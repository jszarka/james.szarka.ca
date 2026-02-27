# James T. Szarka - Personal Portfolio Website

This repository contains the source code for my professional portfolio website, showcasing my experience as a DevOps and IT Infrastructure expert.

## Overview

A responsive single-page portfolio website built with HTML5, CSS3, and JavaScript, featuring:
- Professional summary
- Work experience timeline
- Skills and expertise
- Portfolio of projects
- Contact information

## Local Development

### Prerequisites
- Web browser
- Text editor (VS Code recommended)
- Basic HTTP server (optional)

### Running Locally
1. Clone the repository:
```bash
git clone https://github.com/yourusername/james.szarka.ca.git
cd james.szarka.ca
```

2. Open `index.html` in your browser or serve using a local HTTP server:
```bash
# Using Python 3
python3 -m http.server 8080
```

3. Visit `http://localhost:8080` in your browser

## Project Structure
```
james.szarka.ca/
├── css/               # Stylesheets
├── js/               # JavaScript files
├── img/              # Image assets
├── start.sh           # container startup script (adds SSL block)
├── nginx.conf         # base HTTP server configuration
└── index.html        # Main entry point
```

## HTTPS / TLS

The image is capable of serving HTTPS directly if you mount your own
certificate/key pair at `/etc/ssl/certs/certificate.pem` and
`/etc/ssl/private/private.pem`.  In that case the `start.sh` script
appends a `server` block to `nginx.conf` and enforces **TLS 1.2 and
higher** via `ssl_protocols TLSv1.2 TLSv1.3;`.

When the container is deployed to an AWS Lightsail *container service*
HTTPS termination happens upstream on the managed load balancer, and the
container only ever sees plain HTTP.  Lightsail currently does not expose
any setting to restrict the TLS policy of the front‑end balancer –
if you need to force TLS 1.2+ you must either:

1. Put another proxy (CloudFront, ALB, etc.) in front of the service and
   configure its security policy, or
2. Run the container somewhere where you control the TLS termination
   (EC2/VM, Kubernetes, Docker on a host, etc.) and mount your own
   certs.

The bundled `ssl_protocols` settings in `start.sh`/`nginx.conf` ensure a
secure fallback when nginx does handle TLS.

## Technologies Used
- HTML5
- CSS3
- JavaScript
- jQuery
- Modern CSS Grid/Flexbox
- Responsive Design

## License
Copyright © 2023 James T. Szarka. All rights reserved.

## Contact
For questions or collaboration opportunities:
- Email: james@szarka.ca
- Location: Calgary, Canada
