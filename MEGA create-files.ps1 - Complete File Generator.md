###############################################################################
# WordPress Docker - Complete Setup Generator for Windows 11
# Tested on: Windows 11, PowerShell 5.1+, Docker Desktop 4.x
# 
# Usage:
#   1. Create folder: C:\wordpress-docker
#   2. Save this as: create-files.ps1
#   3. Run: .\create-files.ps1
###############################################################################

param(
    [switch]$Force = $false
)

$ErrorActionPreference = "Continue"

Clear-Host
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host " WordPress Docker Setup Generator" -ForegroundColor Cyan
Write-Host " Windows 11 Compatible Version" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

$projectRoot = $PSScriptRoot
if (-not $projectRoot) {
    $projectRoot = (Get-Location).Path
}

Write-Host "Project Location: $projectRoot" -ForegroundColor Green
Write-Host ""

# Create directory function
function New-ProjectDirectory {
    param([string]$Path)
    
    $fullPath = Join-Path $projectRoot $Path
    if (-not (Test-Path $fullPath)) {
        try {
            New-Item -ItemType Directory -Path $fullPath -Force -ErrorAction Stop | Out-Null
            Write-Host "  [+] Created: $Path" -ForegroundColor Green
        }
        catch {
            Write-Host "  [!] Failed to create: $Path" -ForegroundColor Red
        }
    }
}

# Create file function
function New-ProjectFile {
    param(
        [string]$Path,
        [string]$Content
    )
    
    $fullPath = Join-Path $projectRoot $Path
    
    if ((Test-Path $fullPath) -and -not $Force) {
        Write-Host "  [~] Exists: $Path" -ForegroundColor Yellow
        return
    }
    
    try {
        $Content | Out-File -FilePath $fullPath -Encoding UTF8 -Force -ErrorAction Stop
        Write-Host "  [+] Created: $Path" -ForegroundColor Green
    }
    catch {
        Write-Host "  [!] Failed: $Path - $($_.Exception.Message)" -ForegroundColor Red
    }
}

###############################################################################
# STEP 1: Create Directory Structure
###############################################################################

Write-Host "[Step 1/10] Creating directories..." -ForegroundColor Cyan
Write-Host ""

New-ProjectDirectory "nginx"
New-ProjectDirectory "nginx\conf.d"
New-ProjectDirectory "php"
New-ProjectDirectory "mariadb"
New-ProjectDirectory "mariadb\init"
New-ProjectDirectory "ssl"
New-ProjectDirectory "scripts"
New-ProjectDirectory "backups"
New-ProjectDirectory "logs"
New-ProjectDirectory "logs\nginx"
New-ProjectDirectory "logs\php"
New-ProjectDirectory "logs\mariadb"

Write-Host ""

###############################################################################
# STEP 2: Create .env File
###############################################################################

Write-Host "[Step 2/10] Creating environment file..." -ForegroundColor Cyan
Write-Host ""

$envFile = "COMPOSE_PROJECT_NAME=wordpress-docker

WORDPRESS_DB_NAME=wordpress
WORDPRESS_DB_USER=wpuser
WORDPRESS_DB_PASSWORD=ChangeThisPassword123!
WORDPRESS_TABLE_PREFIX=wp_

WORDPRESS_ADMIN_USER=myadmin
WORDPRESS_ADMIN_PASSWORD=ChangeAdminPassword123!
WORDPRESS_ADMIN_EMAIL=admin@localhost.local

MYSQL_ROOT_PASSWORD=ChangeRootPassword123!

MARIADB_VERSION=11.6
PHP_VERSION=8.3

DOMAIN_NAME=localhost.local
SSL_COUNTRY=US
SSL_STATE=California
SSL_CITY=San Francisco
SSL_ORG=My Organization
SSL_ORG_UNIT=IT Department

NGINX_HTTP_PORT=80
NGINX_HTTPS_PORT=443
PHPMYADMIN_PORT=8080

TIMEZONE=UTC

