# STEP 1: Use the latest Ubuntu LTS version (24.04) for better security and features.
FROM ubuntu:24.04

# Set a non-interactive mode for apt to avoid prompts during installation
ENV DEBIAN_FRONTEND=interactive

# STEP 2: Install Nginx.
# Update the package lists, install Nginx, and clean up apt cache to keep the image size small.
# Installing Nginx is essential for serving your static HTML/CSS/JS files efficiently.
RUN apt-get update && \
    apt-get install -y nginx && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# STEP 3: Remove the default Nginx welcome page files.
RUN rm -rf /var/www/html/*
RUN rm /etc/nginx/sites-enabled/default
# STEP 4: Copy your static website files into the Nginx default web root.
# This is where your index.html, css/, and js/ folders will reside inside the container.
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY . /usr/share/nginx/html

# STEP 5: Expose port 80, the standard HTTP port Nginx listens on.
EXPOSE 80

# STEP 6: Command to run Nginx when the container starts.
# Running Nginx in the foreground ('daemon off;') ensures the container stays alive.
CMD ["nginx", "-g", "daemon off;"]
