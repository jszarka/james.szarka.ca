# RackNerd cPanel deployment

## Decision

Deploy the static site from GitHub Actions through cPanel's HTTPS API on port
2083. The API connection uses TLS certificate verification and a cPanel API
token; FTP, FTPS, and SSH are not required.

The repository is public, so standard GitHub-hosted runners do not consume paid
Actions minutes. The small transfer artifact is retained for one day.

Confirmed production values:

- cPanel host: `fiber18-r.iaasdns.com`
- cPanel account: `cloudpla`
- document root: `/home/cloudpla/james.szarka.ca`
- API directory: `james.szarka.ca`

## Delivery flow

1. Pull requests assemble and test an explicit publish allowlist.
2. A push to `main` runs the same validation.
3. The production job reads its token only after entering the GitHub
   `production` environment.
4. `scripts/deploy-cpanel.sh` creates missing asset directories and uploads
   files with UAPI `Fileman::upload_files`.
5. Assets and secondary pages upload first, `index.html` near the end, and
   `deploy-version.txt` last.
6. The workflow requests the marker through the public site and verifies that it
   contains the deployed Git commit.

The deploy job runs for a manual `workflow_dispatch`. Automatic deployment from
`main` begins only after repository variable `DEPLOY_ENABLED` is `true`.

## Security properties

- The API token is stored only as a GitHub environment secret.
- Authentication is passed through a mode-0600 temporary header file, not a
  command-line argument.
- The script validates every API response because cPanel can report an
  application error in an HTTP 200 response.
- TLS verification stays enabled. Do not add `curl -k`.
- The client refuses any remote root except `james.szarka.ca`.
- The first release performs no remote mirror or broad delete. Existing
  `.well-known`, `cgi-bin`, and other cPanel-managed files are preserved.
- Pull-request jobs never enter the production environment and cannot read its
  token.

A cPanel API token is effectively full account access. It is more reliable than
the broken FTP service, but it is not as narrowly jailed as a dedicated FTP
account. Use a dedicated token named `github-actions-james-site`, give it an
expiration date if the interface offers one, and rotate it periodically.

Official references:

- [cPanel API-token authentication](https://api.docs.cpanel.net/cpanel/tokens)
- [UAPI file-upload tutorial](https://api.docs.cpanel.net/guides/quickstart-development-guide/tutorial-use-uapis-fileman-upload-files-function-in-custom-code)
- [API 2 Fileman::mkdir](https://api.docs.cpanel.net/cpanel-api-2/cpanel-api-2-modules-fileman/cpanel-api-2-functions-fileman-mkdir)

The deployment uses deprecated API 2 only for directory creation because cPanel
documents that no UAPI equivalent exists. All file uploads use UAPI.

## One-time GitHub setup

In the repository, open **Settings → Environments** and create `production`.

Add this environment secret:

- `CPANEL_API_TOKEN`: the token value created in cPanel

Add these environment variables:

- `CPANEL_HOST`: `fiber18-r.iaasdns.com`
- `CPANEL_USERNAME`: `cloudpla`
- `CPANEL_REMOTE_DIR`: `james.szarka.ca`

Under **Settings → Secrets and variables → Actions → Variables**, create the
repository variable:

- `DEPLOY_ENABLED`: leave it unset or set it to `false` for the first manual
  release; set it to `true` only after that release succeeds

`DEPLOY_ENABLED` is a repository variable because GitHub evaluates the job
condition before it loads environment-level variables.

If practical, configure a required reviewer on the production environment. A
sole maintainer should not enable “prevent self-review” unless another reviewer
is available.

## First release

1. In cPanel, download a backup of `/home/cloudpla/james.szarka.ca` or confirm a
   current JetBackup restore point.
2. Merge the pull request after the production environment is configured.
3. Open **Actions → Validate and deploy website → Run workflow** and select
   `main`.
4. Approve the production job if a reviewer is configured.
5. Confirm the API upload and live commit-verification steps succeed.
6. Check the home page and every portfolio page.
7. Set repository variable `DEPLOY_ENABLED=true` to enable later automatic
   deployments from `main`.

The initial deployment intentionally leaves old files such as legacy JavaScript,
fonts, and retired pages in place. After the new site is verified, remove only
the known legacy paths with cPanel File Manager. Do not delete `.well-known` or
`cgi-bin`.

## Cloudflare and cPanel

- Set Cloudflare SSL/TLS mode to **Full (strict)**.
- Turn on **Always Use HTTPS**.
- Keep Rocket Loader off; the site's Content Security Policy intentionally
  blocks inline scripts.
- The deployed `.htaccess` supplies security headers, disables directory
  listings, redirects direct HTTP requests, and denies sensitive extensions.

After the first release, audit the live response headers. If LiteSpeed ignores a
directive, adjust `.htaccess` rather than weakening the policy globally.

## Rollback

This transport cannot provide an atomic release-directory and symlink swap. A
visitor could briefly observe a mixture of old and new files during the small
upload window.

For a code rollback, revert the bad commit on `main`; the resulting push
redeploys the prior tracked content. For a transfer interruption, rerun the
workflow. For loss outside Git-managed files, restore the document root with
JetBackup or the manual backup.

## Troubleshooting

### API authentication fails

Confirm the production environment secret contains only the token value, without
the `Authorization:` prefix, username, quotes, or a trailing copied prompt.
Confirm `CPANEL_USERNAME=cloudpla`.

### TLS certificate error

Use `fiber18-r.iaasdns.com`, whose certificate covers the cPanel service. Do
not use the domain name unless its certificate is valid on port 2083, and do not
disable certificate verification.

### Directory creation fails

The host may have disabled the deprecated API 2 `Fileman::mkdir` endpoint. For
the current site, create `img/portfolio` manually in cPanel File Manager and
rerun the workflow. Existing directories are detected and do not invoke API 2.

### Upload succeeds but verification fails

Request
`https://james.szarka.ca/deploy-version.txt?commit=<commit-sha>` and inspect
Cloudflare caching. The workflow uses both a unique query string and a no-cache
request header.
