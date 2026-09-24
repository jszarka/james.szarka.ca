# James T. Szarka — personal portfolio

Source for [james.szarka.ca](https://james.szarka.ca), a static professional
portfolio and collection of infrastructure and DevOps case studies.

## Stack

- Static HTML and CSS
- Apache/LiteSpeed on RackNerd shared cPanel hosting
- Cloudflare for public DNS, TLS edge termination, and analytics
- Nginx container for local and preview environments
- GitHub Actions for validation and production delivery

## Local development

Serve the files directly:

```bash
python3 -m http.server 8080
```

Then open `http://localhost:8080`.

To exercise the Nginx preview configuration:

```bash
docker build -f dockerfile -t james-szarka-site .
docker run --rm -p 8080:80 james-szarka-site
```

## Repository structure

- `index.html`: home page
- `portfolio-*.html`: case studies
- `css/`, `img/`: published assets
- `.htaccess`: RackNerd Apache/LiteSpeed production configuration
- `nginx.conf`, `dockerfile`: local and preview container
- `.github/workflows/deploy.yml`: validation and cPanel API deployment
- `scripts/deploy-cpanel.sh`: guarded cPanel upload client
- `docs/deployment.md`: cPanel integration design and setup
- `docs/runbooks/cicd-operations.md`: operator release, deployment, and rollback runbook

## Deployment

Pull requests build and smoke-test an explicit publish allowlist. After the
production environment is configured, pushes to `main` deploy the allowlisted
files through cPanel's HTTPS API with a dedicated API token. FTP and SSH are not
required.

The deployment verifies the live commit through Cloudflare before reporting
success. Production credentials belong in the GitHub `production` environment,
never in the repository.

See [docs/deployment.md](docs/deployment.md) for the one-time cPanel setup,
GitHub variables and secrets, first release, troubleshooting, and rollback plan.

## Security

- Do not commit credentials or private keys.
- Do not upload the repository root to the web document root.
- Keep `.htaccess` and `nginx.conf` security headers aligned.
- Use Cloudflare **Full (strict)** TLS and **Always Use HTTPS**.
- Keep Cloudflare Rocket Loader disabled unless the Content Security Policy is
  deliberately revised and tested.

## License

Copyright © 2023–2026 James T. Szarka. All rights reserved.

## Contact

- Email: james@szarka.ca
- Location: Calgary, Canada
