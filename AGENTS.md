# Repository Guidelines

## Project Structure & Module Organization
This is a static portfolio site served by Nginx in Docker. Key paths:
- `index.html`: main entry point for the site content.
- `css/`, `js/`: stylesheets and scripts.
- `img/`, `fonts/`: assets and typography.
- `contact_form/`: contact form assets.
- `dockerfile`, `nginx.conf`, `start.sh`: container and web server setup.

## Build, Test, and Development Commands
Local static preview:
- `python3 -m http.server 8080`: serve the site and open `http://localhost:8080`.

Docker image build and run:
- `docker build -f dockerfile -t james-szarka-site .`: build the Nginx image.
- `docker run --rm -p 8080:80 james-szarka-site`: run HTTP on port 8080.
Note: `start.sh` waits for TLS certs at `/etc/ssl/certs/certificate.pem` and `/etc/ssl/private/private.pem`; mount them if you want HTTPS enabled in the container.

## Coding Style & Naming Conventions
- Indentation: 2 spaces in HTML/CSS/JS to match existing files.
- Naming: keep files lowercase with hyphens (e.g., `portfolio-1.html`), and prefer semantic class names over abbreviations.
- Keep third-party vendor files in their current locations; avoid reformatting vendor CSS/JS.

## Testing Guidelines
No automated tests are configured. If you add tests, document the framework and provide a single command to run the full suite (e.g., `npm test`).

## Commit & Pull Request Guidelines
No established commit message convention is present in the history. Use clear, imperative messages (e.g., `Update hero copy`), and keep commits focused. For PRs, include:
- A short summary of changes and intent.
- Linked issues or tickets if applicable.
- Screenshots for visual updates.

## Configuration & Security
Do not commit secrets. If environment variables are required, add an `.env.example` and list required keys in `README.md`.
