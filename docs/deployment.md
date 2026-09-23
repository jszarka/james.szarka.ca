# RackNerd cPanel deployment

## Decision

Deploy the static site from GitHub Actions to RackNerd shared hosting using
**explicit FTPS**. Plain FTP is not permitted. SFTP remains preferable if RackNerd
later enables jailed SSH, but the deployment does not depend on that support request.

The GitHub repository is public, so standard GitHub-hosted runners do not consume
paid Actions minutes. The workflow retains its small transfer artifact for one day.

## Delivery flow

1. Pull requests assemble and test an explicit publish allowlist.
2. A push to `main` runs the same validation.
3. The production job reads credentials only after entering the GitHub
   `production` environment.
4. `lftp` connects to cPanel with explicit TLS, verifies the server certificate,
   mirrors the publish directory, and removes obsolete site files.
5. The workflow requests `deploy-version.txt` through Cloudflare and verifies that
   the live response contains the deployed Git commit.

The deploy job runs for a manual `workflow_dispatch`. Automatic deployment from
`main` starts only after the repository variable `DEPLOY_ENABLED` is set to
`true`.

## One-time cPanel setup

1. In **cPanel → Domains**, record the exact document root for
   `james.szarka.ca`.
2. In **cPanel → FTP Accounts**, create a dedicated account such as
   `github-deploy`.
3. Set that account's directory to the document root from step 1. This jails the
   account to this website and makes its FTPS root `/`.
4. Generate a long random password used nowhere else. Use at least 40 characters
   from letters, digits, hyphen, underscore, period, and tilde; avoiding quotes,
   backslashes, commas, whitespace, and line breaks keeps the credential safe to
   pass to the non-interactive FTPS client.
5. In cPanel's FTP configuration page, confirm the FTPS hostname and port. cPanel
   normally uses explicit FTPS on port 21.
6. Test the account locally with an FTPS client before adding it to GitHub.

Do not use the primary cPanel login. Do not give the deployment account access to
the home directory, email, databases, or other sites.

## One-time GitHub setup

Create **Settings → Environments → production**. Configure:

Environment secrets:

- `FTPS_USERNAME`
- `FTPS_PASSWORD`

Environment variables:

- `FTPS_HOST`: the certificate-valid FTP hostname supplied by cPanel
- `FTPS_PORT`: normally `21`
- `FTPS_REMOTE_PATH`: `/` when the FTP account is jailed directly to the
  domain document root

Repository variable (under **Settings → Secrets and variables → Actions**):

- `DEPLOY_ENABLED`: leave unset until the manual test succeeds, then set to
  `true`. This must be a repository variable because GitHub evaluates the
  deploy job condition before environment-level variables are loaded.

For the first deployment, add yourself as a required reviewer if GitHub permits a
useful approval arrangement for the account. A sole maintainer cannot use
"prevent self-review" without another reviewer.

## First release

1. Merge the website change only after the production environment and FTPS account
   are ready.
2. Open **Actions → Validate and deploy website → Run workflow**.
3. Approve the production job if an environment reviewer is configured.
4. Confirm the FTPS upload succeeds.
5. Confirm the commit verification succeeds.
6. Check the home page and each portfolio page.
7. Set `DEPLOY_ENABLED=true`. Later pushes to `main` will deploy automatically.

## Cloudflare and cPanel

- Set Cloudflare SSL/TLS mode to **Full (strict)**.
- Turn on **Always Use HTTPS**.
- Ensure Rocket Loader is off; the site's Content Security Policy intentionally
  blocks inline scripts.
- The deployed `.htaccess` carries the security headers formerly held only in
  `nginx.conf`, disables directory listings, redirects direct HTTP requests, and
  denies sensitive file extensions.
- The FTPS mirror excludes `.well-known` and `cgi-bin` so cPanel/AutoSSL content
  is not deleted.

After the first release, audit the live response headers. If LiteSpeed ignores a
directive, adjust `.htaccess` rather than weakening the policy globally.

## Limitations and rollback

FTPS cannot provide the atomic release-directory and symlink swap available over
SSH. A visitor could briefly observe a mixture of old and new files during the
small upload window.

Before the first deployment:

- Confirm that RackNerd JetBackup is enabled and current.
- Download one manual cPanel backup of the existing document root.
- Keep the prior Git commit available.

For a code rollback, revert the bad commit on `main`; the resulting push
redeploys the prior content. For a transfer interrupted after deletions, rerun the
workflow. For loss outside Git-managed files, restore the document root using
JetBackup or the manual archive.

## Troubleshooting

### TLS certificate error

Use the FTP hostname shown by cPanel, not necessarily `james.szarka.ca`. Do not
disable certificate verification.

### Authentication succeeds but upload fails

Check that the FTP account directory is exactly the domain document root and that
`FTPS_REMOTE_PATH` is `/`. An incorrect absolute server path is usually hidden
from jailed FTP accounts.

### Connection timeout

Confirm passive FTPS is enabled and use port 21. RackNerd may publish a passive
port range, but GitHub-hosted runners only initiate outbound connections, so no
runner firewall rule is normally needed.

### Website changed but verification failed

Check Cloudflare caching and request
`/deploy-version.txt?commit=<commit-sha>`. The workflow already sends a cache
buster and a no-cache request header.

### SSH investigation

SFTP uses the SSH service and the primary cPanel system account, not a normal
cPanel FTP subaccount. If RackNerd eventually enables jailed SSH, verify the
assigned SSH port, shell access state, username, and public-key installation in
cPanel before changing the transport.
