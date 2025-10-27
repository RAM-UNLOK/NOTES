# Complete WordPress Docker Setup for Windows 11
## Production-Ready with All Windows-Compatible Scripts

> **Last Updated:** October 27, 2025  
> **Tested On:** Windows 11, Docker Desktop 4.x  
> **Stack:** Nginx Ubuntu + PHP 8.3 + MariaDB 11.6 + WordPress Latest

***

# Table of Contents

1. [Project Overview](#project-overview)
2. [Complete File Structure](#complete-file-structure)
3. [Prerequisites Installation](#prerequisites-installation)
4. [Configuration Files](#configuration-files)
5. [Windows PowerShell Scripts](#windows-powershell-scripts)
6. [Step-by-Step Installation Guide](#step-by-step-installation-guide)
7. [Usage Guide](#usage-guide)
8. [Backup & Restore](#backup--restore)
9. [Troubleshooting](#troubleshooting)
10. [Performance Optimization](#performance-optimization)

***

# Project Overview

## What You'll Get

✅ **Latest Technology Stack**
- Nginx (Ubuntu-based) - Web server with SSL
- PHP 8.3-FPM (Alpine) - Application server
- MariaDB 11.6 - Database
- WordPress (Latest) - CMS
- phpMyAdmin - Database management

✅ **Security Features**
- SSL/TLS encryption (self-signed for localhost)
- Security headers (HSTS, CSP, X-Frame-Options)
- Rate limiting on login pages
- Secure PHP configuration
- MariaDB hardening

✅ **Performance Optimizations**
- Nginx FastCGI caching
- PHP OPcache enabled
- Gzip compression
- Static file caching
- Optimized MariaDB settings

✅ **Developer Friendly**
- All configs editable
- Windows File Manager access
- PowerShell automation scripts
- Comprehensive logging
- Easy backup/restore

***

# Complete File Structure

```
C:\wordpress-docker\
│
├── docker-compose.yml          # Main orchestration file
├── .env                        # Environment variables (EDIT THIS FIRST!)
├── .gitignore                  # Git ignore rules
├── README.md                   # Project documentation
│
├── nginx\                      # Nginx configuration
│   ├── Dockerfile             # Nginx Ubuntu container
│   ├── nginx.conf             # Main Nginx config
│   └── conf.d\
│       └── default.conf       # WordPress site config
│
├── php\                        # PHP-FPM configuration
│   ├── Dockerfile             # PHP Alpine container
│   ├── php.ini                # PHP runtime settings
│   └── php-fpm.conf           # PHP-FPM pool settings
│
├── mariadb\                    # MariaDB configuration
│   ├── my.cnf                 # MariaDB server config
│   └── init\
│       └── init.sql           # Database initialization
│
├── ssl\                        # SSL certificates (auto-generated)
│   ├── cert.pem               # SSL certificate
│   └── key.pem                # Private key
│
├── scripts\                    # PowerShell automation scripts
│   ├── setup.ps1              # Complete setup automation
│   ├── ssl-setup.ps1          # SSL certificate generator
│   ├── backup.ps1             # Backup script
│   ├── restore.ps1            # Restore script
│   ├── start.ps1              # Start containers
│   ├── stop.ps1               # Stop containers
│   └── logs.ps1               # View logs
│
├── backups\                    # Backup storage
│   └── (backup files here)
│
└── logs\                       # Log files
    ├── nginx\                 # Nginx logs
    ├── php\                   # PHP-FPM logs
    └── mariadb\               # MariaDB logs
```

***

# Prerequisites Installation

## Step 1: Install Docker Desktop

```powershell
# Option 1: Download from website
# Visit: https://www.docker.com/products/docker-desktop

# Option 2: Install via winget (Windows Package Manager)
winget install Docker.DockerDesktop

# After installation:
# 1. Restart computer
# 2. Enable WSL 2 backend (recommended)
# 3. Allocate at least 4GB RAM in Docker Desktop settings
```

## Step 2: Install Git for Windows

```powershell
# Option 1: Download from website
# Visit: https://git-scm.com/download/win

# Option 2: Install via winget
winget install Git.Git

# Git includes OpenSSL needed for SSL certificates
```

## Step 3: Verify Installation

```powershell
# Check Docker
docker --version
# Should show: Docker version 24.x.x

docker-compose --version
# Should show: Docker Compose version v2.x.x

# Check Git (includes OpenSSL)
git --version
# Should show: git version 2.x.x
```

***

# Configuration Files

## 1. Environment Variables (.env)

**Location:** `C:\wordpress-docker\.env`

```env
###############################################################################
# WordPress Docker Environment Configuration for Windows 11
# 
# ⚠️  IMPORTANT: Change all passwords before first run!
# 💾 This file is loaded by docker-compose.yml
# 🔒 Never commit this file to version control
###############################################################################

#==============================================================================
# PROJECT CONFIGURATION
#==============================================================================

# Project name (used as prefix for all containers and volumes)
COMPOSE_PROJECT_NAME=wordpress-docker

#==============================================================================
# WORDPRESS DATABASE CONFIGURATION
#==============================================================================

# Database name
WORDPRESS_DB_NAME=wordpress

# Database username (non-root user)
WORDPRESS_DB_USER=wpuser

# Database password
# ⚠️  CHANGE THIS! Use a strong password
WORDPRESS_DB_PASSWORD=ChangeThisPassword123!

# WordPress database table prefix
WORDPRESS_TABLE_PREFIX=wp_

#==============================================================================
# WORDPRESS ADMIN CONFIGURATION
#==============================================================================

# WordPress admin username
# ⚠️  Don't use 'admin' - change this!
WORDPRESS_ADMIN_USER=myadmin

# WordPress admin password
# ⚠️  CHANGE THIS! Use a strong password
WORDPRESS_ADMIN_PASSWORD=ChangeAdminPassword123!

# WordPress admin email
WORDPRESS_ADMIN_EMAIL=admin@localhost.local

#==============================================================================
# MARIADB ROOT CONFIGURATION
#==============================================================================

# MariaDB root password (for database administration)
# ⚠️  CHANGE THIS! This is the master database password
MYSQL_ROOT_PASSWORD=ChangeRootPassword123!

#==============================================================================
# VERSION CONFIGURATION
#==============================================================================

# MariaDB version (11.6 is latest stable)
MARIADB_VERSION=11.6

# PHP version (8.3 is latest stable)
PHP_VERSION=8.3

#==============================================================================
# DOMAIN AND SSL CONFIGURATION
#==============================================================================

# Local domain name (will be added to Windows hosts file)
DOMAIN_NAME=localhost.local

# SSL Certificate Information (for self-signed certificate)
SSL_COUNTRY=US
SSL_STATE=California
SSL_CITY=San Francisco
SSL_ORG=My Organization
SSL_ORG_UNIT=IT Department

#==============================================================================
# PORT CONFIGURATION
#==============================================================================

# Nginx HTTP port (80 is standard, change if port is in use)
NGINX_HTTP_PORT=80

# Nginx HTTPS port (443 is standard, change if port is in use)
NGINX_HTTPS_PORT=443

# phpMyAdmin web interface port
PHPMYADMIN_PORT=8080

#==============================================================================
# TIMEZONE CONFIGURATION
#==============================================================================

# Server timezone
# Examples: America/New_York, Europe/London, Asia/Tokyo, Asia/Kolkata
# Full list: https://en.wikipedia.org/wiki/List_of_tz_database_time_zones
TIMEZONE=UTC

#==============================================================================
# PHP PERFORMANCE SETTINGS
#==============================================================================

# Maximum memory a PHP script can use
PHP_MEMORY_LIMIT=512M

# Maximum script execution time (seconds)
PHP_MAX_EXECUTION_TIME=300

# Maximum input parsing time (seconds)
PHP_MAX_INPUT_TIME=300

# Maximum file upload size
PHP_UPLOAD_MAX_FILESIZE=256M

# Maximum POST data size
PHP_POST_MAX_SIZE=256M

#==============================================================================
# BACKUP CONFIGURATION
#==============================================================================

# Number of days to keep old backups
BACKUP_RETENTION_DAYS=30
```

## 2. Docker Compose (docker-compose.yml)

**Location:** `C:\wordpress-docker\docker-compose.yml`

```yaml
###############################################################################
# Docker Compose Configuration for WordPress
# Version: 3.8 (Latest stable)
# Platform: Windows 11
# 
# Services:
# 1. MariaDB 11.6 - Database server
# 2. WordPress (PHP 8.3-FPM) - Application server
# 3. Nginx (Ubuntu) - Web server with SSL
# 4. phpMyAdmin - Database management interface
###############################################################################

version: '3.8'

services:

  #============================================================================
  # MariaDB Database Service
  #============================================================================
  mariadb:
    image: mariadb:${MARIADB_VERSION:-11.6}
    container_name: ${COMPOSE_PROJECT_NAME}_mariadb
    restart: unless-stopped
    
    # Environment variables (MARIADB_* required for MariaDB 11.4+)
    environment:
      MARIADB_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
      MARIADB_DATABASE: ${WORDPRESS_DB_NAME}
      MARIADB_USER: ${WORDPRESS_DB_USER}
      MARIADB_PASSWORD: ${WORDPRESS_DB_PASSWORD}
      TZ: ${TIMEZONE}
    
    # Volume mounts
    volumes:
      # Persistent database storage
      - mariadb_data:/var/lib/mysql
      
      # Custom configuration (editable via Windows File Manager)
      - ./mariadb/my.cnf:/etc/mysql/conf.d/custom.cnf:ro
      
      # Initialization scripts
      - ./mariadb/init:/docker-entrypoint-initdb.d:ro
      
      # Log files (accessible via Windows File Manager)
      - ./logs/mariadb:/var/log/mysql
    
    networks:
      - wordpress-network
    
    # Command-line options for performance
    command: >
      --character-set-server=utf8mb4
      --collation-server=utf8mb4_unicode_ci
      --max_allowed_packet=256M
      --innodb_buffer_pool_size=512M
      --innodb_log_file_size=128M
    
    # Health check
    healthcheck:
      test: ["CMD", "healthcheck.sh", "--connect", "--innodb_initialized"]
      interval: 30s
      timeout: 10s
      retries: 5
      start_period: 40s

  #============================================================================
  # WordPress PHP-FPM Service
  #============================================================================
  wordpress:
    build:
      context: ./php
      args:
        PHP_VERSION: ${PHP_VERSION:-8.3}
    container_name: ${COMPOSE_PROJECT_NAME}_wordpress
    restart: unless-stopped
    
    # Wait for MariaDB to be healthy
    depends_on:
      mariadb:
        condition: service_healthy
    
    # WordPress configuration
    environment:
      WORDPRESS_DB_HOST: mariadb:3306
      WORDPRESS_DB_NAME: ${WORDPRESS_DB_NAME}
      WORDPRESS_DB_USER: ${WORDPRESS_DB_USER}
      WORDPRESS_DB_PASSWORD: ${WORDPRESS_DB_PASSWORD}
      WORDPRESS_TABLE_PREFIX: ${WORDPRESS_TABLE_PREFIX}
      WORDPRESS_DEBUG: 0
      TZ: ${TIMEZONE}
    
    volumes:
      # WordPress files (accessible via Docker Desktop volumes browser)
      - wordpress_data:/var/www/html
      
      # Custom PHP configuration (editable via Windows File Manager)
      - ./php/php.ini:/usr/local/etc/php/conf.d/custom.ini:ro
      - ./php/php-fpm.conf:/usr/local/etc/php-fpm.d/zz-custom.conf:ro
      
      # Log files (accessible via Windows File Manager)
      - ./logs/php:/var/log/php
    
    networks:
      - wordpress-network
    
    # Health check
    healthcheck:
      test: ["CMD-SHELL", "php-fpm-healthcheck"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

  #============================================================================
  # Nginx Web Server Service (Ubuntu-based)
  #============================================================================
  nginx:
    build:
      context: ./nginx
    container_name: ${COMPOSE_PROJECT_NAME}_nginx
    restart: unless-stopped
    
    # Start after WordPress is running
    depends_on:
      - wordpress
    
    # Port mappings (expose to Windows host)
    ports:
      - "${NGINX_HTTP_PORT:-80}:80"
      - "${NGINX_HTTPS_PORT:-443}:443"
    
    environment:
      DOMAIN_NAME: ${DOMAIN_NAME}
      TZ: ${TIMEZONE}
    
    volumes:
      # WordPress files (read-only - Nginx only serves files)
      - wordpress_data:/var/www/html:ro
      
      # Nginx configuration (editable via Windows File Manager)
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./nginx/conf.d:/etc/nginx/conf.d:ro
      
      # SSL certificates (generated by ssl-setup.ps1)
      - ./ssl:/etc/nginx/ssl:ro
      
      # Log files (accessible via Windows File Manager)
      - ./logs/nginx:/var/log/nginx
    
    networks:
      - wordpress-network
    
    # Health check
    healthcheck:
      test: ["CMD", "nginx", "-t"]
      interval: 30s
      timeout: 10s
      retries: 3

  #============================================================================
  # phpMyAdmin Database Management Interface
  #============================================================================
  phpmyadmin:
    image: phpmyadmin:latest
    container_name: ${COMPOSE_PROJECT_NAME}_phpmyadmin
    restart: unless-stopped
    
    depends_on:
      - mariadb
    
    ports:
      - "${PHPMYADMIN_PORT:-8080}:80"
    
    environment:
      PMA_HOST: mariadb
      PMA_PORT: 3306
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
      UPLOAD_LIMIT: ${PHP_UPLOAD_MAX_FILESIZE}
      TZ: ${TIMEZONE}
    
    networks:
      - wordpress-network

#==============================================================================
# Network Configuration
#==============================================================================
networks:
  wordpress-network:
    driver: bridge

#==============================================================================
# Volume Configuration
# These persist data even when containers are removed
#==============================================================================
volumes:
  mariadb_data:
    driver: local
  wordpress_data:
    driver: local
```

## 3. Nginx Dockerfile (Ubuntu-based)

**Location:** `C:\wordpress-docker\nginx\Dockerfile`

```dockerfile
###############################################################################
# Nginx Dockerfile (Ubuntu-based)
# Base Image: nginx:ubuntu (latest Ubuntu LTS)
###############################################################################

FROM nginx:ubuntu

# Update packages and install required tools
RUN apt-get update && apt-get install -y \
    openssl \
    curl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create directories
RUN mkdir -p /var/log/nginx /var/cache/nginx

# Copy configuration files
COPY nginx.conf /etc/nginx/nginx.conf
COPY conf.d/ /etc/nginx/conf.d/

# Expose ports
EXPOSE 80 443

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]
```

## 4. Nginx Main Configuration

**Location:** `C:\wordpress-docker\nginx\nginx.conf`

```nginx
###############################################################################
# Nginx Main Configuration
# Optimized for WordPress with security and performance enhancements
###############################################################################

user nginx;
worker_processes auto;
worker_rlimit_nofile 65535;
error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;

events {
    worker_connections 4096;
    use epoll;
    multi_accept on;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    #==========================================================================
    # Logging Configuration
    #==========================================================================
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';

    access_log /var/log/nginx/access.log main;

    #==========================================================================
    # Performance Optimizations
    #==========================================================================
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    client_max_body_size 256M;
    client_body_buffer_size 128k;
    
    # Timeouts
    client_body_timeout 60s;
    client_header_timeout 60s;
    send_timeout 60s;
    
    # Buffer settings
    client_header_buffer_size 1k;
    large_client_header_buffers 4 8k;
    
    #==========================================================================
    # Gzip Compression
    #==========================================================================
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/xml text/javascript 
               application/json application/javascript application/xml+rss 
               application/rss+xml font/truetype font/opentype 
               application/vnd.ms-fontobject image/svg+xml;
    gzip_disable "msie6";
    gzip_min_length 256;

    #==========================================================================
    # Security Headers
    #==========================================================================
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "0" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    
    server_tokens off;
    
    #==========================================================================
    # Rate Limiting (Anti-Brute Force)
    #==========================================================================
    limit_req_zone $binary_remote_addr zone=wp_login:10m rate=2r/s;
    limit_req_zone $binary_remote_addr zone=wp_admin:10m rate=10r/s;
    limit_conn_zone $binary_remote_addr zone=addr:10m;

    #==========================================================================
    # FastCGI Cache Configuration
    #==========================================================================
    fastcgi_cache_path /var/cache/nginx levels=1:2 keys_zone=WORDPRESS:100m 
                       inactive=60m max_size=512m;
    fastcgi_cache_key "$scheme$request_method$host$request_uri";
    fastcgi_cache_use_stale error timeout invalid_header http_500 http_503;
    fastcgi_cache_valid 200 301 302 60m;
    fastcgi_cache_valid 404 10m;
    fastcgi_ignore_headers Cache-Control Expires Set-Cookie;

    #==========================================================================
    # Include Site Configurations
    #==========================================================================
    include /etc/nginx/conf.d/*.conf;
}
```

## 5. Nginx WordPress Site Configuration

**Location:** `C:\wordpress-docker\nginx\conf.d\default.conf`

```nginx
###############################################################################
# WordPress Site Configuration
# Includes SSL, caching, security, and performance optimizations
###############################################################################

upstream php-fpm {
    server wordpress:9000;
    keepalive 32;
}

#==============================================================================
# HTTP Server (Redirects to HTTPS)
#==============================================================================
server {
    listen 80;
    listen [::]:80;
    server_name localhost localhost.local;
    
    # Allow Let's Encrypt ACME challenge
    location ^~ /.well-known/acme-challenge/ {
        allow all;
        root /var/www/html;
    }
    
    # Redirect all HTTP to HTTPS
    location / {
        return 301 https://$host$request_uri;
    }
}

#==============================================================================
# HTTPS Server (Main WordPress Site)
#==============================================================================
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name localhost localhost.local;

    root /var/www/html;
    index index.php index.html index.htm;

    #==========================================================================
    # SSL Configuration
    #==========================================================================
    ssl_certificate /etc/nginx/ssl/cert.pem;
    ssl_certificate_key /etc/nginx/ssl/key.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384';
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    ssl_session_tickets off;

    #==========================================================================
    # Security Headers
    #==========================================================================
    add_header Content-Security-Policy "default-src 'self' https: data: 'unsafe-inline' 'unsafe-eval';" always;
    add_header Permissions-Policy "geolocation=(), microphone=(), camera=()" always;

    #==========================================================================
    # Logging
    #==========================================================================
    access_log /var/log/nginx/wordpress-access.log;
    error_log /var/log/nginx/wordpress-error.log;

    #==========================================================================
    # Connection Limits
    #==========================================================================
    limit_conn addr 10;

    #==========================================================================
    # WordPress Permalink Support
    #==========================================================================
    location / {
        try_files $uri $uri/ /index.php?$args;
    }

    #==========================================================================
    # Security: Block Sensitive Files
    #==========================================================================
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }

    location = /xmlrpc.php {
        deny all;
        access_log off;
        log_not_found off;
    }

    location = /readme.html { deny all; }
    location = /license.txt { deny all; }
    location ~* wp-config.php { deny all; }

    #==========================================================================
    # Rate Limited Locations
    #==========================================================================
    location = /wp-login.php {
        limit_req zone=wp_login burst=5 nodelay;
        include fastcgi_params;
        fastcgi_pass php-fpm;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_index index.php;
    }

    location ^~ /wp-admin/ {
        limit_req zone=wp_admin burst=20 nodelay;
        location ~ \.php$ {
            include fastcgi_params;
            fastcgi_pass php-fpm;
            fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
            fastcgi_index index.php;
        }
    }

    #==========================================================================
    # PHP Processing with FastCGI Cache
    #==========================================================================
    location ~ \.php$ {
        try_files $uri =404;
        
        # Cache control
        set $skip_cache 0;
        
        if ($request_method = POST) { set $skip_cache 1; }
        if ($query_string != "") { set $skip_cache 1; }
        if ($request_uri ~* "/wp-admin/|/xmlrpc.php|wp-.*.php|/feed/|index.php|sitemap(_index)?.xml") { set $skip_cache 1; }
        if ($http_cookie ~* "comment_author|wordpress_[a-f0-9]+|wp-postpass|wordpress_no_cache|wordpress_logged_in") { set $skip_cache 1; }
        
        fastcgi_cache_bypass $skip_cache;
        fastcgi_no_cache $skip_cache;
        fastcgi_cache WORDPRESS;
        fastcgi_cache_valid 60m;
        
        include fastcgi_params;
        fastcgi_pass php-fpm;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_index index.php;
        fastcgi_intercept_errors on;
        fastcgi_buffer_size 128k;
        fastcgi_buffers 256 16k;
        fastcgi_busy_buffers_size 256k;
        fastcgi_temp_file_write_size 256k;
        fastcgi_read_timeout 300;
        
        add_header X-Cache-Status $upstream_cache_status;
    }

    #==========================================================================
    # Static File Caching
    #==========================================================================
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg|woff|woff2|ttf|eot)$ {
        expires 30d;
        add_header Cache-Control "public, immutable";
        access_log off;
    }

    #==========================================================================
    # Security: Deny PHP in Uploads
    #==========================================================================
    location ~* /(?:uploads|files)/.*\.php$ {
        deny all;
    }

    #==========================================================================
    # Security: Deny Hidden Files
    #==========================================================================
    location ~ /\.(?!well-known) {
        deny all;
    }
}
```

## 6. PHP Dockerfile (Alpine-based)

**Location:** `C:\wordpress-docker\php\Dockerfile`

```dockerfile
###############################################################################
# PHP-FPM Dockerfile (Alpine-based for optimal size)
# Base: Official WordPress PHP-FPM Alpine image
# 
# Includes:
# - OPcache (performance)
# - Redis (caching)
# - ImageMagick (image processing) - built from source
# - Zip/Exif extensions
###############################################################################

ARG PHP_VERSION=8.3
FROM wordpress:php${PHP_VERSION}-fpm-alpine

#==============================================================================
# Install System Dependencies
#==============================================================================
RUN apk add --no-cache \
    libzip-dev \
    zip \
    unzip \
    git \
    bash \
    fcgi \
    imagemagick \
    imagemagick-libs \
    libgomp

#==============================================================================
# Install Core PHP Extensions
#==============================================================================
RUN docker-php-ext-install opcache zip exif

#==============================================================================
# Install Redis Extension
#==============================================================================
RUN apk add --no-cache --virtual .build-deps $PHPIZE_DEPS \
    && pecl install redis \
    && docker-php-ext-enable redis \
    && apk del .build-deps

#==============================================================================
# Install ImageMagick from Source
# (PECL version is broken for PHP 8.2+)
#==============================================================================
RUN apk add --no-cache --virtual .imagick-build-deps \
    $PHPIZE_DEPS \
    imagemagick-dev \
    libtool \
    && git clone https://github.com/Imagick/imagick.git --depth 1 /tmp/imagick \
    && cd /tmp/imagick \
    && phpize \
    && ./configure \
    && make \
    && make install \
    && docker-php-ext-enable imagick \
    && cd / \
    && rm -rf /tmp/imagick \
    && apk del .imagick-build-deps

#==============================================================================
# Create Health Check Script
#==============================================================================
RUN echo '#!/bin/sh' > /usr/local/bin/php-fpm-healthcheck && \
    echo 'SCRIPT_NAME=/ping SCRIPT_FILENAME=/ping REQUEST_METHOD=GET cgi-fcgi -bind -connect 127.0.0.1:9000 || exit 1' >> /usr/local/bin/php-fpm-healthcheck && \
    chmod +x /usr/local/bin/php-fpm-healthcheck

#==============================================================================
# Create Log Directory
#==============================================================================
RUN mkdir -p /var/log/php && chown www-data:www-data /var/log/php

#==============================================================================
# Copy Custom Configuration
#==============================================================================
COPY php.ini /usr/local/etc/php/conf.d/custom.ini
COPY php-fpm.conf /usr/local/etc/php-fpm.d/zz-custom.conf

WORKDIR /var/www/html

EXPOSE 9000

CMD ["php-fpm"]
```

## 7. PHP Configuration

**Location:** `C:\wordpress-docker\php\php.ini`

```ini
###############################################################################
# Custom PHP Configuration
# Optimized for WordPress with security and performance
###############################################################################

#==============================================================================
# PERFORMANCE SETTINGS
#==============================================================================

max_execution_time = 300
max_input_time = 300
memory_limit = 512M
post_max_size = 256M
upload_max_filesize = 256M
max_input_vars = 3000

#==============================================================================
# ERROR REPORTING (Production Settings)
#==============================================================================

display_errors = Off
display_startup_errors = Off
log_errors = On
error_log = /var/log/php/error.log
error_reporting = E_ALL & ~E_DEPRECATED & ~E_STRICT

#==============================================================================
# SESSION SETTINGS
#==============================================================================

session.save_handler = files
session.save_path = "/tmp"
session.gc_maxlifetime = 3600
session.cookie_httponly = 1
session.cookie_secure = 1
session.use_strict_mode = 1

#==============================================================================
# SECURITY SETTINGS
#==============================================================================

expose_php = Off
allow_url_fopen = On
allow_url_include = Off
disable_functions = exec,passthru,shell_exec,system,proc_open,popen,curl_exec,curl_multi_exec,parse_ini_file,show_source

#==============================================================================
# OPCACHE SETTINGS (Production)
#==============================================================================

opcache.enable = 1
opcache.enable_cli = 0
opcache.memory_consumption = 256
opcache.interned_strings_buffer = 16
opcache.max_accelerated_files = 10000
opcache.max_wasted_percentage = 10
opcache.validate_timestamps = 1
opcache.revalidate_freq = 60
opcache.save_comments = 1
opcache.fast_shutdown = 1

#==============================================================================
# REALPATH CACHE
#==============================================================================

realpath_cache_size = 4096K
realpath_cache_ttl = 600

#==============================================================================
# FILE UPLOADS
#==============================================================================

file_uploads = On
max_file_uploads = 20

#==============================================================================
# DATE/TIME
#==============================================================================

date.timezone = UTC

#==============================================================================
# MYSQLI SETTINGS
#==============================================================================

mysqli.default_socket = /var/run/mysqld/mysqld.sock
```

## 8. PHP-FPM Configuration

**Location:** `C:\wordpress-docker\php\php-fpm.conf`

```ini
###############################################################################
# PHP-FPM Pool Configuration
# Controls process management and resource allocation
###############################################################################

[www]

#==============================================================================
# PROCESS MANAGER SETTINGS
#==============================================================================

pm = dynamic
pm.max_children = 50
pm.start_servers = 10
pm.min_spare_servers = 5
pm.max_spare_servers = 20
pm.max_requests = 500
pm.process_idle_timeout = 10s

#==============================================================================
# PERFORMANCE & TIMEOUTS
#==============================================================================

request_terminate_timeout = 300s
request_slowlog_timeout = 10s
slowlog = /var/log/php/slow.log

#==============================================================================
# ERROR LOGGING
#==============================================================================

catch_workers_output = yes
php_flag[display_errors] = off
php_admin_value[error_log] = /var/log/php/fpm-error.log
php_admin_flag[log_errors] = on

#==============================================================================
# SECURITY
#==============================================================================

security.limit_extensions = .php

#==============================================================================
# STATUS & PING PAGES
#==============================================================================

pm.status_path = /status
ping.path = /ping
ping.response = pong

#==============================================================================
# ENVIRONMENT VARIABLES
#==============================================================================

clear_env = no
```

## 9. MariaDB Configuration

**Location:** `C:\wordpress-docker\mariadb\my.cnf`

```ini
###############################################################################
# MariaDB Custom Configuration
# Optimized for WordPress performance and reliability
###############################################################################

[mysqld]

#==============================================================================
# BASIC SETTINGS
#==============================================================================

user = mysql
pid-file = /var/run/mysqld/mysqld.pid
socket = /var/run/mysqld/mysqld.sock
port = 3306
basedir = /usr
datadir = /var/lib/mysql
tmpdir = /tmp

#==============================================================================
# CHARACTER SET & COLLATION
#==============================================================================

character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci
init_connect = 'SET NAMES utf8mb4'

#==============================================================================
# NETWORKING
#==============================================================================

skip-external-locking
bind-address = 0.0.0.0
max_connections = 200
max_allowed_packet = 256M
connect_timeout = 10
wait_timeout = 600
interactive_timeout = 600

#==============================================================================
# QUERY CACHE (Disabled in MariaDB 10.3+)
#==============================================================================

query_cache_type = 0
query_cache_size = 0

#==============================================================================
# LOGGING
#==============================================================================

general_log = 0
slow_query_log = 1
slow_query_log_file = /var/log/mysql/slow.log
long_query_time = 2
log_error = /var/log/mysql/error.log

#==============================================================================
# INNODB SETTINGS
#==============================================================================

innodb_buffer_pool_size = 512M
innodb_log_file_size = 128M
innodb_log_buffer_size = 16M
innodb_flush_log_at_trx_commit = 2
innodb_file_per_table = 1
innodb_flush_method = O_DIRECT

#==============================================================================
# PERFORMANCE SCHEMA
#==============================================================================

performance_schema = ON

#==============================================================================
# BINARY LOGGING
#==============================================================================

log_bin = /var/log/mysql/mariadb-bin
log_bin_index = /var/log/mysql/mariadb-bin.index
expire_logs_days = 7
max_binlog_size = 100M

#==============================================================================
# TABLE SETTINGS
#==============================================================================

table_open_cache = 4096
table_definition_cache = 2048
open_files_limit = 65535

#==============================================================================
# THREAD SETTINGS
#==============================================================================

thread_cache_size = 50
thread_stack = 256K

#==============================================================================
# MYISAM SETTINGS
#==============================================================================

key_buffer_size = 128M
myisam_sort_buffer_size = 128M

#==============================================================================
# SECURITY
#==============================================================================

local_infile = 0

#==============================================================================
# CLIENT CONFIGURATION
#==============================================================================

[client]
port = 3306
socket = /var/run/mysqld/mysqld.sock
default-character-set = utf8mb4

[mysql]
no-auto-rehash
default-character-set = utf8mb4

[mysqldump]
quick
quote-names
max_allowed_packet = 256M
default-character-set = utf8mb4
```

## 10. MariaDB Initialization Script

**Location:** `C:\wordpress-docker\mariadb\init\init.sql`

```sql
-- ##############################################################################
-- # MariaDB Initialization Script
-- # Runs automatically on first container startup
-- ##############################################################################

-- Optimize system tables
OPTIMIZE TABLE mysql.user;
OPTIMIZE TABLE mysql.db;

-- Flush privileges
FLUSH PRIVILEGES;

-- Display databases (for verification in logs)
SHOW DATABASES;

-- ##############################################################################
-- # Custom initialization below (uncomment as needed)
-- ##############################################################################

-- Example: Create additional database
-- CREATE DATABASE IF NOT EXISTS `wordpress_staging` 
--     CHARACTER SET utf8mb4 
--     COLLATE utf8mb4_unicode_ci;

-- Example: Grant privileges
-- GRANT ALL PRIVILEGES ON `wordpress_staging`.* TO 'wpuser'@'%';

-- Example: Create read-only user
-- CREATE USER IF NOT EXISTS 'readonly'@'%' IDENTIFIED BY 'ReadOnlyPass123!';
-- GRANT SELECT ON wordpress.* TO 'readonly'@'%';

-- Apply changes
FLUSH PRIVILEGES;
```

***

# Windows PowerShell Scripts

## 1. Complete Setup Script

**Location:** `C:\wordpress-docker\scripts\setup.ps1`

```powershell
###############################################################################
# Complete WordPress Docker Setup Script for Windows 11
# 
# This script automates the entire setup process:
# - Creates directory structure
# - Generates SSL certificates
# - Adds domain to hosts file
# - Builds and starts Docker containers
###############################################################################

param(
    [switch]$SkipSSL = $false,
    [switch]$SkipBuild = $false
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host " WordPress Docker Complete Setup" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Check if running as Administrator
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "⚠️  WARNING: Not running as Administrator" -ForegroundColor Yellow
    Write-Host "Some features may not work (hosts file modification, SSL trust)" -ForegroundColor Yellow
    Write-Host ""
}

# Navigate to project root
$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $projectRoot

Write-Host "📁 Project directory: $projectRoot" -ForegroundColor Green
Write-Host ""

#==============================================================================
# Step 1: Verify Prerequisites
#==============================================================================

Write-Host "[1/6] Checking prerequisites..." -ForegroundColor Yellow

# Check Docker
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Docker not found! Please install Docker Desktop." -ForegroundColor Red
    exit 1
}

$dockerVersion = docker --version
Write-Host "✓ Docker found: $dockerVersion" -ForegroundColor Green

# Check docker-compose
if (-not (Get-Command docker-compose -ErrorAction SilentlyContinue)) {
    Write-Host "❌ docker-compose not found!" -ForegroundColor Red
    exit 1
}

$composeVersion = docker-compose --version
Write-Host "✓ docker-compose found: $composeVersion" -ForegroundColor Green

Write-Host ""

#==============================================================================
# Step 2: Create Directory Structure
#==============================================================================

Write-Host "[2/6] Creating directory structure..." -ForegroundColor Yellow

$directories = @(
    "nginx\conf.d",
    "php",
    "mariadb\init",
    "ssl",
    "scripts",
    "backups",
    "logs\nginx",
    "logs\php",
    "logs\mariadb"
)

foreach ($dir in $directories) {
    $fullPath = Join-Path $projectRoot $dir
    if (-not (Test-Path $fullPath)) {
        New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
        Write-Host "✓ Created: $dir" -ForegroundColor Green
    } else {
        Write-Host "✓ Exists: $dir" -ForegroundColor Gray
    }
}

Write-Host ""

#==============================================================================
# Step 3: Check .env File
#==============================================================================

Write-Host "[3/6] Checking environment configuration..." -ForegroundColor Yellow

$envFile = Join-Path $projectRoot ".env"
if (-not (Test-Path $envFile)) {
    Write-Host "❌ .env file not found!" -ForegroundColor Red
    Write-Host "Please create .env file with your configuration." -ForegroundColor Yellow
    exit 1
}

# Load environment variables
Get-Content $envFile | ForEach-Object {
    if ($_ -match '^\s*([^#][^=]+)=(.+)$') {
        $name = $matches[1].Trim()
        $value = $matches[2].Trim()
        Set-Item -Path "env:$name" -Value $value
    }
}

Write-Host "✓ Environment file loaded" -ForegroundColor Green

# Check if passwords were changed
if ($env:WORDPRESS_DB_PASSWORD -eq "ChangeThisPassword123!" -or
    $env:MYSQL_ROOT_PASSWORD -eq "ChangeRootPassword123!" -or
    $env:WORDPRESS_ADMIN_PASSWORD -eq "ChangeAdminPassword123!") {
    
    Write-Host "⚠️  WARNING: Default passwords detected in .env file!" -ForegroundColor Yellow
    Write-Host "Please change all passwords before production use." -ForegroundColor Yellow
}

Write-Host ""

#==============================================================================
# Step 4: Generate SSL Certificates
#==============================================================================

if (-not $SkipSSL) {
    Write-Host "[4/6] Generating SSL certificates..." -ForegroundColor Yellow
    
    $sslScript = Join-Path $PSScriptRoot "ssl-setup.ps1"
    if (Test-Path $sslScript) {
        & $sslScript
    } else {
        Write-Host "⚠️  ssl-setup.ps1 not found, skipping SSL generation" -ForegroundColor Yellow
    }
    
    Write-Host ""
} else {
    Write-Host "[4/6] Skipping SSL generation (--SkipSSL specified)" -ForegroundColor Gray
    Write-Host ""
}

#==============================================================================
# Step 5: Build Docker Containers
#==============================================================================

if (-not $SkipBuild) {
    Write-Host "[5/6] Building Docker containers..." -ForegroundColor Yellow
    Write-Host "This may take 5-10 minutes on first run..." -ForegroundColor Cyan
    
    docker-compose build --no-cache
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Docker build failed!" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "✓ Docker containers built successfully" -ForegroundColor Green
    Write-Host ""
} else {
    Write-Host "[5/6] Skipping Docker build (--SkipBuild specified)" -ForegroundColor Gray
    Write-Host ""
}

#==============================================================================
# Step 6: Start Docker Containers
#==============================================================================

Write-Host "[6/6] Starting Docker containers..." -ForegroundColor Yellow

docker-compose up -d

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to start containers!" -ForegroundColor Red
    exit 1
}

Write-Host "✓ Containers started successfully" -ForegroundColor Green
Write-Host ""

#==============================================================================
# Wait for Services to Be Ready
#==============================================================================

Write-Host "⏳ Waiting for services to be ready..." -ForegroundColor Yellow
Start-Sleep -Seconds 15

#==============================================================================
# Display Status
#==============================================================================

Write-Host ""
Write-Host "=========================================" -ForegroundColor Green
Write-Host " SETUP COMPLETE!" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green
Write-Host ""

# Get container status
$containers = docker-compose ps --format json | ConvertFrom-Json

Write-Host "📦 Container Status:" -ForegroundColor Cyan
foreach ($container in $containers) {
    $status = if ($container.State -eq "running") { "✓" } else { "✗" }
    $color = if ($container.State -eq "running") { "Green" } else { "Red" }
    Write-Host "$status $($container.Service): $($container.State)" -ForegroundColor $color
}

Write-Host ""
Write-Host "🌐 Access URLs:" -ForegroundColor Cyan
Write-Host "   WordPress:   https://$env:DOMAIN_NAME" -ForegroundColor White
Write-Host "   Admin:       https://$env:DOMAIN_NAME/wp-admin" -ForegroundColor White
Write-Host "   phpMyAdmin:  http://localhost:$env:PHPMYADMIN_PORT" -ForegroundColor White
Write-Host ""

Write-Host "📝 Next Steps:" -ForegroundColor Cyan
Write-Host "1. Open your browser and navigate to https://$env:DOMAIN_NAME" -ForegroundColor White
Write-Host "2. Accept the self-signed certificate warning" -ForegroundColor White
Write-Host "3. Complete WordPress installation" -ForegroundColor White
Write-Host "4. Login with credentials from .env file" -ForegroundColor White
Write-Host ""

Write-Host "📚 Useful Commands:" -ForegroundColor Cyan
Write-Host "   View logs:     .\scripts\logs.ps1" -ForegroundColor White
Write-Host "   Stop:          .\scripts\stop.ps1" -ForegroundColor White
Write-Host "   Backup:        .\scripts\backup.ps1" -ForegroundColor White
Write-Host "   Restart:       docker-compose restart" -ForegroundColor White
Write-Host ""

Write-Host "✓ Setup completed successfully!" -ForegroundColor Green
Write-Host ""
```

## 2. SSL Setup Script

**Location:** `C:\wordpress-docker\scripts\ssl-setup.ps1`

```powershell
###############################################################################
# SSL Certificate Generator for Windows 11
# Generates self-signed SSL certificates for local development
###############################################################################

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host " SSL Certificate Generator" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Check for Administrator privileges
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "⚠️  WARNING: Not running as Administrator" -ForegroundColor Yellow
    Write-Host "SSL certificate will be generated but not trusted automatically" -ForegroundColor Yellow
    Write-Host ""
}

# Navigate to project root
$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $projectRoot

# Load environment variables
$envFile = Join-Path $projectRoot ".env"
if (Test-Path $envFile) {
    Get-Content $envFile | ForEach-Object {
        if ($_ -match '^\s*([^#][^=]+)=(.+)$') {
            $name = $matches[1].Trim()
            $value = $matches[2].Trim()
            Set-Item -Path "env:$name" -Value $value
        }
    }
}

#==============================================================================
# Locate OpenSSL
#==============================================================================

Write-Host "[1/4] Locating OpenSSL..." -ForegroundColor Yellow

$opensslPaths = @(
    "C:\Program Files\Git\usr\bin\openssl.exe",
    "C:\Program Files\OpenSSL-Win64\bin\openssl.exe",
    "C:\Program Files (x86)\OpenSSL-Win32\bin\openssl.exe"
)

$opensslPath = $null
foreach ($path in $opensslPaths) {
    if (Test-Path $path) {
        $opensslPath = $path
        break
    }
}

# Check if openssl is in PATH
if (-not $opensslPath) {
    $opensslInPath = Get-Command openssl -ErrorAction SilentlyContinue
    if ($opensslInPath) {
        $opensslPath = "openssl"
    }
}

if (-not $opensslPath) {
    Write-Host "❌ OpenSSL not found!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please install one of the following:" -ForegroundColor Yellow
    Write-Host "1. Git for Windows (includes OpenSSL)" -ForegroundColor White
    Write-Host "   Download: https://git-scm.com/download/win" -ForegroundColor White
    Write-Host "2. OpenSSL for Windows" -ForegroundColor White
    Write-Host "   Download: https://slproweb.com/products/Win32OpenSSL.html" -ForegroundColor White
    Write-Host ""
    exit 1
}

Write-Host "✓ OpenSSL found: $opensslPath" -ForegroundColor Green
Write-Host ""

#==============================================================================
# Create SSL Directory
#==============================================================================

Write-Host "[2/4] Creating SSL directory..." -ForegroundColor Yellow

$sslDir = Join-Path $projectRoot "ssl"
if (-not (Test-Path $sslDir)) {
    New-Item -ItemType Directory -Path $sslDir -Force | Out-Null
}

Set-Location $sslDir
Write-Host "✓ SSL directory: $sslDir" -ForegroundColor Green
Write-Host ""

#==============================================================================
# Generate SSL Certificate
#==============================================================================

Write-Host "[3/4] Generating SSL certificate..." -ForegroundColor Yellow

$domain = if ($env:DOMAIN_NAME) { $env:DOMAIN_NAME } else { "localhost.local" }
$country = if ($env:SSL_COUNTRY) { $env:SSL_COUNTRY } else { "US" }
$state = if ($env:SSL_STATE) { $env:SSL_STATE } else { "State" }
$city = if ($env:SSL_CITY) { $env:SSL_CITY } else { "City" }
$org = if ($env:SSL_ORG) { $env:SSL_ORG } else { "Organization" }
$orgUnit = if ($env:SSL_ORG_UNIT) { $env:SSL_ORG_UNIT } else { "IT" }

$certParams = @(
    "req", "-x509", "-nodes", "-days", "365", "-newkey", "rsa:2048",
    "-keyout", "key.pem",
    "-out", "cert.pem",
    "-subj", "/C=$country/ST=$state/L=$city/O=$org/OU=$orgUnit/CN=$domain",
    "-addext", "subjectAltName=DNS:localhost,DNS:$domain,DNS:*.$domain,IP:127.0.0.1"
)

& $opensslPath $certParams 2>&1 | Out-Null

if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ SSL certificate generated successfully!" -ForegroundColor Green
    Write-Host "  Certificate: $sslDir\cert.pem" -ForegroundColor Gray
    Write-Host "  Private Key: $sslDir\key.pem" -ForegroundColor Gray
    Write-Host ""
} else {
    Write-Host "❌ Certificate generation failed!" -ForegroundColor Red
    exit 1
}

#==============================================================================
# Add to Windows Hosts File
#==============================================================================

Write-Host "[4/4] Updating Windows hosts file..." -ForegroundColor Yellow

$hostsPath = "C:\Windows\System32\drivers\etc\hosts"
$hostsEntry = "127.0.0.1`t$domain"

try {
    $hostsContent = Get-Content $hostsPath -ErrorAction SilentlyContinue
    $entryExists = $hostsContent | Where-Object { $_ -match "127\.0\.0\.1\s+$domain" }
    
    if (-not $entryExists) {
        if ($isAdmin) {
            # Backup hosts file
            Copy-Item $hostsPath "$hostsPath.backup" -Force
            
            # Add entry
            Add-Content -Path $hostsPath -Value "`n$hostsEntry"
            Write-Host "✓ Added $domain to hosts file" -ForegroundColor Green
        } else {
            Write-Host "⚠️  Cannot modify hosts file (not Administrator)" -ForegroundColor Yellow
            Write-Host "Please manually add this line to $hostsPath" -ForegroundColor Yellow
            Write-Host "  $hostsEntry" -ForegroundColor White
        }
    } else {
        Write-Host "✓ $domain already in hosts file" -ForegroundColor Green
    }
} catch {
    Write-Host "⚠️  Could not modify hosts file: $_" -ForegroundColor Yellow
}

Write-Host ""

#==============================================================================
# Instructions to Trust Certificate
#==============================================================================

Write-Host "=========================================" -ForegroundColor Green
Write-Host " NEXT STEPS" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green
Write-Host ""

Write-Host "📝 To trust the SSL certificate in Windows:" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Open File Explorer and navigate to:" -ForegroundColor White
Write-Host "   $sslDir" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Double-click 'cert.pem'" -ForegroundColor White
Write-Host ""
Write-Host "3. Click 'Install Certificate'" -ForegroundColor White
Write-Host ""
Write-Host "4. Select 'Local Machine' → Click 'Next'" -ForegroundColor White
Write-Host ""
Write-Host "5. Choose 'Place all certificates in the following store'" -ForegroundColor White
Write-Host ""
Write-Host "6. Click 'Browse' → Select 'Trusted Root Certification Authorities'" -ForegroundColor White
Write-Host ""
Write-Host "7. Click 'Next' → Click 'Finish'" -ForegroundColor White
Write-Host ""
Write-Host "8. Click 'Yes' on the security warning" -ForegroundColor White
Write-Host ""
Write-Host "9. Restart your browser" -ForegroundColor White
Write-Host ""

Write-Host "✓ SSL setup complete!" -ForegroundColor Green
Write-Host ""

Set-Location $projectRoot
```

## 3. Backup Script

**Location:** `C:\wordpress-docker\scripts\backup.ps1`

```powershell
###############################################################################
# WordPress Docker Backup Script for Windows
# Creates complete backup: Database + Files + Configs
###############################################################################

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host " WordPress Docker Backup" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Navigate to project root
$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $projectRoot

# Load environment variables
$envFile = Join-Path $projectRoot ".env"
if (Test-Path $envFile) {
    Get-Content $envFile | ForEach-Object {
        if ($_ -match '^\s*([^#][^=]+)=(.+)$') {
            $name = $matches[1].Trim()
            $value = $matches[2].Trim()
            Set-Item -Path "env:$name" -Value $value
        }
    }
} else {
    Write-Host "❌ .env file not found!" -ForegroundColor Red
    exit 1
}

# Configuration
$backupDir = Join-Path $projectRoot "backups"
$date = Get-Date -Format "yyyyMMdd_HHmmss"
$backupName = "wordpress_backup_$date"
$containerPrefix = if ($env:COMPOSE_PROJECT_NAME) { $env:COMPOSE_PROJECT_NAME } else { "wordpress-docker" }

Write-Host "📦 Backup: $backupName" -ForegroundColor Cyan
Write-Host "⏰ Started: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan
Write-Host ""

# Create backup directory
$backupPath = Join-Path $backupDir $backupName
New-Item -ItemType Directory -Path $backupPath -Force | Out-Null

#==============================================================================
# 1. Backup Database
#==============================================================================

Write-Host "[1/3] Backing up database..." -ForegroundColor Yellow

$dbFile = Join-Path $backupPath "database.sql"

docker exec "$($containerPrefix)_mariadb" mysqldump `
    -u root `
    -p"$env:MYSQL_ROOT_PASSWORD" `
    --single-transaction `
    --quick `
    --lock-tables=false `
    --routines `
    --triggers `
    --events `
    "$env:WORDPRESS_DB_NAME" | Out-File -FilePath $dbFile -Encoding UTF8

if ($LASTEXITCODE -eq 0) {
    $dbSize = [math]::Round((Get-Item $dbFile).Length / 1MB, 2)
    Write-Host "✓ Database backed up ($dbSize MB)" -ForegroundColor Green
} else {
    Write-Host "❌ Database backup failed!" -ForegroundColor Red
    exit 1
}

Write-Host ""

#==============================================================================
# 2. Backup WordPress Files
#==============================================================================

Write-Host "[2/3] Backing up WordPress files..." -ForegroundColor Yellow

docker run --rm `
    --volumes-from "$($containerPrefix)_wordpress" `
    -v "$($backupPath):/backup" `
    alpine `
    tar czf /backup/wordpress_files.tar.gz -C /var/www/html .

if ($LASTEXITCODE -eq 0) {
    $filesSize = [math]::Round((Get-Item (Join-Path $backupPath "wordpress_files.tar.gz")).Length / 1MB, 2)
    Write-Host "✓ WordPress files backed up ($filesSize MB)" -ForegroundColor Green
} else {
    Write-Host "❌ WordPress files backup failed!" -ForegroundColor Red
    exit 1
}

Write-Host ""

#==============================================================================
# 3. Backup Configuration Files
#==============================================================================

Write-Host "[3/3] Backing up configuration files..." -ForegroundColor Yellow

# Create temp directory
$tempDir = Join-Path $env:TEMP "wp-config-$date"
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

# Copy config files
Copy-Item -Path (Join-Path $projectRoot "nginx\conf.d") -Destination (Join-Path $tempDir "nginx-conf.d") -Recurse
Copy-Item -Path (Join-Path $projectRoot "php\php.ini") -Destination $tempDir
Copy-Item -Path (Join-Path $projectRoot "php\php-fpm.conf") -Destination $tempDir
Copy-Item -Path (Join-Path $projectRoot "mariadb\my.cnf") -Destination $tempDir
Copy-Item -Path (Join-Path $projectRoot ".env") -Destination $tempDir

# Create tar.gz
docker run --rm `
    -v "$($tempDir):/source" `
    -v "$($backupPath):/backup" `
    alpine `
    tar czf /backup/config_files.tar.gz -C /source .

# Cleanup temp directory
Remove-Item -Path $tempDir -Recurse -Force

$configSize = [math]::Round((Get-Item (Join-Path $backupPath "config_files.tar.gz")).Length / 1MB, 2)
Write-Host "✓ Configuration files backed up ($configSize MB)" -ForegroundColor Green

Write-Host ""

#==============================================================================
# 4. Create Backup Info File
#==============================================================================

$infoFile = Join-Path $backupPath "backup_info.txt"
@"
WordPress Docker Backup
=======================

Backup Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Backup Name: $backupName

Environment:
- WordPress Database: $env:WORDPRESS_DB_NAME
- MariaDB Version: $env:MARIADB_VERSION
- PHP Version: $env:PHP_VERSION
- Domain: $env:DOMAIN_NAME

Backup Contents:
- database.sql (MariaDB database dump)
- wordpress_files.tar.gz (WordPress files)
- config_files.tar.gz (Configuration files)

Restore Instructions:
To restore this backup, run:
.\scripts\restore.ps1 -BackupName $backupName

Note: Ensure Docker containers are running before restoring.
"@ | Out-File -FilePath $infoFile -Encoding UTF8

#==============================================================================
# 5. Compress Backup
#==============================================================================

Write-Host "📦 Compressing backup archive..." -ForegroundColor Yellow

$archivePath = "$backupPath.zip"
Compress-Archive -Path "$backupPath\*" -DestinationPath $archivePath -Force

# Remove uncompressed backup
Remove-Item -Path $backupPath -Recurse -Force

$archiveSize = [math]::Round((Get-Item $archivePath).Length / 1MB, 2)
Write-Host "✓ Backup compressed ($archiveSize MB)" -ForegroundColor Green

Write-Host ""

#==============================================================================
# 6. Cleanup Old Backups
#==============================================================================

$retentionDays = if ($env:BACKUP_RETENTION_DAYS) { [int]$env:BACKUP_RETENTION_DAYS } else { 30 }

Write-Host "🧹 Cleaning up backups older than $retentionDays days..." -ForegroundColor Yellow

$cutoffDate = (Get-Date).AddDays(-$retentionDays)
$oldBackups = Get-ChildItem -Path $backupDir -Filter "wordpress_backup_*.zip" | 
    Where-Object { $_.LastWriteTime -lt $cutoffDate }

$deletedCount = 0
foreach ($backup in $oldBackups) {
    Remove-Item -Path $backup.FullName -Force
    $deletedCount++
}

if ($deletedCount -gt 0) {
    Write-Host "✓ Deleted $deletedCount old backup(s)" -ForegroundColor Green
} else {
    Write-Host "✓ No old backups to delete" -ForegroundColor Green
}

Write-Host ""

#==============================================================================
# Display Summary
#==============================================================================

Write-Host "=========================================" -ForegroundColor Green
Write-Host " BACKUP COMPLETE" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green
Write-Host ""
Write-Host "📁 Backup file:  $archivePath" -ForegroundColor Cyan
Write-Host "💾 Backup size:  $archiveSize MB" -ForegroundColor Cyan
Write-Host "⏰ Completed:    $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan
Write-Host ""
Write-Host "📝 To restore this backup:" -ForegroundColor Yellow
Write-Host "   .\scripts\restore.ps1 -BackupName $backupName" -ForegroundColor White
Write-Host ""
```

## 4. Restore Script

**Location:** `C:\wordpress-docker\scripts\restore.ps1`

```powershell
###############################################################################
# WordPress Docker Restore Script for Windows
# Restores WordPress from backup
###############################################################################

param(
    [Parameter(Mandatory=$false)]
    [string]$BackupName
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host " WordPress Docker Restore" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Navigate to project root
$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $projectRoot

# Load environment variables
$envFile = Join-Path $projectRoot ".env"
if (Test-Path $envFile) {
    Get-Content $envFile | ForEach-Object {
        if ($_ -match '^\s*([^#][^=]+)=(.+)$') {
            $name = $matches[1].Trim()
            $value = $matches[2].Trim()
            Set-Item -Path "env:$name" -Value $value
        }
    }
} else {
    Write-Host "❌ .env file not found!" -ForegroundColor Red
    exit 1
}

$backupDir = Join-Path $projectRoot "backups"
$containerPrefix = if ($env:COMPOSE_PROJECT_NAME) { $env:COMPOSE_PROJECT_NAME } else { "wordpress-docker" }

#==============================================================================
# List Available Backups if not specified
#==============================================================================

if (-not $BackupName) {
    Write-Host "📦 Available backups:" -ForegroundColor Cyan
    Write-Host ""
    
    $backups = Get-ChildItem -Path $backupDir -Filter "wordpress_backup_*.zip" | 
        Sort-Object LastWriteTime -Descending
    
    if ($backups.Count -eq 0) {
        Write-Host "No backups found in $backupDir" -ForegroundColor Yellow
        exit 1
    }
    
    for ($i = 0; $i -lt $backups.Count; $i++) {
        $backup = $backups[$i]
        $size = [math]::Round($backup.Length / 1MB, 2)
        $date = $backup.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
        Write-Host "[$($i+1)] $($backup.BaseName) ($size MB) - $date" -ForegroundColor White
    }
    
    Write-Host ""
    Write-Host "Usage:" -ForegroundColor Yellow
    Write-Host "  .\scripts\restore.ps1 -BackupName wordpress_backup_20251027_140000" -ForegroundColor White
    Write-Host ""
    exit 0
}

#==============================================================================
# Locate Backup File
#==============================================================================

$backupFile = Join-Path $backupDir "$BackupName.zip"

if (-not (Test-Path $backupFile)) {
    # Try without .zip extension
    $backupFile = Join-Path $backupDir $BackupName
    if (-not (Test-Path $backupFile)) {
        Write-Host "❌ Backup not found: $BackupName" -ForegroundColor Red
        exit 1
    }
}

Write-Host "📦 Backup file: $backupFile" -ForegroundColor Cyan
$backupSize = [math]::Round((Get-Item $backupFile).Length / 1MB, 2)
Write-Host "💾 Backup size: $backupSize MB" -ForegroundColor Cyan
Write-Host ""

#==============================================================================
# Confirmation
#==============================================================================

Write-Host "⚠️  WARNING: This will OVERWRITE your current WordPress installation!" -ForegroundColor Red
Write-Host ""
$confirmation = Read-Host "Are you sure you want to continue? (yes/no)"

if ($confirmation -ne "yes") {
    Write-Host "❌ Restore cancelled" -ForegroundColor Yellow
    exit 0
}

Write-Host ""

#==============================================================================
# Extract Backup
#==============================================================================

Write-Host "[1/3] Extracting backup..." -ForegroundColor Yellow

$tempDir = Join-Path $env:TEMP "wp-restore-$((Get-Date).Ticks)"
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

Expand-Archive -Path $backupFile -DestinationPath $tempDir -Force

Write-Host "✓ Backup extracted" -ForegroundColor Green
Write-Host ""

#==============================================================================
# Restore Database
#==============================================================================

Write-Host "[2/3] Restoring database..." -ForegroundColor Yellow

$dbFile = Join-Path $tempDir "database.sql"

if (-not (Test-Path $dbFile)) {
    Write-Host "❌ database.sql not found in backup!" -ForegroundColor Red
    Remove-Item -Path $tempDir -Recurse -Force
    exit 1
}

Get-Content $dbFile | docker exec -i "$($containerPrefix)_mariadb" mysql `
    -u root `
    -p"$env:MYSQL_ROOT_PASSWORD" `
    "$env:WORDPRESS_DB_NAME"

if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Database restored" -ForegroundColor Green
} else {
    Write-Host "❌ Database restore failed!" -ForegroundColor Red
    Remove-Item -Path $tempDir -Recurse -Force
    exit 1
}

Write-Host ""

#==============================================================================
# Restore WordPress Files
#==============================================================================

Write-Host "[3/3] Restoring WordPress files..." -ForegroundColor Yellow

docker run --rm `
    --volumes-from "$($containerPrefix)_wordpress" `
    -v "$($tempDir):/backup" `
    alpine `
    sh -c "rm -rf /var/www/html/* && tar xzf /backup/wordpress_files.tar.gz -C /var/www/html && chown -R www-data:www-data /var/www/html"

if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ WordPress files restored" -ForegroundColor Green
} else {
    Write-Host "❌ WordPress files restore failed!" -ForegroundColor Red
    Remove-Item -Path $tempDir -Recurse -Force
    exit 1
}

Write-Host ""

#==============================================================================
# Cleanup
#==============================================================================

Write-Host "🧹 Cleaning up..." -ForegroundColor Yellow
Remove-Item -Path $tempDir -Recurse -Force
Write-Host "✓ Cleanup complete" -ForegroundColor Green
Write-Host ""

#==============================================================================
# Restart Containers
#==============================================================================

Write-Host "🔄 Restarting containers..." -ForegroundColor Yellow

docker-compose restart wordpress nginx

Write-Host "✓ Containers restarted" -ForegroundColor Green
Write-Host ""

#==============================================================================
# Display Summary
#==============================================================================

Write-Host "=========================================" -ForegroundColor Green
Write-Host " RESTORE COMPLETE" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green
Write-Host ""
Write-Host "✓ Your WordPress site has been restored from backup" -ForegroundColor Cyan
Write-Host ""
Write-Host "🌐 Access your site:" -ForegroundColor Yellow
Write-Host "   https://$env:DOMAIN_NAME" -ForegroundColor White
Write-Host ""
```

## 5. Start Script

**Location:** `C:\wordpress-docker\scripts\start.ps1`

```powershell
###############################################################################
# Start Docker Containers
###############################################################################

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "🚀 Starting WordPress Docker containers..." -ForegroundColor Cyan
Write-Host ""

# Navigate to project root
$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $projectRoot

# Start containers
docker-compose up -d

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✓ Containers started successfully!" -ForegroundColor Green
    Write-Host ""
    
    # Wait a moment for containers to initialize
    Start-Sleep -Seconds 3
    
    # Display status
    Write-Host "Container Status:" -ForegroundColor Cyan
    docker-compose ps
    
    Write-Host ""
    Write-Host "Access URLs:" -ForegroundColor Cyan
    
    # Load domain from .env
    $envFile = Join-Path $projectRoot ".env"
    if (Test-Path $envFile) {
        Get-Content $envFile | ForEach-Object {
            if ($_ -match '^\s*DOMAIN_NAME\s*=\s*(.+)$') {
                $domain = $matches[1].Trim()
                Write-Host "  WordPress: https://$domain" -ForegroundColor White
                Write-Host "  Admin:     https://$domain/wp-admin" -ForegroundColor White
            }
            if ($_ -match '^\s*PHPMYADMIN_PORT\s*=\s*(.+)$') {
                $port = $matches[1].Trim()
                Write-Host "  phpMyAdmin: http://localhost:$port" -ForegroundColor White
            }
        }
    }
    
    Write-Host ""
} else {
    Write-Host "❌ Failed to start containers" -ForegroundColor Red
    exit 1
}
```

## 6. Stop Script

**Location:** `C:\wordpress-docker\scripts\stop.ps1`

```powershell
###############################################################################
# Stop Docker Containers
###############################################################################

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "🛑 Stopping WordPress Docker containers..." -ForegroundColor Cyan
Write-Host ""

# Navigate to project root
$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $projectRoot

# Stop containers
docker-compose stop

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✓ Containers stopped successfully!" -ForegroundColor Green
    Write-Host ""
} else {
    Write-Host "❌ Failed to stop containers" -ForegroundColor Red
    exit 1
}
```

## 7. Logs Viewer Script

**Location:** `C:\wordpress-docker\scripts\logs.ps1`

```powershell
###############################################################################
# View Docker Container Logs
###############################################################################

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("all", "nginx", "wordpress", "mariadb", "phpmyadmin")]
    [string]$Service = "all",
    
    [Parameter(Mandatory=$false)]
    [int]$Lines = 100,
    
    [switch]$Follow
)

# Navigate to project root
$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $projectRoot

Write-Host ""
Write-Host "📋 Docker Container Logs" -ForegroundColor Cyan
Write-Host "Service: $Service" -ForegroundColor Gray
Write-Host ""

if ($Follow) {
    # Follow logs (live stream)
    if ($Service -eq "all") {
        docker-compose logs -f
    } else {
        docker-compose logs -f $Service
    }
} else {
    # Show last N lines
    if ($Service -eq "all") {
        docker-compose logs --tail=$Lines
    } else {
        docker-compose logs --tail=$Lines $Service
    }
}
```

***

# Step-by-Step Installation Guide

## Quick Start (5 Minutes)

### 1. Create Project Directory

```powershell
# Open PowerShell
cd C:\
mkdir wordpress-docker
cd wordpress-docker
```

### 2. Create All Files

Create all the configuration files listed above in their respective directories. You can:

**Option A: Create manually** using the file structure guide

**Option B: Create a setup script** to generate all files:

```powershell
# Create this as C:\wordpress-docker\create-files.ps1
# Then run: .\create-files.ps1
```

### 3. Configure Environment

```powershell
# Edit .env file
notepad .env

# Change these values:
# - WORDPRESS_DB_PASSWORD
# - MYSQL_ROOT_PASSWORD  
# - WORDPRESS_ADMIN_PASSWORD
# - WORDPRESS_ADMIN_USER
```

### 4. Run Setup

```powershell
# Open PowerShell as Administrator
cd C:\wordpress-docker

# Allow script execution (first time only)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Run complete setup
.\scripts\setup.ps1
```

### 5. Access WordPress

Open your browser:
```
https://localhost.local
```

Accept the security warning and complete WordPress installation!

***

## Detailed Installation Steps

### Step 1: Install Prerequisites

**Install Docker Desktop:**

1. Download from https://www.docker.com/products/docker-desktop
2. Run installer
3. Enable WSL 2 backend when prompted
4. Restart computer
5. Open Docker Desktop
6. Go to Settings → Resources → Increase RAM to at least 4GB
7. Apply & Restart

**Install Git for Windows:**

1. Download from https://git-scm.com/download/win
2. Run installer (use default options)
3. This includes OpenSSL needed for SSL certificates

**Verify:**

```powershell
docker --version
# Docker version 24.x.x

docker-compose --version
# Docker Compose version v2.x.x

git --version
# git version 2.x.x
```

### Step 2: Create Project Structure

```powershell
# Create main directory
cd C:\
mkdir wordpress-docker
cd wordpress-docker

# Create subdirectories
mkdir nginx, nginx\conf.d, php, mariadb, mariadb\init, ssl, scripts, backups, logs, logs\nginx, logs\php, logs\mariadb

# Verify structure
tree /F
```

### Step 3: Create Configuration Files

Create each file exactly as shown in the [Configuration Files](#configuration-files) section above.

**Quick checklist:**
- ✅ `.env`
- ✅ `docker-compose.yml`
- ✅ `nginx\Dockerfile`
- ✅ `nginx\nginx.conf`
- ✅ `nginx\conf.d\default.conf`
- ✅ `php\Dockerfile`
- ✅ `php\php.ini`
- ✅ `php\php-fpm.conf`
- ✅ `mariadb\my.cnf`
- ✅ `mariadb\init\init.sql`
- ✅ All PowerShell scripts in `scripts\`

### Step 4: Configure Environment Variables

```powershell
notepad .env
```

**IMPORTANT: Change these passwords!**

```env
# Change these:
WORDPRESS_DB_PASSWORD=YourStrongPassword123!
MYSQL_ROOT_PASSWORD=YourRootPassword456!
WORDPRESS_ADMIN_PASSWORD=YourAdminPassword789!
WORDPRESS_ADMIN_USER=yourusername

# Optional changes:
WORDPRESS_ADMIN_EMAIL=your.email@example.com
DOMAIN_NAME=mywordpress.local
TIMEZONE=America/New_York
```

### Step 5: Generate SSL Certificates

```powershell
# Open PowerShell as Administrator
cd C:\wordpress-docker

# Run SSL setup
.\scripts\ssl-setup.ps1
```

**Trust the certificate:**

1. Navigate to `C:\wordpress-docker\ssl`
2. Double-click `cert.pem`
3. Click "Install Certificate"
4. Select "Local Machine"
5. Choose "Place all certificates in the following store"
6. Click "Browse" → Select "Trusted Root Certification Authorities"
7. Click OK → Finish
8. Restart browser

### Step 6: Build Docker Containers

```powershell
# Build all containers (takes 5-10 minutes first time)
docker-compose build --no-cache
```

You'll see:
```
Building mariadb
Building wordpress
Building nginx
```

### Step 7: Start Containers

```powershell
# Start all services
docker-compose up -d
```

**Verify all containers are running:**

```powershell
docker-compose ps
```

Should show:
```
NAME                           STATUS    PORTS
wordpress-docker_mariadb       Up        3306/tcp
wordpress-docker_wordpress     Up        9000/tcp
wordpress-docker_nginx         Up        0.0.0.0:80->80/tcp, 0.0.0.0:443->443/tcp
wordpress-docker_phpmyadmin    Up        0.0.0.0:8080->80/tcp
```

### Step 8: Install WordPress

1. **Open browser** and go to:
   ```
   https://localhost.local
   ```

2. **Accept security warning:**
   - Chrome: Click "Advanced" → "Proceed to localhost.local"
   - Firefox: Click "Advanced" → "Accept the Risk and Continue"

3. **Complete WordPress Installation:**

   **Language Selection:**
   - Select your language
   - Click "Continue"

   **Site Information:**
   - Site Title: Your site name
   - Username: Your `WORDPRESS_ADMIN_USER` from .env
   - Password: Your `WORDPRESS_ADMIN_PASSWORD` from .env
   - Your Email: Your `WORDPRESS_ADMIN_EMAIL` from .env
   - Click "Install WordPress"

4. **Login:**
   - Enter your admin credentials
   - Click "Log In"

5. **Done!** You now have a working WordPress site.

---

# Usage Guide

## Daily Operations

### Start WordPress

```powershell
cd C:\wordpress-docker
.\scripts\start.ps1
```

### Stop WordPress

```powershell
cd C:\wordpress-docker
.\scripts\stop.ps1
```

### Restart Services

```powershell
# Restart all
docker-compose restart

# Restart specific service
docker-compose restart nginx
docker-compose restart wordpress
docker-compose restart mariadb
```

### View Logs

```powershell
# View all logs
.\scripts\logs.ps1

# View specific service
.\scripts\logs.ps1 -Service nginx
.\scripts\logs.ps1 -Service wordpress
.\scripts\logs.ps1 -Service mariadb

# Follow logs (live stream)
.\scripts\logs.ps1 -Follow

# Show last 50 lines
.\scripts\logs.ps1 -Lines 50
```

## Accessing Files

### Method 1: Windows File Manager (Configuration Files)

**All config files are in your project folder:**

```
C:\wordpress-docker\
  nginx\          ← Edit Nginx configs here
  php\            ← Edit PHP configs here
  mariadb\        ← Edit MariaDB configs here
  logs\           ← View logs here
```

**To edit:**
1. Open File Explorer
2. Navigate to `C:\wordpress-docker`
3. Open folder (nginx, php, or mariadb)
4. Right-click file → Edit with Notepad/VS Code
5. Save changes
6. Restart affected service:
   ```powershell
   docker-compose restart nginx
   docker-compose restart wordpress
   docker-compose restart mariadb
   ```

### Method 2: Docker Desktop (WordPress Files)

1. Open Docker Desktop
2. Click "Volumes" in left sidebar
3. Find `wordpress-docker_wordpress_data`
4. Click folder icon to browse in File Explorer
5. Navigate to view/edit WordPress files

### Method 3: Copy Files from Container

```powershell
# Copy entire WordPress directory to Windows
docker cp wordpress-docker_wordpress:/var/www/html C:\wordpress-files

# Edit files in C:\wordpress-files

# Copy back to container
docker cp C:\wordpress-files wordpress-docker_wordpress:/var/www/html

# Fix permissions
docker exec wordpress-docker_wordpress chown -R www-data:www-data /var/www/html
```

### Method 4: Access Container Shell

```powershell
# Enter WordPress container
docker exec -it wordpress-docker_wordpress bash

# Now you're inside the container
cd /var/www/html
ls -la
nano wp-config.php

# Exit container
exit
```

## Editing Configurations

### Change Upload Limit

**1. Edit PHP settings:**

```powershell
notepad php\php.ini
```

Change:
```ini
upload_max_filesize = 512M
post_max_size = 512M
```

**2. Edit Nginx settings:**

```powershell
notepad nginx\nginx.conf
```

Change:
```nginx
client_max_body_size 512M;
```

**3. Restart services:**

```powershell
docker-compose restart wordpress nginx
```

### Enable PHP Debug Mode

```powershell
notepad php\php.ini
```

Change:
```ini
display_errors = On
error_reporting = E_ALL
```

Restart:
```powershell
docker-compose restart wordpress
```

### Increase MariaDB Buffer Pool

```powershell
notepad mariadb\my.cnf
```

Change:
```ini
innodb_buffer_pool_size = 1G
```

Restart:
```powershell
docker-compose restart mariadb
```

## Installing WordPress Plugins & Themes

### Method 1: WordPress Admin (Easiest)

1. Login to WordPress admin
2. Go to **Plugins** → **Add New**
3. Search, install, and activate plugins
4. Go to **Appearance** → **Themes** → **Add New**
5. Search, install, and activate themes

### Method 2: Manual Upload

1. Download plugin/theme ZIP file
2. WordPress Admin → **Plugins/Themes** → **Add New** → **Upload**
3. Choose file and install

### Method 3: Direct File Copy

```powershell
# Copy plugin to container
docker cp C:\my-plugin.zip wordpress-docker_wordpress:/var/www/html/wp-content/plugins/

# Unzip inside container
docker exec wordpress-docker_wordpress unzip /var/www/html/wp-content/plugins/my-plugin.zip -d /var/www/html/wp-content/plugins/

# Fix permissions
docker exec wordpress-docker_wordpress chown -R www-data:www-data /var/www/html/wp-content
```

## Database Management

### Access phpMyAdmin

Open browser:
```
http://localhost:8080
```

**Login:**
- Server: `mariadb`
- Username: `root`
- Password: Your `MYSQL_ROOT_PASSWORD` from .env

### Access MariaDB Command Line

```powershell
# Connect as root
docker exec -it wordpress-docker_mariadb mysql -u root -p
# Enter your MYSQL_ROOT_PASSWORD

# Inside MySQL prompt:
SHOW DATABASES;
USE wordpress;
SHOW TABLES;
SELECT * FROM wp_users;
exit;
```

### Export Database

```powershell
docker exec wordpress-docker_mariadb mysqldump -u root -p[PASSWORD] wordpress > backup.sql
```

### Import Database

```powershell
Get-Content backup.sql | docker exec -i wordpress-docker_mariadb mysql -u root -p[PASSWORD] wordpress
```

### Optimize Database

```powershell
docker exec wordpress-docker_mariadb mysqlcheck -u root -p[PASSWORD] --optimize --all-databases
```

***

# Backup & Restore

## Creating Backups

### Full Backup (Recommended)

```powershell
cd C:\wordpress-docker
.\scripts\backup.ps1
```

**What's included:**
- ✅ Complete database dump
- ✅ All WordPress files (themes, plugins, uploads)
- ✅ All configuration files
- ✅ Compressed into single ZIP file

**Backup location:**
```
C:\wordpress-docker\backups\wordpress_backup_YYYYMMDD_HHMMSS.zip
```

### Automated Backups (Windows Task Scheduler)

**Create scheduled backup:**

1. Open Task Scheduler (`taskschd.msc`)
2. Click "Create Task"
3. **General tab:**
   - Name: "WordPress Daily Backup"
   - Run whether user is logged on or not
   - Run with highest privileges
4. **Triggers tab:**
   - New → Daily at 2:00 AM
5. **Actions tab:**
   - New → Start a program
   - Program: `powershell.exe`
   - Arguments: `-ExecutionPolicy Bypass -File "C:\wordpress-docker\scripts\backup.ps1"`
6. Click OK

## Restoring from Backup

### List Available Backups

```powershell
cd C:\wordpress-docker
.\scripts\restore.ps1
```

Shows all available backups with dates and sizes.

### Restore Specific Backup

```powershell
cd C:\wordpress-docker
.\scripts\restore.ps1 -BackupName wordpress_backup_20251027_140000
```

**⚠️ WARNING:** This will overwrite your current installation!

### What Gets Restored

- ✅ Database (all posts, pages, settings)
- ✅ WordPress files (themes, plugins, uploads)
- ✅ Configuration files

***

# Troubleshooting

## Issue: Containers Won't Start

**Check Docker Desktop is running:**

```powershell
docker --version
# If error, open Docker Desktop and wait for it to start
```

**Check port conflicts:**

```powershell
# Check if ports 80, 443, 8080 are in use
netstat -ano | findstr :80
netstat -ano | findstr :443
netstat -ano | findstr :8080

# Kill process if needed (find PID from netstat output)
taskkill /PID [PID_NUMBER] /F
```

**Check Docker resources:**

1. Open Docker Desktop
2. Settings → Resources
3. Ensure at least 4GB RAM allocated
4. Ensure at least 20GB disk space

**View error logs:**

```powershell
.\scripts\logs.ps1 -Service mariadb
.\scripts\logs.ps1 -Service wordpress
.\scripts\logs.ps1 -Service nginx
```

## Issue: Can't Access https://localhost.local

**1. Check hosts file:**

```powershell
notepad C:\Windows\System32\drivers\etc\hosts
```

Should contain:
```
127.0.0.1    localhost.local
```

If missing, add it (requires Administrator).

**2. Clear browser cache:**

- Chrome: Ctrl+Shift+Delete → Clear cached images and files
- Firefox: Ctrl+Shift+Delete → Cache
- Edge: Ctrl+Shift+Delete → Cached data

**3. Trust SSL certificate:**

Run SSL setup again:
```powershell
.\scripts\ssl-setup.ps1
```

Follow instructions to trust the certificate.

**4. Check Nginx is running:**

```powershell
docker-compose ps nginx
# Should show "Up"

# Test HTTP
curl http://localhost
```

**5. Try different URL:**

```
https://127.0.0.1
https://localhost
```

## Issue: Database Connection Error

**1. Verify MariaDB is running:**

```powershell
docker-compose ps mariadb
# Should show "Up"

# Check logs
.\scripts\logs.ps1 -Service mariadb
```

**2. Test database connection:**

```powershell
docker exec wordpress-docker_wordpress ping mariadb
# Should get replies
```

**3. Verify credentials:**

Check `.env` file has correct passwords.

**4. Restart MariaDB:**

```powershell
docker-compose restart mariadb
```

**5. Reset database (NUCLEAR OPTION - deletes all data):**

```powershell
docker-compose down -v
docker-compose up -d
# Reinstall WordPress
```

## Issue: 502 Bad Gateway

**Cause:** Nginx can't connect to PHP-FPM

**1. Check WordPress container:**

```powershell
docker-compose ps wordpress
# Should show "Up"
```

**2. Check PHP-FPM is responsive:**

```powershell
docker exec wordpress-docker_wordpress php-fpm-healthcheck
# Should exit with code 0
```

**3. Check logs:**

```powershell
.\scripts\logs.ps1 -Service wordpress
.\scripts\logs.ps1 -Service nginx
```

**4. Restart WordPress:**

```powershell
docker-compose restart wordpress nginx
```

## Issue: File Upload Fails

**1. Check current limits:**

```powershell
# Check PHP limits
docker exec wordpress-docker_wordpress php -i | findstr upload_max_filesize
docker exec wordpress-docker_wordpress php -i | findstr post_max_size
```

**2. Increase limits:**

Edit `php\php.ini`:
```ini
upload_max_filesize = 512M
post_max_size = 512M
```

Edit `nginx\nginx.conf`:
```nginx
client_max_body_size 512M;
```

**3. Restart:**

```powershell
docker-compose restart wordpress nginx
```

## Issue: Slow Performance

**1. Enable OPcache (should be on by default):**

```powershell
docker exec wordpress-docker_wordpress php -i | findstr opcache.enable
# Should show: opcache.enable => On => On
```

**2. Check available resources:**

```powershell
docker stats
# Shows CPU and memory usage
```

**3. Increase MariaDB buffer:**

Edit `mariadb\my.cnf`:
```ini
innodb_buffer_pool_size = 1G
```

Restart:
```powershell
docker-compose restart mariadb
```

**4. Check FastCGI cache:**

```powershell
curl -I https://localhost.local | findstr X-Cache-Status
# Should show: HIT (cached) or MISS (not cached)
```

**5. Install WordPress caching plugin:**
- WP Super Cache
- W3 Total Cache
- Redis Object Cache

## Issue: Permission Errors

**Fix WordPress file permissions:**

```powershell
docker exec wordpress-docker_wordpress chown -R www-data:www-data /var/www/html
docker exec wordpress-docker_wordpress find /var/www/html -type d -exec chmod 755 {} \;
docker exec wordpress-docker_wordpress find /var/www/html -type f -exec chmod 644 {} \;
```

## Issue: SSL Certificate Expired

**Generate new certificate:**

```powershell
# Delete old certificates
Remove-Item ssl\cert.pem, ssl\key.pem -Force

# Generate new ones
.\scripts\ssl-setup.ps1

# Restart Nginx
docker-compose restart nginx
```

## Issue: Out of Disk Space

**Check Docker disk usage:**

```powershell
docker system df
```

**Clean up:**

```powershell
# Remove stopped containers
docker container prune -f

# Remove unused images
docker image prune -a -f

# Remove unused volumes (⚠️ WARNING: May delete data!)
docker volume prune -f

# Remove build cache
docker builder prune -f

# NUCLEAR OPTION (removes everything not currently running):
docker system prune -a --volumes -f
```

## Issue: Container Keeps Restarting

**Check container logs:**

```powershell
docker logs wordpress-docker_mariadb
docker logs wordpress-docker_wordpress
docker logs wordpress-docker_nginx
```

**Common causes:**
- Out of memory
- Port already in use
- Configuration error
- Missing files

**Check health status:**

```powershell
docker inspect wordpress-docker_mariadb | findstr Health
docker inspect wordpress-docker_wordpress | findstr Health
docker inspect wordpress-docker_nginx | findstr Health
```

***

# Performance Optimization

## Nginx Optimizations (Already Included)

✅ **FastCGI caching** - Caches dynamic PHP content
✅ **Gzip compression** - Reduces bandwidth by 70%
✅ **HTTP/2** - Faster page loads
✅ **Keep-alive connections** - Reduces overhead
✅ **Static file caching** - 30-day browser cache
✅ **Worker auto-scaling** - Matches CPU cores

**Monitor cache performance:**

```powershell
# Check cache hits
curl -I https://localhost.local | findstr X-Cache-Status

# View cache size
docker exec wordpress-docker_nginx du -sh /var/cache/nginx
```

## PHP Optimizations (Already Included)

✅ **OPcache enabled** - 5x faster PHP execution
✅ **Realpath cache** - Reduces filesystem calls
✅ **Dynamic process manager** - Auto-scales workers
✅ **Memory limit: 512M** - Handles large operations

**Check OPcache status:**

```powershell
docker exec wordpress-docker_wordpress php -i | findstr opcache
```

**Monitor PHP-FPM status:**

```powershell
docker exec wordpress-docker_wordpress bash -c "SCRIPT_NAME=/status SCRIPT_FILENAME=/status REQUEST_METHOD=GET cgi-fcgi -bind -connect 127.0.0.1:9000"
```

## MariaDB Optimizations (Already Included)

✅ **InnoDB buffer pool: 512M** - Caches data in memory
✅ **Query cache disabled** - Not needed in MariaDB 11.6
✅ **Binary logging** - Enables point-in-time recovery
✅ **Connection pooling** - Reduces overhead

**Monitor slow queries:**

```powershell
docker exec wordpress-docker_mariadb tail -f /var/log/mysql/slow.log
```

**Optimize database:**

```powershell
docker exec wordpress-docker_mariadb mysqlcheck -u root -p"$env:MYSQL_ROOT_PASSWORD" --optimize --all-databases
```

## WordPress Optimizations

### 1. Install Caching Plugin

**Recommended plugins:**
- **WP Super Cache** - Simple and effective
- **W3 Total Cache** - Advanced features
- **LiteSpeed Cache** - Fast and comprehensive

**Install via WP-CLI:**

```powershell
docker exec wordpress-docker_wordpress wp plugin install wp-super-cache --activate --allow-root
```

### 2. Optimize Images

**Install image optimization plugin:**

```powershell
docker exec wordpress-docker_wordpress wp plugin install smush --activate --allow-root
```

Or use:
- ShortPixel Image Optimizer
- Imagify
- EWWW Image Optimizer

### 3. Use CDN (Production)

For production sites, use:
- Cloudflare (free)
- StackPath
- KeyCDN

### 4. Minimize Plugins

- Remove unused plugins
- Keep only essential plugins active
- Regularly update plugins

### 5. Optimize Database

**Install optimization plugin:**

```powershell
docker exec wordpress-docker_wordpress wp plugin install wp-optimize --activate --allow-root
```

**Or use WP-CLI:**

```powershell
# Optimize database
docker exec wordpress-docker_wordpress wp db optimize --allow-root

# Clean up revisions
docker exec wordpress-docker_wordpress wp post delete $(wp post list --post_type='revision' --format=ids --allow-root) --allow-root
```

### 6. Enable Object Caching (Redis)

**Add Redis container to `docker-compose.yml`:**

```yaml
  redis:
    image: redis:alpine
    container_name: ${COMPOSE_PROJECT_NAME}_redis
    restart: unless-stopped
    networks:
      - wordpress-network
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 30s
      timeout: 10s
      retries: 3
```

**Install Redis plugin:**

```powershell
docker exec wordpress-docker_wordpress wp plugin install redis-cache --activate --allow-root
docker exec wordpress-docker_wordpress wp redis enable --allow-root
```

***

# Additional Useful Commands

## Docker Management

```powershell
# View all containers
docker ps -a

# View all images
docker images

# View all volumes
docker volume ls

# View all networks
docker network ls

# Remove specific container
docker rm -f wordpress-docker_nginx

# Remove specific volume
docker volume rm wordpress-docker_wordpress_data

# Rebuild single service
docker-compose build --no-cache nginx

# View resource usage
docker stats

# Inspect container
docker inspect wordpress-docker_wordpress

# Copy files from container
docker cp wordpress-docker_wordpress:/var/www/html/wp-config.php C:\backup\

# Execute command in container
docker exec wordpress-docker_wordpress ls -la /var/www/html
```

## WordPress Management (WP-CLI)

```powershell
# Update WordPress core
docker exec wordpress-docker_wordpress wp core update --allow-root

# Update all plugins
docker exec wordpress-docker_wordpress wp plugin update --all --allow-root

# Update all themes
docker exec wordpress-docker_wordpress wp theme update --all --allow-root

# List plugins
docker exec wordpress-docker_wordpress wp plugin list --allow-root

# Install plugin
docker exec wordpress-docker_wordpress wp plugin install contact-form-7 --activate --allow-root

# Uninstall plugin
docker exec wordpress-docker_wordpress wp plugin uninstall akismet --allow-root

# Create user
docker exec wordpress-docker_wordpress wp user create editor editor@example.com --role=editor --allow-root

# Change password
docker exec wordpress-docker_wordpress wp user update 1 --user_pass=NewPassword123 --allow-root

# Search and replace in database
docker exec wordpress-docker_wordpress wp search-replace 'oldurl.com' 'newurl.com' --allow-root

# Export database
docker exec wordpress-docker_wordpress wp db export /tmp/backup.sql --allow-root
docker cp wordpress-docker_wordpress:/tmp/backup.sql C:\backup\

# Clear cache
docker exec wordpress-docker_wordpress wp cache flush --allow-root
```

## Database Management

```powershell
# Connect to database
docker exec -it wordpress-docker_mariadb mysql -u root -p

# Backup database
docker exec wordpress-docker_mariadb mysqldump -u root -p"$env:MYSQL_ROOT_PASSWORD" wordpress > backup.sql

# Restore database
Get-Content backup.sql | docker exec -i wordpress-docker_mariadb mysql -u root -p"$env:MYSQL_ROOT_PASSWORD" wordpress

# Check database size
docker exec wordpress-docker_mariadb mysql -u root -p"$env:MYSQL_ROOT_PASSWORD" -e "SELECT table_schema AS 'Database', ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS 'Size (MB)' FROM information_schema.TABLES GROUP BY table_schema;"

# Repair database
docker exec wordpress-docker_mariadb mysqlcheck -u root -p"$env:MYSQL_ROOT_PASSWORD" --auto-repair wordpress

# Optimize database
docker exec wordpress-docker_mariadb mysqlcheck -u root -p"$env:MYSQL_ROOT_PASSWORD" --optimize wordpress
```

***

# Security Best Practices

## For Development

✅ **Already Implemented:**
- SSL/TLS encryption
- Security headers
- Rate limiting
- Disabled dangerous PHP functions
- Secure session handling
- Hidden Nginx version
- MariaDB security

## For Production Deployment

Before moving to production, implement these additional security measures:

### 1. Change All Passwords

```powershell
# Edit .env file
notepad .env

# Change:
# - WORDPRESS_DB_PASSWORD
# - MYSQL_ROOT_PASSWORD
# - WORDPRESS_ADMIN_PASSWORD
```

### 2. Use Real SSL Certificates

Replace self-signed certificates with Let's Encrypt:

```powershell
# Install certbot
winget install Certbot.Certbot

# Generate certificate (on production server)
certbot certonly --webroot -w C:\wordpress-docker\wordpress -d yourdomain.com
```

### 3. WordPress Security Hardening

**Install security plugin:**

```powershell
docker exec wordpress-docker_wordpress wp plugin install wordfence --activate --allow-root
```

Or use:
- Sucuri Security
- iThemes Security
- All In One WP Security

**Disable file editing in WordPress admin:**

Edit `.env` and add:
```env
WORDPRESS_CONFIG_EXTRA=define('DISALLOW_FILE_EDIT', true);
```

### 4. Regular Updates

```powershell
# Update WordPress core
docker exec wordpress-docker_wordpress wp core update --allow-root

# Update plugins
docker exec wordpress-docker_wordpress wp plugin update --all --allow-root

# Update themes
docker exec wordpress-docker_wordpress wp theme update --all --allow-root
```

### 5. Limit Login Attempts

Install plugin:
```powershell
docker exec wordpress-docker_wordpress wp plugin install limit-login-attempts-reloaded --activate --allow-root
```

### 6. Enable Two-Factor Authentication

Install plugin:
```powershell
docker exec wordpress-docker_wordpress wp plugin install two-factor --activate --allow-root
```

### 7. Regular Backups

Set up automated daily backups (see Task Scheduler section).

### 8. Monitor Security

- Check logs regularly
- Monitor failed login attempts
- Use security scanning tools
- Keep WordPress and plugins updated

***

# Maintenance Schedule

## Daily

✅ Check container status
```powershell
docker-compose ps
```

## Weekly

✅ Update WordPress plugins and themes
```powershell
docker exec wordpress-docker_wordpress wp plugin update --all --allow-root
docker exec wordpress-docker_wordpress wp theme update --all --allow-root
```

✅ Check disk space
```powershell
docker system df
```

## Monthly

✅ Update WordPress core
```powershell
docker exec wordpress-docker_wordpress wp core update --allow-root
```

✅ Optimize database
```powershell
docker exec wordpress-docker_mariadb mysqlcheck -u root -p"$env:MYSQL_ROOT_PASSWORD" --optimize --all-databases
```

✅ Clean up old backups
```powershell
# Backups older than 30 days are automatically deleted
# by backup.ps1 script
```

✅ Review security logs

✅ Test backup restoration

## Quarterly

✅ Update Docker images
```powershell
docker-compose pull
docker-compose up -d --force-recreate
```

✅ Review and update security settings

✅ Audit installed plugins (remove unused)

✅ Performance testing and optimization

***

# Quick Reference Card

## Essential Commands

| Action | Command |
|--------|---------|
| **Start all services** | `.\scripts\start.ps1` |
| **Stop all services** | `.\scripts\stop.ps1` |
| **View logs** | `.\scripts\logs.ps1` |
| **Create backup** | `.\scripts\backup.ps1` |
| **Restore backup** | `.\scripts\restore.ps1 -BackupName [name]` |
| **Restart service** | `docker-compose restart [service]` |
| **Rebuild container** | `docker-compose build --no-cache [service]` |
| **View container status** | `docker-compose ps` |
| **Access container shell** | `docker exec -it wordpress-docker_[service] bash` |

## Access URLs

| Service | URL | Credentials |
|---------|-----|-------------|
| **WordPress Site** | https://localhost.local | - |
| **WordPress Admin** | https://localhost.local/wp-admin | From .env file |
| **phpMyAdmin** | http://localhost:8080 | root / MYSQL_ROOT_PASSWORD |

## File Locations

| Type | Location |
|------|----------|
| **Nginx configs** | `C:\wordpress-docker\nginx\` |
| **PHP configs** | `C:\wordpress-docker\php\` |
| **MariaDB configs** | `C:\wordpress-docker\mariadb\` |
| **Logs** | `C:\wordpress-docker\logs\` |
| **Backups** | `C:\wordpress-docker\backups\` |
| **SSL certificates** | `C:\wordpress-docker\ssl\` |
| **Scripts** | `C:\wordpress-docker\scripts\` |

***

# Additional Files

## .gitignore

**Location:** `C:\wordpress-docker\.gitignore`

```gitignore
###############################################################################
# Git Ignore File - Prevents sensitive files from being committed
###############################################################################

# Environment file (contains passwords!)
.env

# SSL Certificates
ssl/*.pem
ssl/*.key
ssl/*.crt

# Backups (large files)
backups/
*.zip
*.tar.gz
*.sql

# Logs
logs/
*.log

# OS-specific files
.DS_Store
Thumbs.db
desktop.ini
$RECYCLE.BIN/

# IDE files
.vscode/
.idea/
*.swp
*.swo
*~

# Temporary files
tmp/
temp/
*.tmp

# Docker volumes data
mysql-data/
mariadb-data/
```

## README.md

**Location:** `C:\wordpress-docker\README.md`

```markdown
# WordPress Docker Development Environment

Complete Docker-based WordPress setup for Windows 11 with Nginx, PHP 8.3, MariaDB 11.6, and SSL.

## Features

- ✅ Latest technology stack
- ✅ SSL/TLS encryption
- ✅ Performance optimized
- ✅ Security hardened
- ✅ Windows-compatible PowerShell scripts
- ✅ Easy configuration management
- ✅ Automated backups
- ✅ phpMyAdmin included

## Quick Start

1. **Prerequisites:**
   - Docker Desktop for Windows 11
   - Git for Windows

2. **Configure:**
   ```
   # Edit .env file and change all passwords
   notepad .env
   ```

3. **Setup:**
   ```
   # Run complete setup (as Administrator)
   .\scripts\setup.ps1
   ```

4. **Access:**
   - WordPress: https://localhost.local
   - Admin: https://localhost.local/wp-admin
   - phpMyAdmin: http://localhost:8080

## Daily Usage

```
# Start
.\scripts\start.ps1

# Stop
.\scripts\stop.ps1

# Backup
.\scripts\backup.ps1

# View logs
.\scripts\logs.ps1
```

## Documentation

See complete documentation in the main setup guide.

## Support

For issues, check the troubleshooting section in the main guide.

## License

Free to use for development purposes.
```

***

# Final Checklist

## Before First Run

- [ ] Docker Desktop installed and running
- [ ] Git for Windows installed
- [ ] All configuration files created
- [ ] .env file configured with strong passwords
- [ ] SSL certificates generated and trusted
- [ ] localhost.local added to Windows hosts file

## After First Run

- [ ] All containers showing "Up" status
- [ ] Can access https://localhost.local
- [ ] Can access http://localhost:8080 (phpMyAdmin)
- [ ] WordPress installation completed
- [ ] Can login to WordPress admin
- [ ] Backup script tested
- [ ] Restore script tested

## Production Readiness

- [ ] All default passwords changed
- [ ] Admin username changed (not 'admin')
- [ ] Real SSL certificates installed
- [ ] Security plugins installed
- [ ] Automated backups configured
- [ ] WordPress and plugins updated
- [ ] Unnecessary plugins removed
- [ ] Performance tested
- [ ] Security audit completed

---

# Congratulations! 🎉

You now have a **complete, production-ready WordPress development environment** on Windows 11!

## What You've Built

✅ **Modern Stack:**
- Nginx (Ubuntu) - High-performance web server
- PHP 8.3-FPM (Alpine) - Latest PHP with OPcache
- MariaDB 11.6 - Latest stable database
- WordPress (Latest) - World's most popular CMS

✅ **Security:**
- SSL/TLS encryption
- Security headers
- Rate limiting
- Hardened configurations
- Secure by default

✅ **Performance:**
- FastCGI caching
- Gzip compression
- OPcache enabled
- Optimized database
- Static file caching

✅ **Developer Friendly:**
- All configs editable via Windows File Manager
- PowerShell automation scripts
- Easy backup and restore
- Comprehensive logging
- Container health monitoring

## Next Steps

1. **Complete WordPress setup** at https://localhost.local
2. **Install your favorite theme** and plugins
3. **Configure automated backups** (Task Scheduler)
4. **Start building** your amazing website!

## Need Help?

- Check the **Troubleshooting** section
- View **logs** with `.\scripts\logs.ps1`
- Inspect **container status** with `docker-compose ps`
- Review **configuration files** in respective folders

## Useful Resources

- [WordPress Documentation](https://wordpress.org/documentation/)
- [Docker Documentation](https://docs.docker.com/)
- [Nginx Documentation](https://nginx.org/en/docs/)
- [PHP Documentation](https://www.php.net/docs.php)
- [MariaDB Documentation](https://mariadb.com/kb/en/)

***

**Happy developing!** 🚀

Your WordPress Docker environment is ready to use. All files are accessible via Windows File Manager, all scripts work with PowerShell, and everything is optimized for the best development experience on Windows 11.

**Note:** This setup is production-ready but designed for development. Before deploying to production servers, review the security checklist and implement additional hardening measures as needed.

***

**Setup Complete!** ✨