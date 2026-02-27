FROM ubuntu:latest

ENV DEBIAN_FRONTEND=noninteractive

# Install Nginx
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y nginx && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Remove default Nginx config
RUN rm /etc/nginx/sites-enabled/default

# Copy initial HTTP-only config and site files
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY . /usr/share/nginx/html

RUN ln -sf /dev/stdout /var/log/nginx/access.log \
 && ln -sf /dev/stderr /var/log/nginx/error.log

# Copy startup script
COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 80 443

CMD ["/start.sh"]
