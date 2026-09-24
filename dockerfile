# Local and preview server, mirroring production.
#
# Production is shared cPanel: Apache (or LiteSpeed, which reads the same
# .htaccess) serving static files out of public_html. There is no container in
# production and there cannot be one — shared hosting does not run Docker.
#
# So this image exists for exactly one reason: to run the SAME web server and
# the SAME .htaccess locally, so that a config change can be tested before it is
# uploaded. It previously ran nginx, which meant the thing being tested locally
# was a config production never sees, while the config production actually uses
# was never executed until it was live.
#
# Pinned to an explicit Apache and Debian release. For a stricter guarantee,
# pin by digest instead and bump it deliberately:
#   FROM httpd:2.4-bookworm@sha256:<digest>
FROM httpd:2.4-bookworm

# The official image ships most modules commented out. .htaccess needs these
# four, and mod_filter for AddOutputFilterByType. cPanel has them enabled; if a
# module is missing there, the <IfModule> guards in .htaccess skip the block
# rather than returning 500.
RUN sed -i \
      -e 's|^#\(LoadModule rewrite_module\)|\1|' \
      -e 's|^#\(LoadModule headers_module\)|\1|' \
      -e 's|^#\(LoadModule expires_module\)|\1|' \
      -e 's|^#\(LoadModule deflate_module\)|\1|' \
      -e 's|^#\(LoadModule filter_module\)|\1|' \
      /usr/local/apache2/conf/httpd.conf \
 && sed -i 's|AllowOverride None|AllowOverride All|g' \
      /usr/local/apache2/conf/httpd.conf \
 && printf '\nServerName localhost\nServerTokens Prod\nServerSignature Off\n' \
      >> /usr/local/apache2/conf/httpd.conf

# AllowOverride All is what makes .htaccess take effect, matching cPanel.
# Without it the file is present and silently ignored, which is the worst of
# both worlds: it looks tested and is not.

# Copy an explicit allowlist of published assets.
#
# This used to be `COPY . /usr/share/nginx/html`, which put the whole repository
# into the webroot: .git/ (from which the full history can be reconstructed),
# the dockerfile, the server config and the internal docs. The globs below mean
# new pages and assets are picked up without editing this file.
#
# Mirror any change here in the cPanel deploy, so the two webroots hold the same
# set of files.
WORKDIR /usr/local/apache2/htdocs
RUN rm -rf ./*

COPY .htaccess ./
COPY index.html favicon.ico robots.txt sitemap.xml llms.txt ./
COPY portfolio-*.html ./
COPY Resume-JamesSzarka.pdf ./
COPY css/ css/
COPY img/ img/

EXPOSE 80

CMD ["httpd-foreground"]
