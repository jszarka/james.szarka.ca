FROM ubuntu:latest

ENV DEBIAN_FRONTEND=noninteractive

# Install Nginx
RUN apt-get update && \
    apt-get install -y nginx && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Remove default Nginx config
RUN rm /etc/nginx/sites-enabled/default

# Copy initial HTTP-only config and site files
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY . /usr/share/nginx/html

# Copy startup script
COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 80 443

CMD ["/start.sh"]