PHP_MEMORY_LIMIT=512M
PHP_MAX_EXECUTION_TIME=300
PHP_MAX_INPUT_TIME=300
PHP_UPLOAD_MAX_FILESIZE=256M
PHP_POST_MAX_SIZE=256M

BACKUP_RETENTION_DAYS=30"

New-ProjectFile ".env" $envFile

Write-Host ""

###############################################################################
# STEP 3: Create docker-compose.yml
###############################################################################

Write-Host "[Step 3/10] Creating Docker Compose file..." -ForegroundColor Cyan
Write-Host ""

# Use backticks to escape dollar signs in YAML
$composeFile = @"
version: '3.8'

services:
  mariadb:
    image: mariadb:`${MARIADB_VERSION:-11.6}
    container_name: `${COMPOSE_PROJECT_NAME}_mariadb
    restart: unless-stopped
    environment:
      MARIADB_ROOT_PASSWORD: `${MYSQL_ROOT_PASSWORD}
      MARIADB_DATABASE: `${WORDPRESS_DB_NAME}
      MARIADB_USER: `${WORDPRESS_DB_USER}
      MARIADB_PASSWORD: `${WORDPRESS_DB_PASSWORD}
      TZ: `${TIMEZONE}
    volumes:
      - mariadb_data:/var/lib/mysql
      - ./mariadb/my.cnf:/etc/mysql/conf.d/custom.cnf:ro
      - ./mariadb/init:/docker-entrypoint-initdb.d:ro
      - ./logs/mariadb:/var/log/mysql
    networks:
      - wordpress-network
    command: >
      --character-set-server=utf8mb4
      --collation-server=utf8mb4_unicode_ci
      --max_allowed_packet=256M
      --innodb_buffer_pool_size=512M
      --innodb_log_file_size=128M
    healthcheck:
      test: ["CMD", "healthcheck.sh", "--connect", "--innodb_initialized"]
      interval: 30s
      timeout: 10s
      retries: 5
      start_period: 40s

  wordpress:
    build:
      context: ./php
      args:
        PHP_VERSION: `${PHP_VERSION:-8.3}
    container_name: `${COMPOSE_PROJECT_NAME}_wordpress
    restart: unless-stopped
    depends_on:
      mariadb:
        condition: service_healthy
    environment:
      WORDPRESS_DB_HOST: mariadb:3306
      WORDPRESS_DB_NAME: `${WORDPRESS_DB_NAME}
      WORDPRESS_DB_USER: `${WORDPRESS_DB_USER}
      WORDPRESS_DB_PASSWORD: `${WORDPRESS_DB_PASSWORD}
      WORDPRESS_TABLE_PREFIX: `${WORDPRESS_TABLE_PREFIX}
      WORDPRESS_DEBUG: 0
      TZ: `${TIMEZONE}
    volumes:
      - wordpress_data:/var/www/html
      - ./php/php.ini:/usr/local/etc/php/conf.d/custom.ini:ro
      - ./php/php-fpm.conf:/usr/local/etc/php-fpm.d/zz-custom.conf:ro
      - ./logs/php:/var/log/php
    networks:
      - wordpress-network
    healthcheck:
      test: ["CMD-SHELL", "php-fpm-healthcheck"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

  nginx:
    build:
      context: ./nginx
    container_name: `${COMPOSE_PROJECT_NAME}_nginx
    restart: unless-stopped
    depends_on:
      - wordpress
    ports:
      - "`${NGINX_HTTP_PORT:-80}:80"
      - "`${NGINX_HTTPS_PORT:-443}:443"
    environment:
      DOMAIN_NAME: `${DOMAIN_NAME}
      TZ: `${TIMEZONE}
    volumes:
      - wordpress_data:/var/www/html:ro
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./nginx/conf.d:/etc/nginx/conf.d:ro
      - ./ssl:/etc/nginx/ssl:ro
      - ./logs/nginx:/var/log/nginx
    networks:
      - wordpress-network
    healthcheck:
      test: ["CMD", "nginx", "-t"]
      interval: 30s
      timeout: 10s
      retries: 3

  phpmyadmin:
    image: phpmyadmin:latest
    container_name: `${COMPOSE_PROJECT_NAME}_phpmyadmin
    restart: unless-stopped
    depends_on:
      - mariadb
    ports:
      - "`${PHPMYADMIN_PORT:-8080}:80"
    environment:
      PMA_HOST: mariadb
      PMA_PORT: 3306
      MYSQL_ROOT_PASSWORD: `${MYSQL_ROOT_PASSWORD}
      UPLOAD_LIMIT: `${PHP_UPLOAD_MAX_FILESIZE}
      TZ: `${TIMEZONE}
    networks:
      - wordpress-network

networks:
  wordpress-network:
    driver: bridge

volumes:
  mariadb_data:
    driver: local
  wordpress_data:
    driver: local
"@

New-ProjectFile "docker-compose.yml" $composeFile

Write-Host ""

###############################################################################
# STEP 4: Create Nginx Files
###############################################################################

Write-Host "[Step 4/10] Creating Nginx configuration..." -ForegroundColor Cyan
Write-Host ""

$nginxDockerfile = @"
FROM nginx:ubuntu

RUN apt-get update && apt-get install -y \
    openssl \
    curl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/log/nginx /var/cache/nginx

COPY nginx.conf /etc/nginx/nginx.conf
COPY conf.d/ /etc/nginx/conf.d/

EXPOSE 80 443

CMD ["nginx", "-g", "daemon off;"]
"@

New-ProjectFile "nginx\Dockerfile" $nginxDockerfile

$nginxConf = @"
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;

events {
    worker_connections 1024;
    multi_accept on;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    log_format main '`$remote_addr - `$remote_user [`$time_local] "`$request" '
                    '`$status `$body_bytes_sent "`$http_referer" '
                    '"`$http_user_agent" "`$http_x_forwarded_for"';

    access_log /var/log/nginx/access.log main;

    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    client_max_body_size 256M;

    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/xml text/javascript 
               application/json application/javascript;

    server_tokens off;

    include /etc/nginx/conf.d/*.conf;
}
"@

New-ProjectFile "nginx\nginx.conf" $nginxConf

$nginxSite = @"
upstream php-fpm {
    server wordpress:9000;
    keepalive 32;
}

server {
    listen 80;
    listen [::]:80;
    server_name localhost localhost.local;
    
    location / {
        return 301 https://`$host`$request_uri;
    }
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name localhost localhost.local;

    root /var/www/html;
    index index.php index.html;

    ssl_certificate /etc/nginx/ssl/cert.pem;
    ssl_certificate_key /etc/nginx/ssl/key.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;

    access_log /var/log/nginx/wordpress-access.log;
    error_log /var/log/nginx/wordpress-error.log;

    location / {
        try_files `$uri `$uri/ /index.php?`$args;
    }

    location ~ /\. {
        deny all;
        access_log off;
    }

    location = /xmlrpc.php {
        deny all;
        access_log off;
    }

    location ~ \.php$ {
        try_files `$uri =404;
        include fastcgi_params;
        fastcgi_pass php-fpm;
        fastcgi_param SCRIPT_FILENAME `$document_root`$fastcgi_script_name;
        fastcgi_index index.php;
        fastcgi_intercept_errors on;
        fastcgi_buffer_size 128k;
        fastcgi_buffers 256 16k;
        fastcgi_read_timeout 300;
    }

    location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg|woff|woff2|ttf|eot)$ {
        expires 30d;
        access_log off;
    }
}
"@

New-ProjectFile "nginx\conf.d\default.conf" $nginxSite

Write-Host ""

###############################################################################
# STEP 5: Create PHP Files
###############################################################################

Write-Host "[Step 5/10] Creating PHP configuration..." -ForegroundColor Cyan
Write-Host ""

$phpDockerfile = @"
ARG PHP_VERSION=8.3
FROM wordpress:php`${PHP_VERSION}-fpm-alpine

RUN apk add --no-cache \
    libzip-dev zip unzip git bash fcgi \
    imagemagick imagemagick-libs libgomp

RUN docker-php-ext-install opcache zip exif

RUN apk add --no-cache --virtual .build-deps `$PHPIZE_DEPS \
    && pecl install redis \
    && docker-php-ext-enable redis \
    && apk del .build-deps

RUN apk add --no-cache --virtual .imagick-deps `$PHPIZE_DEPS imagemagick-dev libtool \
    && git clone https://github.com/Imagick/imagick.git --depth 1 /tmp/imagick \
    && cd /tmp/imagick \
    && phpize && ./configure && make && make install \
    && docker-php-ext-enable imagick \
    && rm -rf /tmp/imagick \
    && apk del .imagick-deps

RUN echo '#!/bin/sh' > /usr/local/bin/php-fpm-healthcheck && \
    echo 'SCRIPT_NAME=/ping SCRIPT_FILENAME=/ping REQUEST_METHOD=GET cgi-fcgi -bind -connect 127.0.0.1:9000 || exit 1' >> /usr/local/bin/php-fpm-healthcheck && \
    chmod +x /usr/local/bin/php-fpm-healthcheck

RUN mkdir -p /var/log/php && chown www-data:www-data /var/log/php

COPY php.ini /usr/local/etc/php/conf.d/custom.ini
COPY php-fpm.conf /usr/local/etc/php-fpm.d/zz-custom.conf

WORKDIR /var/www/html
EXPOSE 9000
CMD ["php-fpm"]
"@

New-ProjectFile "php\Dockerfile" $phpDockerfile

$phpIni = @"
max_execution_time = 300
max_input_time = 300
memory_limit = 512M
post_max_size = 256M
upload_max_filesize = 256M
max_input_vars = 3000

display_errors = Off
display_startup_errors = Off
log_errors = On
error_log = /var/log/php/error.log
error_reporting = E_ALL

expose_php = Off
allow_url_fopen = On
allow_url_include = Off

opcache.enable = 1
opcache.enable_cli = 0
opcache.memory_consumption = 256
opcache.interned_strings_buffer = 16
opcache.max_accelerated_files = 10000
opcache.validate_timestamps = 1
opcache.revalidate_freq = 60

realpath_cache_size = 4096K
realpath_cache_ttl = 600

file_uploads = On
max_file_uploads = 20
date.timezone = UTC
"@

New-ProjectFile "php\php.ini" $phpIni

$phpFpm = @"
[www]
pm = dynamic
pm.max_children = 50
pm.start_servers = 10
pm.min_spare_servers = 5
pm.max_spare_servers = 20
pm.max_requests = 500
pm.process_idle_timeout = 10s

request_terminate_timeout = 300s
request_slowlog_timeout = 10s
slowlog = /var/log/php/slow.log

catch_workers_output = yes
php_flag[display_errors] = off
php_admin_value[error_log] = /var/log/php/fpm-error.log
php_admin_flag[log_errors] = on

security.limit_extensions = .php

pm.status_path = /status
ping.path = /ping
ping.response = pong

clear_env = no
"@

New-ProjectFile "php\php-fpm.conf" $phpFpm

Write-Host ""

###############################################################################
# STEP 6: Create MariaDB Files
###############################################################################

Write-Host "[Step 6/10] Creating MariaDB configuration..." -ForegroundColor Cyan
Write-Host ""

$mariadbConf = @"
[mysqld]
user = mysql
port = 3306
datadir = /var/lib/mysql

character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci

bind-address = 0.0.0.0
max_connections = 200
max_allowed_packet = 256M
wait_timeout = 600

slow_query_log = 1
slow_query_log_file = /var/log/mysql/slow.log
long_query_time = 2

innodb_buffer_pool_size = 512M
innodb_log_file_size = 128M
innodb_file_per_table = 1

[client]
port = 3306
default-character-set = utf8mb4

[mysqldump]
quick
max_allowed_packet = 256M
default-character-set = utf8mb4
"@

New-ProjectFile "mariadb\my.cnf" $mariadbConf

$mariadbInit = @"
OPTIMIZE TABLE mysql.user;
OPTIMIZE TABLE mysql.db;
FLUSH PRIVILEGES;
SHOW DATABASES;
"@

New-ProjectFile "mariadb\init\init.sql" $mariadbInit

Write-Host ""

###############################################################################
# STEP 7: Create Support Files
###############################################################################

Write-Host "[Step 7/10] Creating support files..." -ForegroundColor Cyan
Write-Host ""

$gitignore = @"
.env
ssl/*.pem
ssl/*.key
ssl/*.crt
backups/
*.zip
*.tar.gz
*.sql
logs/
*.log
.DS_Store
Thumbs.db
desktop.ini
.vscode/
.idea/
*.swp
tmp/
temp/
"@

New-ProjectFile ".gitignore" $gitignore

$readme = @"
# WordPress Docker Environment

Complete WordPress setup with Docker for Windows 11.

## Stack

- Nginx (Ubuntu)
- PHP 8.3-FPM (Alpine)
- MariaDB 11.6
- WordPress (Latest)
- phpMyAdmin

## Quick Start

1. Edit .env and change passwords
2. Run: .\scripts\start.ps1
3. Access: https://localhost.local

## Commands

Start: .\scripts\start.ps1
Stop: .\scripts\stop.ps1
Logs: .\scripts\logs.ps1
Backup: .\scripts\backup.ps1

## Access URLs

WordPress: https://localhost.local
Admin: https://localhost.local/wp-admin
phpMyAdmin: http://localhost:8080
"@

New-ProjectFile "README.md" $readme

Write-Host ""

###############################################################################
# STEP 8: Create PowerShell Scripts
###############################################################################

Write-Host "[Step 8/10] Creating PowerShell scripts..." -ForegroundColor Cyan
Write-Host ""

# Start script
$startScript = @'
$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "Starting WordPress Docker..." -ForegroundColor Cyan
Write-Host ""

$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $projectRoot

docker-compose up -d

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "Containers started successfully!" -ForegroundColor Green
    Write-Host ""
    Start-Sleep -Seconds 2
    docker-compose ps
    Write-Host ""
    Write-Host "Access URLs:" -ForegroundColor Cyan
    Write-Host "  WordPress:   https://localhost.local" -ForegroundColor White
    Write-Host "  phpMyAdmin:  http://localhost:8080" -ForegroundColor White
    Write-Host ""
} else {
    Write-Host "Failed to start containers!" -ForegroundColor Red
    exit 1
}
'@

New-ProjectFile "scripts\start.ps1" $startScript

# Stop script
$stopScript = @'
$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "Stopping WordPress Docker..." -ForegroundColor Cyan
Write-Host ""

$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $projectRoot

docker-compose stop

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "Containers stopped successfully!" -ForegroundColor Green
    Write-Host ""
} else {
    Write-Host "Failed to stop containers!" -ForegroundColor Red
    exit 1
}
'@

New-ProjectFile "scripts\stop.ps1" $stopScript

# Logs script
$logsScript = @'
param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("all", "nginx", "wordpress", "mariadb", "phpmyadmin")]
    [string]$Service = "all",
    
    [Parameter(Mandatory=$false)]
    [int]$Lines = 100,
    
    [switch]$Follow
)

$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $projectRoot

Write-Host ""
Write-Host "Docker Logs - Service: $Service" -ForegroundColor Cyan
Write-Host ""

if ($Follow) {
    if ($Service -eq "all") {
        docker-compose logs -f
    } else {
        docker-compose logs -f $Service
    }
} else {
    if ($Service -eq "all") {
        docker-compose logs --tail=$Lines
    } else {
        docker-compose logs --tail=$Lines $Service
    }
}
'@

New-ProjectFile "scripts\logs.ps1" $logsScript

# Backup script
$backupScript = @'
$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "WordPress Docker Backup" -ForegroundColor Cyan
Write-Host "======================" -ForegroundColor Cyan
Write-Host ""

$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $projectRoot

$envFile = Join-Path $projectRoot ".env"
if (Test-Path $envFile) {
    Get-Content $envFile | ForEach-Object {
        if ($_ -match '^\s*([^#][^=]+)=(.+)$') {
            Set-Item -Path "env:$($matches[1].Trim())" -Value $matches[2].Trim()
        }
    }
}

$backupDir = Join-Path $projectRoot "backups"
$date = Get-Date -Format "yyyyMMdd_HHmmss"
$backupName = "wordpress_backup_$date"
$containerPrefix = if ($env:COMPOSE_PROJECT_NAME) { $env:COMPOSE_PROJECT_NAME } else { "wordpress-docker" }

Write-Host "Backup name: $backupName" -ForegroundColor Cyan
Write-Host ""

$backupPath = Join-Path $backupDir $backupName
New-Item -ItemType Directory -Path $backupPath -Force | Out-Null

Write-Host "[1/2] Backing up database..." -ForegroundColor Yellow

$dbFile = Join-Path $backupPath "database.sql"
docker exec "$($containerPrefix)_mariadb" mysqldump -u root -p"$env:MYSQL_ROOT_PASSWORD" --single-transaction --quick "$env:WORDPRESS_DB_NAME" | Out-File -FilePath $dbFile -Encoding UTF8

if ($LASTEXITCODE -eq 0) {
    $dbSize = [math]::Round((Get-Item $dbFile).Length / 1MB, 2)
    Write-Host "Database backed up ($dbSize MB)" -ForegroundColor Green
}

Write-Host "[2/2] Backing up files..." -ForegroundColor Yellow

docker run --rm --volumes-from "$($containerPrefix)_wordpress" -v "$($backupPath):/backup" alpine tar czf /backup/wordpress_files.tar.gz -C /var/www/html .

if ($LASTEXITCODE -eq 0) {
    $filesSize = [math]::Round((Get-Item (Join-Path $backupPath "wordpress_files.tar.gz")).Length / 1MB, 2)
    Write-Host "Files backed up ($filesSize MB)" -ForegroundColor Green
}

Write-Host ""
Write-Host "Compressing backup..." -ForegroundColor Yellow
$archivePath = "$backupPath.zip"
Compress-Archive -Path "$backupPath\*" -DestinationPath $archivePath -Force
Remove-Item -Path $backupPath -Recurse -Force

$totalSize = [math]::Round((Get-Item $archivePath).Length / 1MB, 2)

Write-Host ""
Write-Host "Backup complete!" -ForegroundColor Green
Write-Host "File: $archivePath" -ForegroundColor Cyan
Write-Host "Size: $totalSize MB" -ForegroundColor Cyan
Write-Host ""
'@

New-ProjectFile "scripts\backup.ps1" $backupScript

Write-Host ""

###############################################################################
# STEP 9: Create Setup Instructions
###############################################################################

Write-Host "[Step 9/10] Creating setup instructions..." -ForegroundColor Cyan
Write-Host ""

$setupInstructions = @"
WordPress Docker Setup Instructions for Windows 11
===================================================

PREREQUISITES
-------------
1. Docker Desktop for Windows 11
   Download: https://www.docker.com/products/docker-desktop

2. Git for Windows (includes OpenSSL)
   Download: https://git-scm.com/download/win

SETUP STEPS
-----------

STEP 1: Edit Passwords
-----------------------
notepad .env

Change these values:
- WORDPRESS_DB_PASSWORD
- MYSQL_ROOT_PASSWORD
- WORDPRESS_ADMIN_PASSWORD
- WORDPRESS_ADMIN_USER

STEP 2: Generate SSL Certificate
---------------------------------
cd ssl

For Git Bash:
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout key.pem -out cert.pem -subj "/CN=localhost.local" -addext "subjectAltName=DNS:localhost,DNS:localhost.local"

For PowerShell:
& 'C:\Program Files\Git\usr\bin\openssl.exe' req -x509 -nodes -days 365 -newkey rsa:2048 -keyout key.pem -out cert.pem -subj "/CN=localhost.local" -addext "subjectAltName=DNS:localhost,DNS:localhost.local"

cd ..

STEP 3: Trust SSL Certificate (Windows 11)
-------------------------------------------
1. Navigate to C:\wordpress-docker\ssl
2. Double-click cert.pem
3. Click "Install Certificate"
4. Select "Local Machine"
5. Choose "Place all certificates in the following store"
6. Click "Browse" and select "Trusted Root Certification Authorities"
7. Click Next, then Finish

STEP 4: Add to Hosts File
--------------------------
Run PowerShell as Administrator and execute:

Add-Content -Path C:\Windows\System32\drivers\etc\hosts -Value "`n127.0.0.1`tlocalhost.local"

Or manually edit C:\Windows\System32\drivers\etc\hosts and add:
127.0.0.1    localhost.local

STEP 5: Build Docker Containers
--------------------------------
docker-compose build

This will take 5-10 minutes on first run.

STEP 6: Start Containers
-------------------------
docker-compose up -d

Or use the script:
.\scripts\start.ps1

STEP 7: Access WordPress
-------------------------
Open browser and navigate to:
https://localhost.local

Accept the security warning (self-signed certificate).

Complete WordPress installation:
- Site Title: Your site name
- Username: (from .env WORDPRESS_ADMIN_USER)
- Password: (from .env WORDPRESS_ADMIN_PASSWORD)
- Email: (from .env WORDPRESS_ADMIN_EMAIL)

DAILY USAGE
-----------
Start containers:    .\scripts\start.ps1
Stop containers:     .\scripts\stop.ps1
View logs:           .\scripts\logs.ps1
Create backup:       .\scripts\backup.ps1

ACCESS URLS
-----------
WordPress:    https://localhost.local
Admin Panel:  https://localhost.local/wp-admin
phpMyAdmin:   http://localhost:8080

phpMyAdmin Login:
- Server:   mariadb
- Username: root
- Password: (from .env MYSQL_ROOT_PASSWORD)

TROUBLESHOOTING
---------------

Problem: Containers won't start
Solution: docker-compose logs
          docker-compose down -v
          docker-compose up -d

Problem: Can't access https://localhost.local
Solution: - Check hosts file has entry
          - Trust SSL certificate
          - Clear browser cache
          - Try https://127.0.0.1

Problem: Port already in use
Solution: netstat -ano | findstr :80
          netstat -ano | findstr :443
          Stop conflicting service or change ports in .env

Problem: Database connection error
Solution: docker-compose logs mariadb
          Verify passwords in .env match

CONFIGURATION FILES
-------------------
All configuration files are in your project folder and can be edited with Notepad:

- nginx\nginx.conf        - Main Nginx config
- nginx\conf.d\default.conf - WordPress site config
- php\php.ini             - PHP settings
- php\php-fpm.conf        - PHP-FPM process manager
- mariadb\my.cnf          - MariaDB database settings

After editing any config, restart the affected service:
docker-compose restart nginx
docker-compose restart wordpress
docker-compose restart mariadb

USEFUL COMMANDS
---------------
# Restart specific service
docker-compose restart nginx

# Rebuild after Dockerfile changes
docker-compose build --no-cache
docker-compose up -d

# View container status
docker-compose ps

# Access container shell
docker exec -it wordpress-docker_wordpress bash
docker exec -it wordpress-docker_mariadb bash

# Copy files from container
docker cp wordpress-docker_wordpress:/var/www/html C:\wordpress-files

# View resource usage
docker stats

# Clean up Docker
docker system prune -a

BACKUP AND RESTORE
------------------
Backup: .\scripts\backup.ps1
Backups stored in: C:\wordpress-docker\backups\

To restore:
1. Stop containers: docker-compose stop
2. Extract backup ZIP
3. Import database: docker exec -i wordpress-docker_mariadb mysql -u root -p[PASSWORD] wordpress < database.sql
4. Copy files: docker cp wordpress_files wordpress-docker_wordpress:/var/www/html/
5. Start containers: docker-compose start

SUPPORT
-------
For issues, check:
- Docker Desktop is running
- Ports 80, 443, 8080 are available
- All passwords in .env are correct
- SSL certificate is trusted
- hosts file has localhost.local entry

Log locations:
- C:\wordpress-docker\logs\nginx\
- C:\wordpress-docker\logs\php\
- C:\wordpress-docker\logs\mariadb\
"@

New-ProjectFile "SETUP-GUIDE.txt" $setupInstructions

Write-Host ""

###############################################################################
# STEP 10: Create Quick Start Script
###############################################################################

Write-Host "[Step 10/10] Creating quick-start helper..." -ForegroundColor Cyan
Write-Host ""

$quickStart = @'
# Quick Start Helper
# Run this after editing .env to complete setup

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "WordPress Docker Quick Setup" -ForegroundColor Cyan
Write-Host "============================" -ForegroundColor Cyan
Write-Host ""

$root = $PSScriptRoot

# Check if .env has been edited
$envPath = Join-Path $root ".env"
$envContent = Get-Content $envPath -Raw
if ($envContent -match "ChangeThisPassword") {
    Write-Host "WARNING: Please edit .env and change all passwords first!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Run: notepad .env" -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

# Check if Docker is running
try {
    docker ps | Out-Null
} catch {
    Write-Host "ERROR: Docker is not running!" -ForegroundColor Red
    Write-Host "Please start Docker Desktop and try again." -ForegroundColor Yellow
    exit 1
}

Write-Host "[1/4] Generating SSL certificate..." -ForegroundColor Yellow
$sslPath = Join-Path $root "ssl"
Set-Location $sslPath

$openssl = "C:\Program Files\Git\usr\bin\openssl.exe"
if (Test-Path $openssl) {
    & $openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout key.pem -out cert.pem -subj "/CN=localhost.local" -addext "subjectAltName=DNS:localhost,DNS:localhost.local" 2>&1 | Out-Null
    Write-Host "SSL certificate generated" -ForegroundColor Green
} else {
    Write-Host "OpenSSL not found. Please install Git for Windows." -ForegroundColor Yellow
}

Set-Location $root

Write-Host "[2/4] Building Docker containers..." -ForegroundColor Yellow
Write-Host "This will take 5-10 minutes..." -ForegroundColor Gray
docker-compose build
Write-Host "Containers built" -ForegroundColor Green

Write-Host "[3/4] Starting containers..." -ForegroundColor Yellow
docker-compose up -d
Start-Sleep -Seconds 5
Write-Host "Containers started" -ForegroundColor Green

Write-Host "[4/4] Checking status..." -ForegroundColor Yellow
docker-compose ps

Write-Host ""
Write-Host "Setup complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Access URLs:" -ForegroundColor Cyan
Write-Host "  WordPress:   https://localhost.local" -ForegroundColor White
Write-Host "  phpMyAdmin:  http://localhost:8080" -ForegroundColor White
Write-Host ""
Write-Host "Next: Complete WordPress installation in your browser" -ForegroundColor Yellow
Write-Host ""
'@

New-ProjectFile "quick-start.ps1" $quickStart

Write-Host ""

###############################################################################
# COMPLETION MESSAGE
###############################################################################

Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host " SETUP FILES CREATED SUCCESSFULLY!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""
Write-Host "Created:" -ForegroundColor Cyan
Write-Host "  [+] Docker configuration files" -ForegroundColor White
Write-Host "  [+] Nginx, PHP, MariaDB configs" -ForegroundColor White
Write-Host "  [+] PowerShell utility scripts" -ForegroundColor White
Write-Host "  [+] Documentation and guides" -ForegroundColor White
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Edit passwords:" -ForegroundColor White
Write-Host "   notepad .env" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Run quick setup:" -ForegroundColor White
Write-Host "   .\quick-start.ps1" -ForegroundColor Gray
Write-Host ""
Write-Host "   OR follow manual steps in:" -ForegroundColor White
Write-Host "   notepad SETUP-GUIDE.txt" -ForegroundColor Gray
Write-Host ""
Write-Host "Read SETUP-GUIDE.txt for complete instructions" -ForegroundColor Cyan
Write-Host ""
Write-Host "Support: All configs are in project folder" -ForegroundColor Gray
Write-Host "         Edit with Notepad, restart affected service" -ForegroundColor Gray
Write-Host ""
