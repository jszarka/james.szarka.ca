# Official nginx image on Debian bookworm.
#
# Replaces `FROM ubuntu:latest` + `apt-get install nginx`. That pulled a general
# purpose distribution and a package-manager-built nginx to serve five static
# files; this is the same Debian base with nginx built and patched by the people
# who write nginx, and without apt, systemd remnants and the rest of a full
# userland sitting in the image unexecuted.
#
# Pinned to the stable branch on an explicit Debian release. For a stricter
# guarantee, pin by digest instead:
#   FROM nginx:1.30-bookworm@sha256:<digest>
# and bump it deliberately. A tag can be repointed; a digest cannot.
FROM nginx:1.30-bookworm

# The official image ships its own default.conf; ours replaces it.
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy an explicit allowlist of published assets.
#
# This used to be `COPY . /usr/share/nginx/html`, which put the whole repository
# into the webroot: .git/ (from which the full history can be reconstructed),
# the dockerfile, nginx.conf, start.sh, and the internal docs. Nginx serves
# dotfiles by default, so nothing stopped /.git/config being fetched. The globs
# below mean new pages and assets are picked up without editing this file.
WORKDIR /usr/share/nginx/html
RUN rm -rf ./*

COPY index.html favicon.ico robots.txt sitemap.xml llms.txt ./
COPY portfolio-*.html ./
COPY Resume-JamesSzarka.pdf ./
COPY css/ css/
COPY img/ img/

EXPOSE 80

# start.sh is gone. It was the Lightsail-era entrypoint: it started nginx as a
# daemon, then blocked forever in a sleep loop waiting for certificate files at
# /etc/ssl/{certs,private} that are never mounted here. The 443 block it wanted
# to append therefore never applied, and PID 1 was a sleep loop rather than
# nginx, so the container had no signal handling or graceful shutdown.
# TLS terminates at Cloudflare; this container serves HTTP only.
#
# The base image already logs to stdout/stderr and runs nginx in the foreground;
# CMD is stated explicitly so a base image change cannot silently alter it.
CMD ["nginx", "-g", "daemon off;"]
