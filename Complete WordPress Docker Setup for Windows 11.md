<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" style="height:64px;margin-right:32px"/>

# Complete WordPress Docker Setup for Windows 11

**Production-Ready with Latest Versions (Nginx, PHP 8.3, MariaDB 11.6)**

***

## 📋 Table of Contents

1. [Overview \& Features](#overview--features)
2. [Complete File Structure](#complete-file-structure)
3. [Installation Prerequisites](#installation-prerequisites)
4. [Step-by-Step Setup](#step-by-step-setup)
5. [All Configuration Files](#all-configuration-files)
6. [SSL Certificate Generation](#ssl-certificate-generation)
7. [Backup \& Restore Scripts](#backup--restore-scripts)
8. [Usage Guide](#usage-guide)
9. [Troubleshooting](#troubleshooting)
10. [Security Checklist](#security-checklist)

***

## Overview \& Features

### ✨ What You Get

- **Latest Stack**: Nginx Alpine, PHP 8.3-FPM, MariaDB 11.6, WordPress Latest
- **SSL/HTTPS**: Self-signed certificates for local development
- **Performance**: OPcache, FastCGI cache, Gzip, optimized MariaDB
- **Security**: Rate limiting, security headers, blocked sensitive files
- **Developer Tools**: phpMyAdmin, detailed logging, health checks
- **Easy Management**: All configs editable, automated backups, Windows-friendly


### 🔧 All Fixes Applied

✅ ImageMagick built from source (PECL broken)
✅ Health check using built-in cgi-fcgi
✅ MariaDB 11.6+ environment variables (MARIADB_*)
✅ Windows file access via Docker Desktop
✅ Latest compatible versions of all components

***

## Complete File Structure

```
wordpress-docker/
│
├── docker-compose.yml          # Main orchestration file
├── .env                        # Environment variables (EDIT PASSWORDS HERE!)
├── .gitignore                  # Git ignore file
├── README.md                   # Documentation
│
├── nginx/                      # Nginx web server
│   ├── Dockerfile
│   ├── nginx.conf              # Main Nginx config
│   └── conf.d/
│       └── default.conf        # WordPress site config
│
├── php/                        # PHP-FPM
│   ├── Dockerfile
│   ├── php.ini                 # PHP settings (upload limits, memory, etc.)
│   └── php-fpm.conf            # PHP-FPM process manager
│
├── mariadb/                    # MariaDB database
│   ├── my.cnf                  # MariaDB optimization
│   └── init/
│       └── init.sql            # Initial database setup
│
├── ssl/                        # SSL certificates (auto-generated)
│   ├── cert.pem                # Certificate (generated)
│   ├── key.pem                 # Private key (generated)
│   └── generate-ssl.sh         # Linux/Git Bash script
│
├── scripts/                    # Utility scripts
│   ├── setup-ssl-windows.ps1   # SSL generator for Windows
│   ├── backup.sh               # Backup script
│   └── restore.sh              # Restore script
│
├── backups/                    # Backup storage (auto-created)
│   └── (backup files here)
│
└── logs/                       # All logs (auto-created)
    ├── nginx/                  # Nginx access & error logs
    ├── php/                    # PHP-FPM logs
    └── mariadb/                # MariaDB logs
```


***

## Installation Prerequisites

### Required Software

**1. Docker Desktop for Windows 11**

```powershell
# Download from: https://www.docker.com/products/docker-desktop
# Or install via winget:
winget install Docker.DockerDesktop
```

- Enable WSL 2 during installation
- Allocate at least 4GB RAM (Settings → Resources)
- Restart after installation

**2. Git for Windows**

```powershell
# Download from: https://git-scm.com/download/win
# Or install via winget:
winget install Git.Git
```

- Includes Git Bash for scripts
- Includes OpenSSL for certificates

**3. Text Editor (Optional)**

```powershell
# VS Code (recommended):
winget install Microsoft.VisualStudioCode

# Or Notepad++:
winget install Notepad++.Notepad++
```


***

## Step-by-Step Setup

### Step 1: Create Project Directory

```powershell
# Open PowerShell
cd C:\

# Create project folder
mkdir wordpress-docker
cd wordpress-docker

# Create all subdirectories
mkdir nginx, nginx\conf.d, php, mariadb, mariadb\init, ssl, backups, scripts, logs, logs\nginx, logs\php, logs\mariadb
```


### Step 2: Create All Files

Create each file below in its respective directory. Copy the complete content for each file.

***

## All Configuration Files

### 1. Environment Variables (.env)

**Location:** `C:\wordpress-docker\.env`

```env
###############################################################################
# WordPress Docker Environment Configuration
# ⚠️ CHANGE ALL PASSWORDS BEFORE FIRST RUN!
###############################################################################

# Project Name (used as container prefix)
COMPOSE_PROJECT_NAME=wordpress-docker

###############################################################################
# WORDPRESS DATABASE CONFIGURATION
###############################################################################
WORDPRESS_DB_NAME=wordpress
WORDPRESS_DB_USER=wpuser
WORDPRESS_DB_PASSWORD=ChangeThisPassword123!
WORDPRESS_TABLE_PREFIX=wp_

###############################################################################
# WORDPRESS ADMIN USER (for installation)
###############################################################################
WORDPRESS_ADMIN_USER=admin
WORDPRESS_ADMIN_PASSWORD=ChangeAdminPassword123!
WORDPRESS_ADMIN_EMAIL=admin@localhost.local

###############################################################################
# MARIADB ROOT PASSWORD
###############################################################################
MYSQL_ROOT_PASSWORD=ChangeRootPassword123!

###############################################################################
# VERSIONS (Latest stable versions)
###############################################################################
MARIADB_VERSION=11.6
PHP_VERSION=8.3

###############################################################################
# DOMAIN AND SSL
###############################################################################
DOMAIN_NAME=localhost.local
SSL_COUNTRY=US
SSL_STATE=State
SSL_CITY=City
SSL_ORG=Organization
SSL_ORG_UNIT=IT

###############################################################################
# PORTS
###############################################################################
NGINX_HTTP_PORT=80
NGINX_HTTPS_PORT=443
PHPMYADMIN_PORT=8080

###############################################################################
# TIMEZONE
###############################################################################
TIMEZONE=UTC

###############################################################################
# PHP PERFORMANCE SETTINGS
###############################################################################
PHP_MEMORY_LIMIT=512M
PHP_MAX_EXECUTION_TIME=300
PHP_MAX_INPUT_TIME=300
PHP_UPLOAD_MAX_FILESIZE=256M
PHP_POST_MAX_SIZE=256M

###############################################################################
# BACKUP SETTINGS
###############################################################################
BACKUP_RETENTION_DAYS=30
```

**⚠️ SECURITY: Change these before starting:**

- `WORDPRESS_DB_PASSWORD`
- `WORDPRESS_ADMIN_USER` (don't use "admin")
- `WORDPRESS_ADMIN_PASSWORD`
- `WORDPRESS_ADMIN_EMAIL`
- `MYSQL_ROOT_PASSWORD`

***

### 2. Docker Compose (docker-compose.yml)

**Location:** `C:\wordpress-docker\docker-compose.yml`

```yaml
###############################################################################
# WordPress Docker Compose Configuration
# Latest versions: Nginx, PHP 8.3, MariaDB 11.6, WordPress
###############################################################################

version: '3.8'

services:

  ###############################################################################
  # MariaDB 11.6 Database Service
  ###############################################################################
  mariadb:
    image: mariadb:${MARIADB_VERSION:-11.6}
    container_name: ${COMPOSE_PROJECT_NAME}_mariadb
    restart: unless-stopped
    
    environment:
      # MariaDB 11.x requires MARIADB_* prefix
      MARIADB_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
      MARIADB_DATABASE: ${WORDPRESS_DB_NAME}
      MARIADB_USER: ${WORDPRESS_DB_USER}
      MARIADB_PASSWORD: ${WORDPRESS_DB_PASSWORD}
      TZ: ${TIMEZONE}
    
    volumes:
      # Persistent database storage
      - mariadb_data:/var/lib/mysql
      # Custom configuration
      - ./mariadb/my.cnf:/etc/mysql/conf.d/custom.cnf:ro
      # Initialization scripts
      - ./mariadb/init:/docker-entrypoint-initdb.d:ro
      # Logs
      - ./logs/mariadb:/var/log/mysql
    
    networks:
      - wordpress-network
    
    # Performance optimizations via command line
    command: >
      --character-set-server=utf8mb4
      --collation-server=utf8mb4_unicode_ci
      --max_allowed_packet=256M
      --innodb_buffer_pool_size=512M
      --innodb_log_file_size=128M
    
    # Health check ensures DB is ready before WordPress starts
    healthcheck:
      test: ["CMD", "healthcheck.sh", "--connect", "--innodb_initialized"]
      interval: 30s
      timeout: 10s
      retries: 5
      start_period: 40s

  ###############################################################################
  # WordPress with PHP 8.3-FPM Service
  ###############################################################################
  wordpress:
    build:
      context: ./php
      args:
        PHP_VERSION: ${PHP_VERSION:-8.3}
    
    container_name: ${COMPOSE_PROJECT_NAME}_wordpress
    restart: unless-stopped
    
    # Wait for healthy database before starting
    depends_on:
      mariadb:
        condition: service_healthy
    
    environment:
      # WordPress database connection
      WORDPRESS_DB_HOST: mariadb:3306
      WORDPRESS_DB_NAME: ${WORDPRESS_DB_NAME}
      WORDPRESS_DB_USER: ${WORDPRESS_DB_USER}
      WORDPRESS_DB_PASSWORD: ${WORDPRESS_DB_PASSWORD}
      WORDPRESS_TABLE_PREFIX: ${WORDPRESS_TABLE_PREFIX}
      WORDPRESS_DEBUG: 0
      TZ: ${TIMEZONE}
    
    volumes:
      # WordPress files (wp-content, themes, plugins, uploads)
      - wordpress_data:/var/www/html
      # Custom PHP configuration
      - ./php/php.ini:/usr/local/etc/php/conf.d/custom.ini:ro
      # PHP-FPM process manager config
      - ./php/php-fpm.conf:/usr/local/etc/php-fpm.d/zz-custom.conf:ro
      # PHP logs
      - ./logs/php:/var/log/php
    
    networks:
      - wordpress-network
    
    # Health check using custom script
    healthcheck:
      test: ["CMD-SHELL", "php-fpm-healthcheck"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

  ###############################################################################
  # Nginx Web Server Service
  ###############################################################################
  nginx:
    build:
      context: ./nginx
    
    container_name: ${COMPOSE_PROJECT_NAME}_nginx
    restart: unless-stopped
    
    depends_on:
      - wordpress
    
    # Expose HTTP and HTTPS to host
    ports:
      - "${NGINX_HTTP_PORT:-80}:80"
      - "${NGINX_HTTPS_PORT:-443}:443"
    
    environment:
      DOMAIN_NAME: ${DOMAIN_NAME}
      TZ: ${TIMEZONE}
    
    volumes:
      # WordPress files (read-only)
      - wordpress_data:/var/www/html:ro
      # Nginx configurations
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./nginx/conf.d:/etc/nginx/conf.d:ro
      # SSL certificates
      - ./ssl:/etc/nginx/ssl:ro
      # Nginx logs
      - ./logs/nginx:/var/log/nginx
    
    networks:
      - wordpress-network
    
    # Health check validates Nginx config
    healthcheck:
      test: ["CMD", "nginx", "-t"]
      interval: 30s
      timeout: 10s
      retries: 3

  ###############################################################################
  # phpMyAdmin Database Management Interface
  ###############################################################################
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

###############################################################################
# Networks
###############################################################################
networks:
  wordpress-network:
    driver: bridge

###############################################################################
# Volumes (Persistent Data Storage)
###############################################################################
volumes:
  mariadb_data:
    driver: local
  wordpress_data:
    driver: local
```


***

### 3. Nginx Configuration Files

#### nginx/Dockerfile

**Location:** `C:\wordpress-docker\nginx\Dockerfile`

```dockerfile
FROM nginx:alpine

# Install OpenSSL for SSL certificate generation
RUN apk add --no-cache openssl

# Create directories
RUN mkdir -p /var/log/nginx /var/cache/nginx

# Copy configurations
COPY nginx.conf /etc/nginx/nginx.conf
COPY conf.d/ /etc/nginx/conf.d/

EXPOSE 80 443

CMD ["nginx", "-g", "daemon off;"]
```


#### nginx/nginx.conf

**Location:** `C:\wordpress-docker\nginx\nginx.conf`

```nginx
###############################################################################
# Main Nginx Configuration - Optimized for WordPress
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

    # Logging format
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';
    access_log /var/log/nginx/access.log main;

    # Performance optimizations
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
    
    # Buffers
    client_header_buffer_size 1k;
    large_client_header_buffers 4 8k;
    
    # Gzip compression
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

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "0" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    server_tokens off;
    
    # Rate limiting (anti-brute force)
    limit_req_zone $binary_remote_addr zone=wp_login:10m rate=2r/s;
    limit_req_zone $binary_remote_addr zone=wp_admin:10m rate=10r/s;
    limit_conn_zone $binary_remote_addr zone=addr:10m;

    # FastCGI cache
    fastcgi_cache_path /var/cache/nginx levels=1:2 keys_zone=WORDPRESS:100m 
                       inactive=60m max_size=512m;
    fastcgi_cache_key "$scheme$request_method$host$request_uri";
    fastcgi_cache_use_stale error timeout invalid_header http_500 http_503;
    fastcgi_cache_valid 200 301 302 60m;
    fastcgi_cache_valid 404 10m;
    fastcgi_ignore_headers Cache-Control Expires Set-Cookie;

    # Include site configurations
    include /etc/nginx/conf.d/*.conf;
}
```


#### nginx/conf.d/default.conf

**Location:** `C:\wordpress-docker\nginx\conf.d\default.conf`

```nginx
###############################################################################
# WordPress Site Configuration
###############################################################################

upstream php-fpm {
    server wordpress:9000;
    keepalive 32;
}

# HTTP → HTTPS Redirect
server {
    listen 80;
    listen [::]:80;
    server_name localhost localhost.local;
    
    # Allow ACME challenge for Let's Encrypt
    location ^~ /.well-known/acme-challenge/ {
        allow all;
        root /var/www/html;
    }
    
    # Redirect everything else to HTTPS
    location / {
        return 301 https://$host$request_uri;
    }
}

# HTTPS Server
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name localhost localhost.local;

    root /var/www/html;
    index index.php index.html;

    # SSL Configuration
    ssl_certificate /etc/nginx/ssl/cert.pem;
    ssl_certificate_key /etc/nginx/ssl/key.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384';
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    ssl_session_tickets off;

    # Security headers
    add_header Content-Security-Policy "default-src 'self' https: data: 'unsafe-inline' 'unsafe-eval';" always;
    add_header Permissions-Policy "geolocation=(), microphone=(), camera=()" always;

    # Logging
    access_log /var/log/nginx/wordpress-access.log;
    error_log /var/log/nginx/wordpress-error.log;

    # Connection limit
    limit_conn addr 10;

    # WordPress permalinks
    location / {
        try_files $uri $uri/ /index.php?$args;
    }

    # Block hidden files
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }

    # Block XML-RPC (prevents DDoS attacks)
    location = /xmlrpc.php {
        deny all;
        access_log off;
        log_not_found off;
    }

    # Block sensitive files
    location = /readme.html { deny all; }
    location = /license.txt { deny all; }
    location ~* wp-config.php { deny all; }

    # Rate limit login page
    location = /wp-login.php {
        limit_req zone=wp_login burst=5 nodelay;
        include fastcgi_params;
        fastcgi_pass php-fpm;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_index index.php;
    }

    # Rate limit admin area
    location ^~ /wp-admin/ {
        limit_req zone=wp_admin burst=20 nodelay;
        location ~ \.php$ {
            include fastcgi_params;
            fastcgi_pass php-fpm;
            fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
            fastcgi_index index.php;
        }
    }

    # PHP processing with caching
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

    # Static file caching
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg|woff|woff2|ttf|eot)$ {
        expires 30d;
        add_header Cache-Control "public, immutable";
        access_log off;
    }

    # Deny PHP in uploads
    location ~* /(?:uploads|files)/.*\.php$ {
        deny all;
    }

    # Deny hidden files (except .well-known)
    location ~ /\.(?!well-known) {
        deny all;
    }
}
```


***

### 4. PHP Configuration Files

#### php/Dockerfile

**Location:** `C:\wordpress-docker\php\Dockerfile`

```dockerfile
###############################################################################
# PHP 8.3-FPM Dockerfile with ImageMagick (Built from Source)
###############################################################################

ARG PHP_VERSION=8.3
FROM wordpress:php${PHP_VERSION}-fpm-alpine

# Install system dependencies
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

# Install core PHP extensions
RUN docker-php-ext-install opcache zip exif

# Install Redis extension (for object caching)
RUN apk add --no-cache --virtual .build-deps $PHPIZE_DEPS \
    && pecl install redis \
    && docker-php-ext-enable redis \
    && apk del .build-deps

# Build ImageMagick extension from source
# PECL version is broken for PHP 8.2+
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

# Create health check script using cgi-fcgi
RUN echo '#!/bin/sh' > /usr/local/bin/php-fpm-healthcheck && \
    echo 'SCRIPT_NAME=/ping SCRIPT_FILENAME=/ping REQUEST_METHOD=GET cgi-fcgi -bind -connect 127.0.0.1:9000 || exit 1' >> /usr/local/bin/php-fpm-healthcheck && \
    chmod +x /usr/local/bin/php-fpm-healthcheck

# Create log directory
RUN mkdir -p /var/log/php && chown www-data:www-data /var/log/php

# Copy custom configurations
COPY php.ini /usr/local/etc/php/conf.d/custom.ini
COPY php-fpm.conf /usr/local/etc/php-fpm.d/zz-custom.conf

WORKDIR /var/www/html

EXPOSE 9000

CMD ["php-fpm"]
```


#### php/php.ini

**Location:** `C:\wordpress-docker\php\php.ini`

```ini
###############################################################################
# Custom PHP Configuration - Optimized for WordPress
###############################################################################

# Performance Settings
max_execution_time = 300
max_input_time = 300
memory_limit = 512M
post_max_size = 256M
upload_max_filesize = 256M
max_input_vars = 3000

# Error Reporting (Production - errors logged, not displayed)
display_errors = Off
display_startup_errors = Off
log_errors = On
error_log = /var/log/php/error.log
error_reporting = E_ALL & ~E_DEPRECATED & ~E_STRICT

# Session Settings
session.save_handler = files
session.save_path = "/tmp"
session.gc_maxlifetime = 3600
session.cookie_httponly = 1
session.cookie_secure = 1
session.use_strict_mode = 1

# Security Settings
expose_php = Off
allow_url_fopen = On
allow_url_include = Off
disable_functions = exec,passthru,shell_exec,system,proc_open,popen,curl_exec,curl_multi_exec,parse_ini_file,show_source

# OPcache Configuration (Huge Performance Boost)
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

# Realpath Cache
realpath_cache_size = 4096K
realpath_cache_ttl = 600

# File Uploads
file_uploads = On
max_file_uploads = 20

# Timezone
date.timezone = UTC

# MySQL
mysqli.default_socket = /var/run/mysqld/mysqld.sock
```


#### php/php-fpm.conf

**Location:** `C:\wordpress-docker\php\php-fpm.conf`

```ini
###############################################################################
# PHP-FPM Process Manager Configuration
###############################################################################

[www]

# Process manager (dynamic = auto-adjusts workers)
pm = dynamic
pm.max_children = 50
pm.start_servers = 10
pm.min_spare_servers = 5
pm.max_spare_servers = 20
pm.max_requests = 500
pm.process_idle_timeout = 10s

# Performance
request_terminate_timeout = 300s
request_slowlog_timeout = 10s
slowlog = /var/log/php/slow.log

# Error logging
catch_workers_output = yes
php_flag[display_errors] = off
php_admin_value[error_log] = /var/log/php/fpm-error.log
php_admin_flag[log_errors] = on

# Security
security.limit_extensions = .php

# Status and ping pages (for health checks)
pm.status_path = /status
ping.path = /ping
ping.response = pong

# Environment variables
clear_env = no
```


***

### 5. MariaDB Configuration Files

#### mariadb/my.cnf

**Location:** `C:\wordpress-docker\mariadb\my.cnf`

```ini
###############################################################################
# MariaDB 11.6 Configuration - Optimized for WordPress
###############################################################################

[mysqld]
# Basic settings
user = mysql
pid-file = /var/run/mysqld/mysqld.pid
socket = /var/run/mysqld/mysqld.sock
port = 3306
basedir = /usr
datadir = /var/lib/mysql
tmpdir = /tmp

# Character set (UTF8MB4 supports emoji)
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci
init_connect = 'SET NAMES utf8mb4'

# Networking
skip-external-locking
bind-address = 0.0.0.0
max_connections = 200
max_allowed_packet = 256M
connect_timeout = 10
wait_timeout = 600
interactive_timeout = 600

# Query cache (disabled in MariaDB 10.3+)
query_cache_type = 0
query_cache_size = 0

# Logging
general_log = 0
slow_query_log = 1
slow_query_log_file = /var/log/mysql/slow.log
long_query_time = 2
log_error = /var/log/mysql/error.log

# InnoDB optimization (most important for WordPress)
innodb_buffer_pool_size = 512M
innodb_log_file_size = 128M
innodb_log_buffer_size = 16M
innodb_flush_log_at_trx_commit = 2
innodb_file_per_table = 1
innodb_flush_method = O_DIRECT

# Performance schema
performance_schema = ON

# Binary logging (for backups)
log_bin = /var/log/mysql/mariadb-bin
log_bin_index = /var/log/mysql/mariadb-bin.index
expire_logs_days = 7
max_binlog_size = 100M

# Table and index settings
table_open_cache = 4096
table_definition_cache = 2048
open_files_limit = 65535

# Thread settings
thread_cache_size = 50
thread_stack = 256K

# MyISAM settings
key_buffer_size = 128M
myisam_sort_buffer_size = 128M

# Security
local_infile = 0

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


#### mariadb/init/init.sql

**Location:** `C:\wordpress-docker\mariadb\init\init.sql`

```sql
-- MariaDB Initialization Script
-- Runs automatically on first container startup

-- Optimize system tables
OPTIMIZE TABLE mysql.user;
OPTIMIZE TABLE mysql.db;

-- Flush privileges
FLUSH PRIVILEGES;

-- Display databases (for log verification)
SHOW DATABASES;
```


***

## SSL Certificate Generation

### scripts/setup-ssl-windows.ps1

**Location:** `C:\wordpress-docker\scripts\setup-ssl-windows.ps1`

```powershell
###############################################################################
# SSL Certificate Generator for Windows 11
# Run as Administrator in PowerShell
###############################################################################

$ErrorActionPreference = "Stop"

Write-Host "=============================================" -ForegroundColor Green
Write-Host " WordPress Docker SSL Certificate Generator" -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Green
Write-Host ""

# Check for admin privileges
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "ERROR: Run as Administrator!" -ForegroundColor Red
    exit 1
}

# Locate OpenSSL
$opensslPaths = @(
    "C:\Program Files\Git\usr\bin\openssl.exe",
    "C:\Program Files\OpenSSL-Win64\bin\openssl.exe",
    "openssl"
)

$opensslPath = $null
foreach ($path in $opensslPaths) {
    if ($path -eq "openssl") {
        $opensslInPath = Get-Command openssl -ErrorAction SilentlyContinue
        if ($opensslInPath) {
            $opensslPath = "openssl"
            break
        }
    } elseif (Test-Path $path) {
        $opensslPath = $path
        break
    }
}

# Install OpenSSL if not found
if (-not $opensslPath) {
    Write-Host "Installing OpenSSL via Chocolatey..." -ForegroundColor Yellow
    
    if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
        Write-Host "Installing Chocolatey..." -ForegroundColor Yellow
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    }
    
    choco install openssl -y
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    $opensslPath = "C:\Program Files\OpenSSL-Win64\bin\openssl.exe"
}

Write-Host "✓ OpenSSL found: $opensslPath" -ForegroundColor Green

# Create SSL directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$sslDir = Join-Path (Split-Path -Parent $scriptDir) "ssl"
if (-not (Test-Path $sslDir)) {
    New-Item -ItemType Directory -Path $sslDir -Force | Out-Null
}
Set-Location $sslDir

# Generate certificate
Write-Host "`nGenerating SSL certificate..." -ForegroundColor Cyan

$domain = "localhost.local"
$certCmd = "req -x509 -nodes -days 365 -newkey rsa:2048 -keyout key.pem -out cert.pem -subj '/C=US/ST=State/L=City/O=Organization/OU=IT/CN=$domain' -addext 'subjectAltName=DNS:localhost,DNS:$domain,DNS:*.$domain,IP:127.0.0.1'"

$process = Start-Process -FilePath $opensslPath -ArgumentList $certCmd.Split(' ') -Wait -PassThru -NoNewWindow

if ($process.ExitCode -eq 0) {
    Write-Host "✓ Certificate generated!" -ForegroundColor Green
    Write-Host "  Certificate: $sslDir\cert.pem"
    Write-Host "  Private Key: $sslDir\key.pem"
} else {
    Write-Host "ERROR: Certificate generation failed!" -ForegroundColor Red
    exit 1
}

# Add to hosts file
Write-Host "`nAdding localhost.local to hosts file..." -ForegroundColor Cyan
$hostsPath = "C:\Windows\System32\drivers\etc\hosts"
$hostsEntry = "127.0.0.1`tlocalhost.local"

Copy-Item $hostsPath "$hostsPath.backup" -Force

$hostsContent = Get-Content $hostsPath
$entryExists = $hostsContent | Where-Object { $_ -match "127\.0\.0\.1\s+localhost\.local" }

if (-not $entryExists) {
    Add-Content -Path $hostsPath -Value "`n$hostsEntry"
    Write-Host "✓ Added localhost.local to hosts" -ForegroundColor Green
} else {
    Write-Host "✓ localhost.local already in hosts" -ForegroundColor Green
}

# Instructions
Write-Host ""
Write-Host "=============================================" -ForegroundColor Green
Write-Host " NEXT STEPS" -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Green
Write-Host ""
Write-Host "1. Trust the Certificate:" -ForegroundColor Yellow
Write-Host "   - Navigate to: $sslDir"
Write-Host "   - Double-click cert.pem"
Write-Host "   - Click 'Install Certificate'"
Write-Host "   - Select 'Local Machine'"
Write-Host "   - Place in 'Trusted Root Certification Authorities'"
Write-Host ""
Write-Host "2. Start Docker:" -ForegroundColor Yellow
Write-Host "   docker-compose up -d"
Write-Host ""
Write-Host "3. Access Site:" -ForegroundColor Yellow
Write-Host "   https://localhost.local"
Write-Host ""
Write-Host "✓ Setup complete!" -ForegroundColor Green
```


***

## Backup \& Restore Scripts

### scripts/backup.sh

**Location:** `C:\wordpress-docker\scripts\backup.sh`

```bash
#!/bin/bash
###############################################################################
# WordPress Docker Backup Script
# Backs up: Database, WordPress files, Configuration files
###############################################################################

set -e
cd "$(dirname "$0")"

# Load environment variables
if [ -f ../.env ]; then
    export $(cat ../.env | grep -v '^#' | xargs)
else
    echo "ERROR: .env file not found!"
    exit 1
fi

# Configuration
BACKUP_DIR="../backups"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="wordpress_backup_${DATE}"
CONTAINER_PREFIX="${COMPOSE_PROJECT_NAME:-wordpress-docker}"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${GREEN}======================================"
echo -e " WordPress Docker Backup"
echo -e "======================================${NC}"
echo -e "${CYAN}Backup: ${BACKUP_NAME}${NC}"
echo ""

mkdir -p "$BACKUP_DIR/$BACKUP_NAME"

# Backup database
echo -e "${YELLOW}[1/3] Backing up database...${NC}"
docker exec "${CONTAINER_PREFIX}_mariadb" mysqldump \
    -u root \
    -p"${MYSQL_ROOT_PASSWORD}" \
    --single-transaction \
    --quick \
    --lock-tables=false \
    --routines \
    --triggers \
    --events \
    "${WORDPRESS_DB_NAME}" > "$BACKUP_DIR/$BACKUP_NAME/database.sql"

if [ $? -eq 0 ]; then
    DB_SIZE=$(du -h "$BACKUP_DIR/$BACKUP_NAME/database.sql" | cut -f1)
    echo -e "${GREEN}✓ Database backed up ($DB_SIZE)${NC}"
else
    echo -e "${RED}✗ Database backup failed!${NC}"
    exit 1
fi

# Backup WordPress files
echo -e "${YELLOW}[2/3] Backing up WordPress files...${NC}"
docker run --rm \
    --volumes-from "${CONTAINER_PREFIX}_wordpress" \
    -v "$(cd .. && pwd)/backups/$BACKUP_NAME:/backup" \
    alpine \
    tar czf /backup/wordpress_files.tar.gz -C /var/www/html .

if [ $? -eq 0 ]; then
    FILES_SIZE=$(du -h "$BACKUP_DIR/$BACKUP_NAME/wordpress_files.tar.gz" | cut -f1)
    echo -e "${GREEN}✓ Files backed up ($FILES_SIZE)${NC}"
else
    echo -e "${RED}✗ Files backup failed!${NC}"
    exit 1
fi

# Backup configurations
echo -e "${YELLOW}[3/3] Backing up configurations...${NC}"
tar czf "$BACKUP_DIR/$BACKUP_NAME/config_files.tar.gz" \
    -C .. \
    nginx/conf.d \
    php/php.ini \
    php/php-fpm.conf \
    mariadb/my.cnf \
    .env \
    2>/dev/null

echo -e "${GREEN}✓ Configurations backed up${NC}"

# Create backup info
cat > "$BACKUP_DIR/$BACKUP_NAME/backup_info.txt" << EOF
WordPress Docker Backup
======================
Date: $(date)
Name: ${BACKUP_NAME}
Database: ${WORDPRESS_DB_NAME}

Files:
- database.sql
- wordpress_files.tar.gz
- config_files.tar.gz

Restore: ./scripts/restore.sh ${BACKUP_NAME}
EOF

# Compress backup
echo -e "${YELLOW}Compressing...${NC}"
cd "$BACKUP_DIR"
tar czf "${BACKUP_NAME}.tar.gz" "$BACKUP_NAME"
rm -rf "$BACKUP_NAME"
cd - > /dev/null

BACKUP_SIZE=$(du -h "$BACKUP_DIR/${BACKUP_NAME}.tar.gz" | cut -f1)
echo ""
echo -e "${GREEN}======================================"
echo -e " Backup Complete!"
echo -e "======================================${NC}"
echo -e "${CYAN}File: ${BACKUP_DIR}/${BACKUP_NAME}.tar.gz${NC}"
echo -e "${CYAN}Size: ${BACKUP_SIZE}${NC}"
echo ""

# Cleanup old backups
RETENTION_DAYS="${BACKUP_RETENTION_DAYS:-30}"
find "$BACKUP_DIR" -name "wordpress_backup_*.tar.gz" -mtime +${RETENTION_DAYS} -delete
echo -e "${GREEN}✓ Cleaned backups older than ${RETENTION_DAYS} days${NC}"
```


### scripts/restore.sh

**Location:** `C:\wordpress-docker\scripts\restore.sh`

```bash
#!/bin/bash
###############################################################################
# WordPress Docker Restore Script
# Usage: ./restore.sh <backup_name>
###############################################################################

set -e

if [ -z "$1" ]; then
    echo "Usage: ./restore.sh <backup_name>"
    echo ""
    echo "Available backups:"
    ls -1 ../backups/*.tar.gz 2>/dev/null | xargs -n 1 basename || echo "  No backups found"
    exit 1
fi

cd "$(dirname "$0")"

# Load environment
if [ -f ../.env ]; then
    export $(cat ../.env | grep -v '^#' | xargs)
fi

BACKUP_FILE="../backups/$1.tar.gz"
[ ! -f "$BACKUP_FILE" ] && BACKUP_FILE="../backups/$1"

if [ ! -f "$BACKUP_FILE" ]; then
    echo "ERROR: Backup not found: $BACKUP_FILE"
    exit 1
fi

CONTAINER_PREFIX="${COMPOSE_PROJECT_NAME:-wordpress-docker}"
RESTORE_DIR="/tmp/wordpress_restore_$$"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

# Confirmation
echo -e "${RED}WARNING: This will overwrite your current WordPress!${NC}"
echo -e "${CYAN}Backup: $BACKUP_FILE${NC}"
read -p "Continue? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Cancelled"
    exit 0
fi

echo ""
echo -e "${GREEN}======================================"
echo -e " WordPress Docker Restore"
echo -e "======================================${NC}"

# Extract backup
echo -e "${YELLOW}[1/3] Extracting backup...${NC}"
mkdir -p "$RESTORE_DIR"
tar xzf "$BACKUP_FILE" -C "$RESTORE_DIR"
BACKUP_PATH="$RESTORE_DIR/$(ls -1 "$RESTORE_DIR" | head -n 1)"
echo -e "${GREEN}✓ Extracted${NC}"

# Restore database
echo -e "${YELLOW}[2/3] Restoring database...${NC}"
docker exec -i "${CONTAINER_PREFIX}_mariadb" mysql \
    -u root \
    -p"${MYSQL_ROOT_PASSWORD}" \
    "${WORDPRESS_DB_NAME}" < "$BACKUP_PATH/database.sql"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Database restored${NC}"
else
    echo -e "${RED}✗ Database restore failed!${NC}"
    exit 1
fi

# Restore files
echo -e "${YELLOW}[3/3] Restoring WordPress files...${NC}"
docker run --rm \
    --volumes-from "${CONTAINER_PREFIX}_wordpress" \
    -v "$BACKUP_PATH:/backup" \
    alpine \
    sh -c "rm -rf /var/www/html/* && tar xzf /backup/wordpress_files.tar.gz -C /var/www/html && chown -R www-data:www-data /var/www/html"

echo -e "${GREEN}✓ Files restored${NC}"

# Cleanup
rm -rf "$RESTORE_DIR"

# Restart containers
echo -e "${YELLOW}Restarting containers...${NC}"
cd ..
docker-compose restart wordpress nginx

echo ""
echo -e "${GREEN}======================================"
echo -e " Restore Complete!"
echo -e "======================================${NC}"
echo -e "${CYAN}Access: https://${DOMAIN_NAME}${NC}"
```


***

## Usage Guide

### Initial Setup (First Time Only)

**1. Open PowerShell as Administrator**

```powershell
cd C:\wordpress-docker
```

**2. Edit .env file - CHANGE ALL PASSWORDS!**

```powershell
notepad .env
```

Change:

- `WORDPRESS_DB_PASSWORD`
- `WORDPRESS_ADMIN_USER`
- `WORDPRESS_ADMIN_PASSWORD`
- `WORDPRESS_ADMIN_EMAIL`
- `MYSQL_ROOT_PASSWORD`

**3. Generate SSL Certificate**

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
.\scripts\setup-ssl-windows.ps1
```

Follow instructions to trust certificate:

- Double-click `ssl\cert.pem`
- Install to "Trusted Root Certification Authorities"

**4. Build and Start Containers**

```powershell
docker-compose build --no-cache
docker-compose up -d
```

Wait 2-3 minutes for first build.

**5. Check Status**

```powershell
docker-compose ps
```

All containers should show "Up".

**6. Install WordPress**

Open browser: `https://localhost.local`

Follow installation wizard:

- Database: From your .env file
- Admin: From your .env file

**7. Access phpMyAdmin**

Open: `http://localhost:8080`

- Username: `root`
- Password: Your `MYSQL_ROOT_PASSWORD`

***

### Daily Operations

**Start containers:**

```powershell
docker-compose start
```

**Stop containers:**

```powershell
docker-compose stop
```

**Restart containers:**

```powershell
docker-compose restart
```

**View logs:**

```powershell
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f wordpress
docker-compose logs -f nginx
docker-compose logs -f mariadb
```

**Check container status:**

```powershell
docker-compose ps
docker stats
```


***

### Accessing WordPress Files

**Method 1: Docker Desktop (Easiest)**

1. Open Docker Desktop
2. Click "Volumes"
3. Find `wordpress-docker_wordpress_data`
4. Click folder icon to browse in File Explorer

**Method 2: Copy from Container**

```powershell
# Copy entire WordPress to Windows
docker cp wordpress-docker_wordpress:/var/www/html C:\wordpress-files

# Copy back
docker cp C:\wordpress-files\wp-content wordpress-docker_wordpress:/var/www/html/
```

**Method 3: Container Shell**

```powershell
docker exec -it wordpress-docker_wordpress bash
cd /var/www/html
ls -la
exit
```


***

### Editing Configurations

**All configs are in your project folder:**

```powershell
# Edit PHP settings (upload limits, memory, etc.)
notepad php\php.ini

# Edit Nginx settings (caching, security)
notepad nginx\conf.d\default.conf

# Edit MariaDB settings (performance)
notepad mariadb\my.cnf

# After editing, restart affected service:
docker-compose restart wordpress
docker-compose restart nginx
docker-compose restart mariadb
```

**Common changes:**

**Increase upload limit:**

```ini
# php/php.ini
upload_max_filesize = 512M
post_max_size = 512M

# nginx/nginx.conf
client_max_body_size 512M;

# Restart:
docker-compose restart wordpress nginx
```


***

### Backup \& Restore

**Create backup (using Git Bash):**

```bash
cd /c/wordpress-docker
./scripts/backup.sh
```

Backups saved to: `C:\wordpress-docker\backups\`

**Restore backup:**

```bash
./scripts/restore.sh wordpress_backup_20251027_143000
```

**Automated backups (Windows Task Scheduler):**

1. Open Task Scheduler
2. Create Basic Task
3. Name: "WordPress Backup"
4. Trigger: Daily at 2:00 AM
5. Action: Start program
6. Program: `C:\Program Files\Git\bin\bash.exe`
7. Arguments: `-c "cd /c/wordpress-docker && ./scripts/backup.sh"`

***

## Troubleshooting

### Containers Won't Start

```powershell
# Check Docker is running
docker --version

# Check port conflicts
netstat -ano | findstr :80
netstat -ano | findstr :443

# View logs
docker-compose logs

# Nuclear option (removes all data!)
docker-compose down -v
docker-compose up -d
```


### Can't Access https://localhost.local

**1. Check hosts file:**

```powershell
notepad C:\Windows\System32\drivers\etc\hosts
```

Should contain: `127.0.0.1    localhost.local`

**2. Trust SSL certificate** (Step 3 above)

**3. Clear browser cache** (Ctrl+Shift+Delete)

**4. Try:** `https://127.0.0.1`

### Database Connection Error

```powershell
# Check MariaDB is running
docker-compose ps mariadb
docker-compose logs mariadb

# Test connection
docker exec wordpress-docker_wordpress ping mariadb

# Verify credentials
docker exec wordpress-docker_wordpress cat /var/www/html/wp-config.php | findstr DB_
```


### 502 Bad Gateway

```powershell
# Check PHP-FPM
docker-compose ps wordpress
docker exec wordpress-docker_wordpress php-fpm-healthcheck

# View logs
docker-compose logs wordpress

# Restart
docker-compose restart wordpress nginx
```


### File Upload Fails

See "Increase upload limit" in Editing Configurations section above.

### Permission Errors

```powershell
docker exec wordpress-docker_wordpress chown -R www-data:www-data /var/www/html
docker exec wordpress-docker_wordpress chmod -R 755 /var/www/html
```


### Slow Performance

**1. Check resources:**

```powershell
docker stats
```

**2. Increase MariaDB buffer:**

```ini
# mariadb/my.cnf
innodb_buffer_pool_size = 1G
```

**3. Install caching plugin:**

- WP Super Cache
- W3 Total Cache

**4. Check OPcache:**

```powershell
docker exec wordpress-docker_wordpress php -i | findstr opcache.enable
```


### Out of Disk Space

```powershell
# Check usage
docker system df

# Clean up
docker system prune -a --volumes -f
```


***

## Security Checklist

### Before Production

- [ ] Change ALL passwords in .env
- [ ] Change admin username (not "admin")
- [ ] Use real domain name
- [ ] Use Let's Encrypt for SSL
- [ ] Disable WordPress debug mode
- [ ] Set opcache.validate_timestamps=0
- [ ] Enable firewall
- [ ] Set up automated backups
- [ ] Install security plugin (Wordfence, Sucuri)
- [ ] Keep WordPress/plugins/themes updated
- [ ] Remove unused plugins/themes
- [ ] Use strong WordPress salts
- [ ] Regular security audits


### Security Features Included

✅ HTTPS with TLS 1.2+
✅ Security headers (HSTS, CSP, X-Frame-Options)
✅ Rate limiting on login pages
✅ XML-RPC disabled
✅ Sensitive files blocked
✅ PHP dangerous functions disabled
✅ Nginx version hidden
✅ Session security enabled
✅ File upload validation

***

## Quick Reference

### URLs

- **WordPress:** https://localhost.local
- **Admin:** https://localhost.local/wp-admin
- **phpMyAdmin:** http://localhost:8080


### Default Credentials

**WordPress Admin:**

- Username: From .env `WORDPRESS_ADMIN_USER`
- Password: From .env `WORDPRESS_ADMIN_PASSWORD`

**phpMyAdmin:**

- Username: `root`
- Password: From .env `MYSQL_ROOT_PASSWORD`


### Important Commands

```powershell
# Start
docker-compose up -d

# Stop
docker-compose stop

# Restart
docker-compose restart

# Logs
docker-compose logs -f

# Status
docker-compose ps

# Rebuild
docker-compose build --no-cache
docker-compose up -d

# Backup (Git Bash)
./scripts/backup.sh

# Restore (Git Bash)
./scripts/restore.sh backup_name
```


### File Locations

- **WordPress Files:** Docker volume `wordpress-docker_wordpress_data`
- **Database Files:** Docker volume `wordpress-docker_mariadb_data`
- **Logs:** `C:\wordpress-docker\logs\`
- **Backups:** `C:\wordpress-docker\backups\`
- **SSL Certs:** `C:\wordpress-docker\ssl\`

***

## Support \& Resources

- **Docker Documentation:** https://docs.docker.com/
- **WordPress Documentation:** https://wordpress.org/documentation/
- **Nginx Documentation:** https://nginx.org/en/docs/
- **PHP Documentation:** https://www.php.net/docs.php
- **MariaDB Documentation:** https://mariadb.com/kb/en/

***

## 🎉 You're Done!

Your complete WordPress development environment is ready with:

✅ Latest stable versions (Nginx, PHP 8.3, MariaDB 11.6)
✅ SSL/HTTPS working
✅ All configs editable
✅ Performance optimized
✅ Security hardened
✅ Automated backups
✅ Easy Windows access
✅ Production-ready architecture

**Access your site:** https://localhost.local
**Happy developing!** 🚀

