#!/usr/bin/env bash
set -Eeuo pipefail

: "${CPANEL_HOST:?Set CPANEL_HOST}"
: "${CPANEL_USERNAME:?Set CPANEL_USERNAME}"
: "${CPANEL_REMOTE_DIR:?Set CPANEL_REMOTE_DIR}"
: "${CPANEL_API_TOKEN:?Set CPANEL_API_TOKEN}"

PUBLISH_DIR="${PUBLISH_DIR:-_site}"
EXPECTED_REMOTE_DIR="james.szarka.ca"

if [[ ! -d "$PUBLISH_DIR" ]]; then
  echo "Publish directory does not exist: $PUBLISH_DIR" >&2
  exit 1
fi

if [[ ! "$CPANEL_HOST" =~ ^[A-Za-z0-9.-]+$ ]]; then
  echo "CPANEL_HOST must be a hostname without a scheme, port, or path." >&2
  exit 1
fi

if [[ ! "$CPANEL_USERNAME" =~ ^[A-Za-z0-9._-]+$ ]]; then
  echo "CPANEL_USERNAME contains unsupported characters." >&2
  exit 1
fi

# This is intentionally site-specific. An incorrect document root combined with
# a full-access cPanel token has a much larger blast radius than a jailed FTP
# account, so refuse any destination other than the confirmed domain root.
if [[ "$CPANEL_REMOTE_DIR" != "$EXPECTED_REMOTE_DIR" ]]; then
  echo "Refusing deployment to '$CPANEL_REMOTE_DIR'; expected '$EXPECTED_REMOTE_DIR'." >&2
  exit 1
fi

if [[ ! -s "$PUBLISH_DIR/index.html" || ! -s "$PUBLISH_DIR/deploy-version.txt" ]]; then
  echo "The validated site or deployment marker is missing." >&2
  exit 1
fi

umask 077
auth_file="$(mktemp)"
response_file="$(mktemp)"
cleanup() {
  rm -f -- "$auth_file" "$response_file"
}
trap cleanup EXIT

printf 'Authorization: cpanel %s:%s\n' "$CPANEL_USERNAME" "$CPANEL_API_TOKEN" > "$auth_file"
unset CPANEL_API_TOKEN

cpanel_base="https://${CPANEL_HOST}:2083"
account_home="/home/${CPANEL_USERNAME}"

curl_common=(
  --fail-with-body
  --silent
  --show-error
  --retry 3
  --retry-all-errors
  --connect-timeout 20
  --max-time 120
  --header "@$auth_file"
)

uapi_list_directory() {
  local directory="$1"

  curl "${curl_common[@]}" \
    --get \
    --data-urlencode "dir=$directory" \
    "$cpanel_base/execute/Fileman/list_files" > "$response_file"

  jq -e '.status == 1 and .errors == null and (.data | type == "array")' \
    "$response_file" > /dev/null
}

ensure_directory() {
  local relative_directory="$1"
  local parent name parent_remote parent_absolute

  parent="$(dirname -- "$relative_directory")"
  name="$(basename -- "$relative_directory")"

  if [[ "$parent" == "." ]]; then
    parent_remote="$CPANEL_REMOTE_DIR"
  else
    parent_remote="$CPANEL_REMOTE_DIR/$parent"
  fi

  uapi_list_directory "$parent_remote"

  if jq -e --arg name "$name" \
    'any(.data[]; .file == $name and .type == "dir")' \
    "$response_file" > /dev/null; then
    return
  fi

  parent_absolute="$account_home/$parent_remote"
  echo "Creating remote directory: $parent_remote"

  # cPanel has no UAPI equivalent for mkdir. API 2 Fileman::mkdir remains the
  # documented interface for this one operation; uploads use current UAPI.
  curl "${curl_common[@]}" \
    --get \
    --data-urlencode "cpanel_jsonapi_user=$CPANEL_USERNAME" \
    --data-urlencode "cpanel_jsonapi_apiversion=2" \
    --data-urlencode "cpanel_jsonapi_module=Fileman" \
    --data-urlencode "cpanel_jsonapi_func=mkdir" \
    --data-urlencode "path=$parent_absolute" \
    --data-urlencode "name=$name" \
    --data-urlencode "permissions=0755" \
    "$cpanel_base/json-api/cpanel" > "$response_file"

  jq -e \
    '.cpanelresult.event.result == 1 and
     all(.cpanelresult.data[]?; (.result // 1) == 1)' \
    "$response_file" > /dev/null
}

upload_file() {
  local relative_file="$1"
  local local_file remote_parent filename

  local_file="$PUBLISH_DIR/$relative_file"
  remote_parent="$(dirname -- "$relative_file")"
  filename="$(basename -- "$relative_file")"

  if [[ "$remote_parent" == "." ]]; then
    remote_parent="$CPANEL_REMOTE_DIR"
  else
    remote_parent="$CPANEL_REMOTE_DIR/$remote_parent"
  fi

  echo "Uploading: $relative_file"
  curl "${curl_common[@]}" \
    --form "dir=$remote_parent" \
    --form "overwrite=1" \
    --form "file=@${local_file};filename=${filename}" \
    "$cpanel_base/execute/Fileman/upload_files" > "$response_file"

  jq -e \
    '.status == 1 and
     .errors == null and
     .data.failed == 0 and
     .data.succeeded == 1 and
     (.data.uploads | length) == 1 and
     .data.uploads[0].status == 1' \
    "$response_file" > /dev/null
}

# Reject path shapes that should never appear in the generated allowlist.
while IFS= read -r -d '' path; do
  relative="${path#"$PUBLISH_DIR/"}"
  case "$relative" in
    ""|/*|../*|*/../*|*/..)
      echo "Unsafe publish path: $relative" >&2
      exit 1
      ;;
  esac
done < <(find "$PUBLISH_DIR" -mindepth 1 -print0)

# Parents are sorted before children, so nested directories can be created
# incrementally.
while IFS= read -r directory; do
  ensure_directory "$directory"
done < <(
  find "$PUBLISH_DIR" -mindepth 1 -type d -printf '%P\n' |
    LC_ALL=C sort
)

# Upload assets and secondary pages first. The entry point changes only after
# its dependencies are present, and the version marker changes only after every
# site file succeeded.
while IFS= read -r file; do
  case "$file" in
    index.html|deploy-version.txt) continue ;;
  esac
  upload_file "$file"
done < <(
  find "$PUBLISH_DIR" -type f -printf '%P\n' |
    LC_ALL=C sort
)

upload_file "index.html"
upload_file "deploy-version.txt"

echo "cPanel upload completed successfully."
