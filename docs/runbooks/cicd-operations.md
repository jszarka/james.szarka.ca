# James.szarka.ca CI/CD operations runbook

## Purpose

This runbook explains how to change, review, merge, deploy, verify, and roll back
the production website at [james.szarka.ca](https://james.szarka.ca).

Use this page for routine website releases and deployment incidents. The
repository's `docs/deployment.md` contains the lower-level cPanel integration
details.

## Publish and maintain this page in Docmost

Recommended location:

```text
Operations
└── Web Services
    └── james.szarka.ca
        └── CI/CD Operations Runbook
```

After this documentation pull request is merged:

1. Download `docs/runbooks/cicd-operations.md` from the `main` branch.
2. In the target Docmost space, open the **...** menu next to **Pages**.
3. Select **Import pages → Markdown**.
4. Upload the Markdown file.
5. Rename or move the imported page into the hierarchy above.
6. Give website operators **Can Edit** access and other stakeholders **Can View**
   access as appropriate.
7. Add the GitHub source-file link at the top of the Docmost page.

Docmost also converts Markdown pasted directly into its editor, but importing the
file is preferable for the first publication because it preserves the complete
document consistently.

The repository Markdown file is the controlled source of truth. Any CI/CD change
must update this file in the same pull request. After that pull request is merged,
the operator must update the Docmost page from the new Markdown and use Docmost
page history to retain the prior version.

At the top of the Docmost page, maintain this ownership block:

```text
Service owner: James Szarka
Technical source: docs/runbooks/cicd-operations.md
Last reviewed: YYYY-MM-DD
Review interval: after every pipeline change, and at least every 90 days
```

Docmost references:

- https://docmost.com/docs/user-guide/import-export
- https://docmost.com/docs/user-guide/pages
- https://docmost.com/docs/user-guide/spaces

## Production reference

| Item | Value |
| --- | --- |
| GitHub repository | `jszarka/james.szarka.ca` |
| Default and production branch | `main` |
| AI-assisted delivery system | **PREFAB** |
| PREFAB site/project alias | `cv` |
| Pull request workflow | `Validate and deploy website` |
| Workflow file | `.github/workflows/deploy.yml` |
| Production URL | `https://james.szarka.ca` |
| GitHub environment | `production` |
| cPanel host | `fiber18-r.iaasdns.com` |
| cPanel port | `2083` over HTTPS |
| cPanel username | `cloudpla` |
| cPanel document root | `/home/cloudpla/james.szarka.ca` |
| cPanel API directory | `james.szarka.ca` |
| Automatic deployment switch | Repository variable `DEPLOY_ENABLED=true` |

## How delivery works

1. Work is performed on a branch, never directly on `main`.
2. A pull request runs the validation job without receiving production secrets.
3. The validation job builds an explicit publish directory, checks its allowlist,
   tests the deployment script's syntax, and smoke-tests the real `.htaccess`
   through Apache.
4. A maintainer merges the pull request into `main`.
5. Because `DEPLOY_ENABLED=true`, the push to `main` automatically enters the
   GitHub `production` environment and deploys through the cPanel HTTPS API.
6. Assets and secondary pages upload first. `index.html` uploads near the end
   and `deploy-version.txt` uploads last.
7. The workflow reads the public deployment marker and succeeds only when it
   contains the Git commit that was just deployed.

The deployer overwrites the files in the publish allowlist. It does not mirror or
broadly delete the document root, so cPanel-managed paths such as
`.well-known` and `cgi-bin` are preserved.

### Where PREFAB fits

**PREFAB** is the AI-assisted delivery layer included in this CI/CD process. It
can audit the live and preview sites, synchronize the repository, create or
resume a work branch, modify and test the website, commit and push changes, and
open or update the pull request.

PREFAB does not bypass review and does not deploy directly to cPanel. Its output
is a GitHub branch and pull request. A human reviews and merges that pull request;
GitHub Actions then performs the production deployment through the cPanel API.

```text
Operator request
    → PREFAB creates branch, implements, validates, and opens PR
    → Human reviews and merges PR
    → GitHub Actions validates main
    → cPanel API uploads the allowlisted site
    → Public commit marker verifies production
```

This separation keeps the AI authoring identity away from the production token.
PREFAB work branches normally use the `mcp/<topic>` naming convention and must
never directly modify `main`.

## Access and configuration

### Required GitHub access

An operator needs write access to the repository to create branches, open pull
requests, merge approved changes, or manually run the workflow.

### GitHub production environment

Under **Repository → Settings → Environments → production**, configure:

Environment secret:

- `CPANEL_API_TOKEN`: only the cPanel API token value

Environment variables:

- `CPANEL_HOST=fiber18-r.iaasdns.com`
- `CPANEL_USERNAME=cloudpla`
- `CPANEL_REMOTE_DIR=james.szarka.ca`

Under **Settings → Secrets and variables → Actions → Variables**, configure:

- `DEPLOY_ENABLED=true`

Never place the token in source code, an issue, a pull request, a workflow log,
Docmost, chat, or a command saved in shell history.

### cPanel token

Create the token in cPanel's API token interface. Use a dedicated name such as
`github-actions-james-site`. Set an expiry if cPanel offers one, and record the
rotation date in the operations calendar.

The token has broad access to the cPanel account. GitHub environment protections,
branch review, and careful handling of the secret are the primary safeguards.

## PREFAB AI-assisted release procedure

Use this path when PREFAB will implement or help implement the website change.

### 1. Request the change

Select the PREFAB site/project alias `cv` and give it a concrete outcome,
acceptance criteria, and any files or pages that must remain unchanged.

Example request:

```text
Use PREFAB on the cv site to update the platform-foundation case study.
Preserve the existing visual design, validate the preview, and open a pull
request. Do not merge or deploy it.
```

For a visual change, include the intended desktop/mobile behavior and request
screenshots or preview validation. Never include a cPanel token or other secret
in the prompt.

### 2. PREFAB creates the change

PREFAB should follow its guarded repository workflow:

1. audit the live site when a baseline is relevant;
2. synchronize the `cv` repository;
3. create or resume an `mcp/<topic>` work branch from `main`;
4. read and modify only the required files;
5. build or validate the configured preview;
6. review the branch diff;
7. commit and push the branch;
8. open a pull request, or update the existing pull request for that branch.

PREFAB must return the pull-request link and report its validation results. It
must not merge the pull request.

### 3. Request revisions if needed

Review the preview, pull-request description, checks, and **Files changed** tab.
Give PREFAB precise follow-up instructions in the same task, for example:

```text
Update the existing PREFAB pull request: correct the mobile heading spacing,
rerun validation, and summarize the new commit.
```

PREFAB should push revisions to the same branch so the same pull request updates
and CI runs again.

### 4. Human approval, merge, and deployment

Continue at **Review CI and the pull request** below. A human remains responsible
for approving the diff, merging into `main`, watching GitHub Actions, and
verifying production.

## Manual Git release procedure

Use this path when an operator is editing the repository directly.

### 1. Synchronize the repository

Using Git:

```bash
git clone https://github.com/jszarka/james.szarka.ca.git
cd james.szarka.ca
git switch main
git pull --ff-only
```

If the repository is already cloned, start with `git status`. Preserve or
finish any existing work before switching branches.

### 2. Create a branch

Choose a short name describing the outcome:

```bash
git switch -c update-portfolio-copy
```

Suggested branch prefixes:

- `content/` for text and portfolio changes
- `fix/` for corrections
- `feature/` for new site behavior
- `ops/` for CI/CD and documentation

Example:

```bash
git switch -c content/update-resume
```

### 3. Make and test the change

For a simple local preview:

```bash
python3 -m http.server 8080
```

Open `http://localhost:8080` and check:

- the home page;
- every page changed by the branch;
- desktop and narrow/mobile widths;
- navigation and external links;
- images and downloadable files;
- spelling, headings, and accessibility labels.

The pull request will perform the authoritative Apache/`.htaccess` smoke test.

### 4. Commit and push

Review the exact changes before committing:

```bash
git status
git diff
git add <changed-files>
git commit -m "Update portfolio copy"
git push -u origin HEAD
```

Do not use `git add .` without first reviewing untracked files. Never commit
tokens, passwords, private keys, local environment files, database exports, or
backups.

### 5. Create the pull request

#### GitHub web interface

1. Open the repository on GitHub.
2. Select **Pull requests → New pull request**.
3. Set **base** to `main`.
4. Set **compare** to the new branch.
5. Click **Create pull request**.
6. Write a title that describes the outcome.
7. In the description, include:
   - what changed and why;
   - pages or files affected;
   - how the change was tested;
   - screenshots for visual changes;
   - operational or rollback considerations.
8. Click **Create pull request**.

#### GitHub CLI alternative

```bash
gh pr create \
  --base main \
  --head "$(git branch --show-current)" \
  --title "Update portfolio copy" \
  --body "Summary, validation, and rollback notes."
```

### 6. Review CI and the pull request

Open the pull request's **Checks** section. The `Build publish directory` job
must be green before merging.

Review:

- the **Files changed** tab;
- unexpected deletions or binary changes;
- the publish allowlist;
- generated deployment or workflow changes;
- reviewer comments;
- screenshots and manual test results.

Warnings about a future runner migration are maintenance notices unless a job is
red. Errors, cancelled jobs, and failed checks must be resolved before merging.

If a fix is needed, commit it to the same branch and push again. The pull request
and CI checks update automatically.

### 7. Merge

When review and checks pass:

1. Open the pull request.
2. If it is a draft, click **Ready for review**.
3. Click **Squash and merge**.
4. Confirm the final title and commit message.
5. Click **Confirm squash and merge**.
6. Delete the remote branch after the merge when GitHub offers the option.

Squash merging keeps one production-history commit per pull request. Do not merge
when CI is failing or when the production secret/configuration is known to be
unavailable.

### 8. Observe automatic deployment

The merge creates a push to `main`. With `DEPLOY_ENABLED=true`, deployment
starts automatically.

1. Open **Repository → Actions**.
2. Open **Validate and deploy website**.
3. Open the run triggered by the merge commit.
4. Confirm both jobs succeed:
   - `Build publish directory`
   - `Deploy to RackNerd cPanel`
5. Open the deployment job and confirm:
   - the cPanel upload completed;
   - the live commit verification passed.

Do not treat a successful merge as a successful release until the deployment job
is green.

### 9. Verify production

Open the site in a private/incognito browser window and verify:

- `https://james.szarka.ca/`;
- all pages changed in the release;
- navigation, images, styles, and downloads;
- mobile layout;
- expected security redirects and headers.

Confirm the marker:

```bash
curl --fail --silent --show-error \
  "https://james.szarka.ca/deploy-version.txt?check=$(date +%s)"
```

The returned SHA should match the deployed commit displayed in the GitHub Actions
run.

Record the release in Docmost or the relevant change record:

- date and time;
- pull request link;
- merge/deployed commit;
- workflow-run link;
- operator;
- verification result;
- any follow-up work.

## Manual deployment or redeployment

Use a manual run when:

- retrying an interrupted cPanel upload;
- deploying after restoring the token or environment configuration;
- verifying the pipeline without making another source change.

1. Open
   `https://github.com/jszarka/james.szarka.ca/actions/workflows/deploy.yml`.
2. Click **Run workflow**.
3. Select branch `main`.
4. Click the green **Run workflow** button.
5. Monitor both jobs and verify production.

A manual run deploys `main` even when `DEPLOY_ENABLED=false`. Never select a
feature branch; the workflow contains an additional guard that refuses production
deployment unless the ref is `main`.

## Pausing deployment

### Pause automatic deployments

Set repository variable `DEPLOY_ENABLED=false` under:

**Settings → Secrets and variables → Actions → Variables**

Pull request and main-branch validation continue, but pushes to `main` no
longer run the deployment job.

This does not disable the manual **Run workflow** path.

### Emergency full stop

For an incident where no deployment must be possible:

1. Set `DEPLOY_ENABLED=false`.
2. Disable the workflow from its Actions page, or remove the
   `CPANEL_API_TOKEN` environment secret.
3. Record who paused deployment, why, and when.
4. Restore access only after the incident owner approves it.

## Rollback

### Preferred rollback: revert the pull request

A rollback should create a new commit rather than rewriting `main`.

From the merged pull request, use GitHub's **Revert** button if available. This
opens a revert pull request. Review its checks, merge it, and observe the normal
automatic deployment.

Git alternative:

```bash
git switch main
git pull --ff-only
git switch -c revert/bad-release
git revert <bad-merge-or-squash-commit>
git push -u origin HEAD
```

Open and merge the resulting pull request normally.

### Emergency hosting restore

Use cPanel File Manager or JetBackup only when Git-based rollback cannot recover
the site, such as account-level corruption or loss of untracked cPanel-managed
files.

After a hosting restore:

1. confirm the document root is correct;
2. manually run the workflow from `main`;
3. verify the deployment marker and site;
4. document which files and backup point were restored.

## Token rotation

1. Set `DEPLOY_ENABLED=false`.
2. Create a new dedicated cPanel API token.
3. Test it from a secure terminal with a read-only
   `Fileman/list_files?dir=james.szarka.ca` request.
4. Replace the GitHub `production` environment secret
   `CPANEL_API_TOKEN`.
5. Manually run the workflow on `main`.
6. Verify the production marker and website.
7. Revoke the old cPanel token.
8. Set `DEPLOY_ENABLED=true`.
9. Record the rotation date and operator.

Never delete the old token until the new token has completed a successful
deployment.

## Troubleshooting

| Symptom | Likely cause | Action |
| --- | --- | --- |
| Pull request job fails before deployment | Build, allowlist, shell syntax, or Apache smoke-test error | Open the failed step, correct the branch, push again |
| Deployment job is skipped after a merge | `DEPLOY_ENABLED` is absent, misspelled, or not exactly `true` | Correct the repository Actions variable |
| Manual run has no deployment job | A branch other than `main` was selected | Rerun using `main` |
| “Set CPANEL_API_TOKEN” | Environment secret is missing or empty | Add/replace the secret in the `production` environment |
| API authentication failure | Expired/revoked token, wrong username, or copied header text in secret | Replace the secret with only the token value; confirm username `cloudpla` |
| TLS certificate failure | Wrong cPanel hostname or certificate problem | Use `fiber18-r.iaasdns.com`; never disable verification |
| Directory creation failure | Host disabled deprecated API 2 mkdir | Create the required directory in cPanel File Manager and rerun |
| Upload API reports failure in HTTP 200 | cPanel application-level failure | Read the JSON error in the failed step; the script intentionally validates it |
| Deployment green but old content appears | Browser or Cloudflare cache | Hard refresh and request the page with a unique query string |
| Live commit verification fails | Upload incomplete, wrong document root, or cached marker | Check the cPanel upload step and request `deploy-version.txt` directly |
| Node.js or runner migration annotation | Pinned GitHub Action or runner needs routine maintenance | Open an operations PR; it is not a release failure if both jobs are green |
| Some retired URLs remain public | Safe deployer does not broadly delete remote files | Remove only confirmed legacy paths in cPanel File Manager |

## Known limitations

- cPanel API tokens have broad account access and cannot be jailed to one
  document root like a dedicated FTP account.
- Shared hosting does not provide an atomic release-directory and symlink swap.
  Visitors could briefly see mixed versions during an upload.
- The workflow deliberately does not delete unknown remote files.
- cPanel has no UAPI directory-creation endpoint. The deployer uses the
  documented legacy API 2 mkdir call only when a required directory is missing.
- GitHub environment configuration and cPanel tokens are external state and
  cannot be reconstructed from the repository alone.

## Change and incident record template

```text
Title:
Date/time (UTC):
Operator:
Pull request:
Commit:
GitHub Actions run:
Change summary:
Pre-deployment checks:
Production verification:
Rollback required: yes/no
Rollback action:
Incident or follow-up notes:
```

## Related links

- PREFAB site/project alias: `cv`
- Repository: https://github.com/jszarka/james.szarka.ca
- Workflow: https://github.com/jszarka/james.szarka.ca/actions/workflows/deploy.yml
- Production: https://james.szarka.ca
- Technical deployment design: `docs/deployment.md`
- cPanel token documentation: https://api.docs.cpanel.net/cpanel/tokens
- GitHub manual workflow documentation:
  https://docs.github.com/en/actions/how-tos/manage-workflow-runs/manually-run-a-workflow
