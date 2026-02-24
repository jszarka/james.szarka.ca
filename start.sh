#!/bin/bash

# Enforce TLS 1.2 minimum
sysctl -w net.ipv4.tcp_enabled=1
sysctl -w net.ipv4.tcp_max_syn_backlog=2048

# Restart Nginx after SSL/TLS certificate mounting
sudo systemctl stop nginx
sudo systemctl start nginx

# Log the restart
echo "$(date) - Nginx restarted with TLS 1.2 minimum enforcement." >> /var/log/nginx/restart.log