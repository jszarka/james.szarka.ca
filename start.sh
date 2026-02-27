#!/bin/bash
set -e

# Start Nginx with HTTP only so health checks pass
nginx

# Wait for TLS certificate files to be mounted.
while [ ! -f /etc/ssl/certs/certificate.pem ] || [ ! -f /etc/ssl/private/private.pem ]; do
    sleep 5
done

# Append HTTPS block only if not already present
if ! grep -q "listen 443 ssl" /etc/nginx/conf.d/default.conf 2>/dev/null; then
cat >> /etc/nginx/conf.d/default.conf <<'EOL'

server {
    listen 443 ssl http2;
    server_name james.szarka.ca;

    root /usr/share/nginx/html;
    index index.html;

    ssl_certificate /etc/ssl/certs/certificate.pem;
    ssl_certificate_key /etc/ssl/private/private.pem;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ciphers 'ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384';

    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Content-Type-Options nosniff;
    add_header X-Frame-Options DENY;
    add_header X-XSS-Protection "1; mode=block";

    location / {
        try_files \$uri \$uri/ =404;
    }
}
EOL

  # Reload Nginx with SSL enabled
  nginx -s reload
fi

# Keep Nginx in foreground
nginx -g "daemon off;"