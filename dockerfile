# Pinned, not :latest. An unpinned base means two builds of the same commit can
# ship different software, which makes "it worked yesterday" unfalsifiable.
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y --no-install-recommends nginx && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

RUN rm -f /etc/nginx/sites-enabled/default

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

RUN ln -sf /dev/stdout /var/log/nginx/access.log \
 && ln -sf /dev/stderr /var/log/nginx/error.log

EXPOSE 80

# start.sh is gone. It was the Lightsail-era entrypoint: it started nginx as a
# daemon, then blocked forever in a sleep loop waiting for certificate files at
# /etc/ssl/{certs,private} that are never mounted here. The 443 block it wanted
# to append therefore never applied, and PID 1 was a sleep loop rather than
# nginx, so the container had no signal handling or graceful shutdown.
# TLS terminates at Cloudflare; this container serves HTTP only.
CMD ["nginx", "-g", "daemon off;"]
