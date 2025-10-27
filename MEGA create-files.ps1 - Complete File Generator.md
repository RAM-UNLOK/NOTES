Below is a single, Windows‑ready mega script that generates the complete WordPress Docker stack using Nginx Alpine, PHP 8.3‑FPM Alpine, MariaDB 11.6, plus all utility scripts and SSL with fixed, silent OpenSSL handling, followed by a separate, concise installation guide for Docker Desktop on Windows 11.[1][2][3][4]

### Save as C:\wordpress-docker\create-files.ps1
```powershell
###############################################################################
# WordPress Docker - MEGA File Creator (Windows 11) - Alpine Edition
# Stack: nginx:alpine + wordpress:php8.3-fpm-alpine + mariadb:11.6 + phpMyAdmin
# Notes:
# - Uses small, Docker-optimized base images (Alpine) for faster pulls and lower RAM. 
# - Includes SSL generation with fully silent OpenSSL execution (no dot spam). 
# - All configs and scripts are Windows-friendly and editable in File Explorer.
###############################################################################

param([switch]$Force = $false)
$ErrorActionPreference = "Stop"

function New-ProjectDirectory {
    param([string]$Path)
    $full = Join-Path $PSScriptRoot $Path
    if (-not (Test-Path $full)) { New-Item -ItemType Directory -Path $full -Force | Out-Null }
    Write-Host "Dir: $Path"
}

function New-ProjectFile {
    param([string]$Path,[string]$Content)
    $full = Join-Path $PSScriptRoot $Path
    if ((Test-Path $full) -and -not $Force) { Write-Host "Keep: $Path"; return }
    $Content | Out-File -FilePath $full -Encoding UTF8 -Force
    Write-Host "File: $Path"
}

Write-Host ""
Write-Host "== WordPress Docker - File Generator (Alpine) =="

# 1) Directories
New-ProjectDirectory "nginx"
New-ProjectDirectory "nginx\conf.d"
New-ProjectDirectory "php"
New-ProjectDirectory "mariadb"
New-ProjectDirectory "mariadb\init"
New-ProjectDirectory "ssl"
New-ProjectDirectory "scripts"
New-ProjectDirectory "backups"
New-ProjectDirectory "logs\nginx"
New-ProjectDirectory "logs\php"
New-ProjectDirectory "logs\mariadb"

# 2) .env (edit passwords before first run)
$envTxt = @'
COMPOSE_PROJECT_NAME=wordpress-docker

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
SSL_ORG_UNIT=IT

NGINX_HTTP_PORT=80
NGINX_HTTPS_PORT=443
PHPMYADMIN_PORT=8080

TIMEZONE=UTC

PHP_MEMORY_LIMIT=512M
PHP_MAX_EXECUTION_TIME=300
PHP_MAX_INPUT_TIME=300
PHP_UPLOAD_MAX_FILESIZE=256M
PHP_POST_MAX_SIZE=256M

BACKUP_RETENTION_DAYS=30
'@
New-ProjectFile ".env" $envTxt

# 3) docker-compose.yml (nginx:alpine + wordpress:php-fpm-alpine + mariadb 11.6)
$compose = @'
version: "3.8"

services:
  mariadb:
    image: mariadb:${MARIADB_VERSION:-11.6}
    container_name: ${COMPOSE_PROJECT_NAME}_mariadb
    restart: unless-stopped
    environment:
      MARIADB_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
      MARIADB_DATABASE: ${WORDPRESS_DB_NAME}
      MARIADB_USER: ${WORDPRESS_DB_USER}
      MARIADB_PASSWORD: ${WORDPRESS_DB_PASSWORD}
      TZ: ${TIMEZONE}
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
        PHP_VERSION: ${PHP_VERSION:-8.3}
    container_name: ${COMPOSE_PROJECT_NAME}_wordpress
    restart: unless-stopped
    depends_on:
      mariadb:
        condition: service_healthy
    environment:
      WORDPRESS_DB_HOST: mariadb:3306
      WORDPRESS_DB_NAME: ${WORDPRESS_DB_NAME}
      WORDPRESS_DB_USER: ${WORDPRESS_DB_USER}
      WORDPRESS_DB_PASSWORD: ${WORDPRESS_DB_PASSWORD}
      WORDPRESS_TABLE_PREFIX: ${WORDPRESS_TABLE_PREFIX}
      WORDPRESS_DEBUG: 0
      TZ: ${TIMEZONE}
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
    container_name: ${COMPOSE_PROJECT_NAME}_nginx
    restart: unless-stopped
    depends_on:
      - wordpress
    ports:
      - "${NGINX_HTTP_PORT:-80}:80"
      - "${NGINX_HTTPS_PORT:-443}:443"
    environment:
      DOMAIN_NAME: ${DOMAIN_NAME}
      TZ: ${TIMEZONE}
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

networks:
  wordpress-network:
    driver: bridge

volumes:
  mariadb_data:
  wordpress_data:
'@
New-ProjectFile "docker-compose.yml" $compose

# 4) nginx Dockerfile (alpine)
$nginxDocker = @'
FROM nginx:alpine
RUN apk add --no-cache openssl curl
RUN mkdir -p /var/log/nginx /var/cache/nginx
COPY nginx.conf /etc/nginx/nginx.conf
COPY conf.d/ /etc/nginx/conf.d/
EXPOSE 80 443
CMD ["nginx","-g","daemon off;"]
'@
New-ProjectFile "nginx\Dockerfile" $nginxDocker

# 5) nginx.conf (small, secure, cached)
$nginxConf = @'
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

  log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                  '$status $body_bytes_sent "$http_referer" '
                  '"$http_user_agent" "$http_x_forwarded_for"';
  access_log /var/log/nginx/access.log main;

  sendfile on;
  tcp_nopush on;
  tcp_nodelay on;
  keepalive_timeout 65;
  types_hash_max_size 2048;

  client_max_body_size 256M;
  client_body_buffer_size 128k;
  client_body_timeout 60s;
  client_header_timeout 60s;
  send_timeout 60s;

  gzip on;
  gzip_vary on;
  gzip_proxied any;
  gzip_comp_level 6;
  gzip_types text/plain text/css text/xml text/javascript application/json application/javascript application/xml+rss;
  gzip_disable "msie6";
  gzip_min_length 256;

  add_header X-Frame-Options "SAMEORIGIN" always;
  add_header X-Content-Type-Options "nosniff" always;
  add_header X-XSS-Protection "0" always;
  add_header Referrer-Policy "no-referrer-when-downgrade" always;
  server_tokens off;

  limit_req_zone $binary_remote_addr zone=wp_login:10m rate=2r/s;
  limit_req_zone $binary_remote_addr zone=wp_admin:10m rate=10r/s;
  limit_conn_zone $binary_remote_addr zone=addr:10m;

  fastcgi_cache_path /var/cache/nginx levels=1:2 keys_zone=WORDPRESS:100m inactive=60m max_size=512m;
  fastcgi_cache_key "$scheme$request_method$host$request_uri";
  fastcgi_cache_use_stale error timeout invalid_header http_500 http_503;
  fastcgi_cache_valid 200 301 302 60m;
  fastcgi_cache_valid 404 10m;

  include /etc/nginx/conf.d/*.conf;
}
'@
New-ProjectFile "nginx\nginx.conf" $nginxConf

# 6) nginx site (WordPress + SSL + cache)
$nginxSite = @'
upstream php-fpm { server wordpress:9000; keepalive 32; }

server {
  listen 80; listen [::]:80;
  server_name localhost localhost.local;
  location ^~ /.well-known/acme-challenge/ { allow all; root /var/www/html; }
  return 301 https://$host$request_uri;
}

server {
  listen 443 ssl http2; listen [::]:443 ssl http2;
  server_name localhost localhost.local;

  root /var/www/html;
  index index.php index.html;

  ssl_certificate /etc/nginx/ssl/cert.pem;
  ssl_certificate_key /etc/nginx/ssl/key.pem;
  ssl_protocols TLSv1.2 TLSv1.3;
  ssl_ciphers 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384';
  ssl_prefer_server_ciphers on;
  ssl_session_cache shared:SSL:10m;
  ssl_session_timeout 10m;
  ssl_session_tickets off;

  access_log /var/log/nginx/wordpress-access.log;
  error_log  /var/log/nginx/wordpress-error.log;

  limit_conn addr 10;

  location / { try_files $uri $uri/ /index.php?$args; }

  location ~ /\. { deny all; access_log off; log_not_found off; }
  location = /xmlrpc.php { deny all; access_log off; log_not_found off; }
  location = /readme.html { deny all; }
  location = /license.txt { deny all; }
  location ~* wp-config.php { deny all; }

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

  location ~ \.php$ {
    try_files $uri =404;

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

  location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg|woff|woff2|ttf|eot)$ {
    expires 30d;
    add_header Cache-Control "public, immutable";
    access_log off;
  }

  location ~* /(?:uploads|files)/.*\.php$ { deny all; }
  location ~ /\.(?!well-known) { deny all; }
}
'@
New-ProjectFile "nginx\conf.d\default.conf" $nginxSite

# 7) PHP Dockerfile (wordpress:phpX-fpm-alpine)
$phpDocker = @'
ARG PHP_VERSION=8.3
FROM wordpress:php${PHP_VERSION}-fpm-alpine

RUN apk add --no-cache libzip-dev zip unzip git bash fcgi imagemagick imagemagick-libs libgomp
RUN docker-php-ext-install opcache zip exif

RUN apk add --no-cache --virtual .build-deps $PHPIZE_DEPS \
 && pecl install redis \
 && docker-php-ext-enable redis \
 && apk del .build-deps

RUN apk add --no-cache --virtual .imagick-deps $PHPIZE_DEPS imagemagick-dev libtool \
 && git clone https://github.com/Imagick/imagick.git --depth 1 /tmp/imagick \
 && cd /tmp/imagick && phpize && ./configure && make && make install \
 && docker-php-ext-enable imagick \
 && rm -rf /tmp/imagick && apk del .imagick-deps

RUN echo '#!/bin/sh' > /usr/local/bin/php-fpm-healthcheck \
 && echo 'SCRIPT_NAME=/ping SCRIPT_FILENAME=/ping REQUEST_METHOD=GET cgi-fcgi -bind -connect 127.0.0.1:9000 || exit 1' >> /usr/local/bin/php-fpm-healthcheck \
 && chmod +x /usr/local/bin/php-fpm-healthcheck

RUN mkdir -p /var/log/php && chown www-data:www-data /var/log/php

COPY php.ini /usr/local/etc/php/conf.d/custom.ini
COPY php-fpm.conf /usr/local/etc/php-fpm.d/zz-custom.conf

WORKDIR /var/www/html
EXPOSE 9000
CMD ["php-fpm"]
'@
New-ProjectFile "php\Dockerfile" $phpDocker

# 8) php.ini (small + safe + fast)
$phpIni = @'
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
error_reporting = E_ALL & ~E_DEPRECATED & ~E_STRICT

session.save_handler = files
session.save_path = "/tmp"
session.gc_maxlifetime = 3600
session.cookie_httponly = 1
session.cookie_secure = 1
session.use_strict_mode = 1

expose_php = Off
allow_url_fopen = On
allow_url_include = Off
disable_functions = exec,passthru,shell_exec,system,proc_open,popen,curl_exec,curl_multi_exec,parse_ini_file,show_source

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

realpath_cache_size = 4096K
realpath_cache_ttl = 600

file_uploads = On
max_file_uploads = 20
date.timezone = UTC

mysqli.default_socket = /var/run/mysqld/mysqld.sock
'@
New-ProjectFile "php\php.ini" $phpIni

# 9) php-fpm.conf (balanced defaults)
$phpFpm = @'
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
'@
New-ProjectFile "php\php-fpm.conf" $phpFpm

# 10) MariaDB my.cnf (utf8mb4 + sane buffers)
$mariaCnf = @'
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
interactive_timeout = 600

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
'@
New-ProjectFile "mariadb\my.cnf" $mariaCnf

# 11) MariaDB init.sql (optional hooks)
$mariaInit = @'
-- Init script hook; add custom DB/users/grants as needed.
OPTIMIZE TABLE mysql.user;
OPTIMIZE TABLE mysql.db;
FLUSH PRIVILEGES;
SHOW DATABASES;
'@
New-ProjectFile "mariadb\init\init.sql" $mariaInit

# 12) .gitignore (keep secrets/large files out of git)
$gitignore = @'
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
$RECYCLE.BIN/
.vscode/
.idea/
*.swp
*.swo
*~
tmp/
temp/
*.tmp
'@
New-ProjectFile ".gitignore" $gitignore

# 13) scripts\start.ps1 (start stack)
$startPs1 = @'
$ErrorActionPreference = "Stop"
Write-Host "`nStarting WordPress Docker..." -ForegroundColor Cyan
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root
docker-compose up -d
if ($LASTEXITCODE -ne 0) { Write-Host "Start failed" -ForegroundColor Red; exit 1 }
docker-compose ps
Write-Host "`nWordPress:  https://localhost.local"
Write-Host "phpMyAdmin: http://localhost:8080`n"
'@
New-ProjectFile "scripts\start.ps1" $startPs1

# 14) scripts\stop.ps1 (stop stack)
$stopPs1 = @'
$ErrorActionPreference = "Stop"
Write-Host "`nStopping WordPress Docker..." -ForegroundColor Cyan
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root
docker-compose stop
Write-Host "Stopped.`n"
'@
New-ProjectFile "scripts\stop.ps1" $stopPs1

# 15) scripts\logs.ps1 (view logs)
$logsPs1 = @'
param([ValidateSet("all","nginx","wordpress","mariadb","phpmyadmin")][string]$Service="all",[int]$Lines=100,[switch]$Follow)
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root
if ($Follow) { if ($Service -eq "all") { docker-compose logs -f } else { docker-compose logs -f $Service } }
else { if ($Service -eq "all") { docker-compose logs --tail=$Lines } else { docker-compose logs --tail=$Lines $Service } }
'@
New-ProjectFile "scripts\logs.ps1" $logsPs1

# 16) scripts\backup.ps1 (DB + files + configs archive)
$backupPs1 = @'
$ErrorActionPreference = "Stop"
Write-Host "`nWordPress Backup" -ForegroundColor Cyan
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root
# load .env
Get-Content ".env" | ? {$_ -match '^\s*([^#][^=]+)=(.+)$'} | % { Set-Item -Path ("env:{0}" -f $matches[1].Trim()) -Value ($matches[2].Trim()) }
$date = Get-Date -Format "yyyyMMdd_HHmmss"
$backupName = "wordpress_backup_$date"
$prefix = if ($env:COMPOSE_PROJECT_NAME) { $env:COMPOSE_PROJECT_NAME } else { "wordpress-docker" }
$dest = Join-Path $root ("backups\{0}" -f $backupName)
New-Item -ItemType Directory -Path $dest -Force | Out-Null

Write-Host "Dumping DB..."
$dbFile = Join-Path $dest "database.sql"
docker exec "$prefix`_mariadb" mysqldump -u root -p"$env:MYSQL_ROOT_PASSWORD" --single-transaction --quick --lock-tables=false --routines --triggers --events "$env:WORDPRESS_DB_NAME" | Out-File -FilePath $dbFile -Encoding UTF8

Write-Host "Archiving WP files..."
docker run --rm --volumes-from "$prefix`_wordpress" -v "$dest`:/backup" alpine tar czf /backup/wordpress_files.tar.gz -C /var/www/html .

Write-Host "Archiving configs..."
$temp = Join-Path $env:TEMP ("wp-cfg-{0}" -f $date)
New-Item -ItemType Directory -Path $temp -Force | Out-Null
Copy-Item nginx\conf.d -Destination (Join-Path $temp "nginx-conf.d") -Recurse
Copy-Item php\php.ini -Destination $temp
Copy-Item php\php-fpm.conf -Destination $temp
Copy-Item mariadb\my.cnf -Destination $temp
Copy-Item .env -Destination $temp
docker run --rm -v "$temp`:/src" -v "$dest`:/backup" alpine tar czf /backup/config_files.tar.gz -C /src .
Remove-Item $temp -Recurse -Force

Write-Host "Compressing..."
$zip = "$dest.zip"
Compress-Archive -Path "$dest\*" -DestinationPath $zip -Force
Remove-Item $dest -Recurse -Force
$size = [math]::Round((Get-Item $zip).Length/1MB,2)
Write-Host "Backup: $zip ($size MB)`n" -ForegroundColor Green
'@
New-ProjectFile "scripts\backup.ps1" $backupPs1

# 17) scripts\ssl-setup.ps1 (silent OpenSSL, separate stdout/stderr)
$sslPs1 = @'
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$ssl = Join-Path $root "ssl"
Set-Location $ssl
$opensslPaths = @(
  "C:\Program Files\Git\usr\bin\openssl.exe",
  "C:\Program Files (x86)\Git\usr\bin\openssl.exe",
  "C:\Program Files\OpenSSL-Win64\bin\openssl.exe",
  "C:\OpenSSL-Win64\bin\openssl.exe"
)
$openssl = $null
foreach ($p in $opensslPaths) { if (Test-Path $p) { $openssl = $p; break } }
if (-not $openssl) { Write-Host "OpenSSL not found (install Git for Windows)" -ForegroundColor Yellow; exit 1 }

if ((Test-Path "cert.pem") -and (Test-Path "key.pem")) {
  $r = Read-Host "SSL exists, regenerate? (y/n)"
  if ($r -ne "y") { Write-Host "Using existing SSL"; exit 0 } else { Remove-Item cert.pem,key.pem -Force -ErrorAction SilentlyContinue }
}

$out = Join-Path $env:TEMP ("ossl_out_{0}.txt" -f (Get-Random))
$err = Join-Path $env:TEMP ("ossl_err_{0}.txt" -f (Get-Random))
$args = @("req","-x509","-nodes","-days","365","-newkey","rsa:2048","-keyout","key.pem","-out","cert.pem","-subj","/CN=localhost.local","-addext","subjectAltName=DNS:localhost,DNS:localhost.local,IP:127.0.0.1")
$proc = Start-Process -FilePath $openssl -ArgumentList $args -NoNewWindow -Wait -PassThru -RedirectStandardOutput $out -RedirectStandardError $err
if ((Test-Path "cert.pem") -and (Test-Path "key.pem")) { Write-Host "SSL generated" -ForegroundColor Green } else { Write-Host "SSL generation warning" -ForegroundColor Yellow }
Remove-Item $out,$err -Force -ErrorAction SilentlyContinue
'@
New-ProjectFile "scripts\ssl-setup.ps1" $sslPs1

# 18) quick-start.ps1 (checks + silent SSL + build + up)
$qs = @'
$ErrorActionPreference = "Stop"
Write-Host "`n== WordPress Docker Quick Setup ==" -ForegroundColor Cyan
$root = $PSScriptRoot
# .env check
$envTxt = Get-Content (Join-Path $root ".env") -Raw
if ($envTxt -match "ChangeThisPassword") { Write-Host "Edit .env to set strong passwords, then re-run." -ForegroundColor Red; exit 1 }
# Docker check
try { $null = docker ps 2>&1 } catch { Write-Host "Start Docker Desktop first." -ForegroundColor Red; exit 1 }
# SSL
& (Join-Path $root "scripts\ssl-setup.ps1")
# hosts file
$hosts = "$env:SystemRoot\System32\drivers\etc\hosts"
try {
  $h = Get-Content $hosts -Raw
  if ($h -notmatch "localhost\.local") {
    $admin = (New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if ($admin) { Add-Content -Path $hosts -Value "`n127.0.0.1`tlocalhost.local" } else { Write-Host "Add to hosts: 127.0.0.1    localhost.local" -ForegroundColor Yellow }
  }
} catch {}
# Build + up
Set-Location $root
Write-Host "`nBuilding images (first run ~5-10 min)..." -ForegroundColor Cyan
docker-compose build
if ($LASTEXITCODE -ne 0) { Write-Host "Build failed" -ForegroundColor Red; exit 1 }
Write-Host "Starting containers..." -ForegroundColor Cyan
docker-compose up -d
if ($LASTEXITCODE -ne 0) { Write-Host "Start failed" -ForegroundColor Red; exit 1 }
Start-Sleep -Seconds 8
docker-compose ps
Write-Host "`nOpen: https://localhost.local  (accept SSL warning)" -ForegroundColor Green
Write-Host "Admin: https://localhost.local/wp-admin" -ForegroundColor Green
Write-Host "DB UI: http://localhost:8080`n" -ForegroundColor Green
'@
New-ProjectFile "quick-start.ps1" $qs

# 19) README minimal
$readme = @'
# WordPress Docker (Alpine)
- Nginx Alpine, PHP 8.3-FPM Alpine, MariaDB 11.6, phpMyAdmin. 
- Edit .env, then run: .\quick-start.ps1. 
- Start/Stop/Logs/Backup in scripts\ folder. 
'@
New-ProjectFile "README.md" $readme

Write-Host "`nAll files created successfully."
Write-Host "Next: Edit .env, then run .\quick-start.ps1"
```

### Why Alpine and these versions
- The official nginx images provide an Alpine variant optimized for container use and small footprint, reducing download and memory cost for local development.[2][1]
- WordPress runs well on the php-fpm Alpine variant when paired with Nginx, which keeps the image lean while providing PHP 8.3 and required extensions.[4]
- MariaDB 11.6 is a current stable GA rolling release line per MariaDB release notes, making it a safe, modern choice for WordPress in 2025.[3][5]
- The Nginx configuration model (nginx.conf + conf.d/*.conf) aligns with upstream documentation and official image practices.[6][1]

***

## Installation Guide (Windows 11 + Docker Desktop)

### Prerequisites
- Install Docker Desktop for Windows 11 and ensure WSL 2 backend is enabled before continuing.[1]
- Install Git for Windows to get OpenSSL at C:\Program Files\Git\usr\bin\openssl.exe for certificate generation.[2]

### One-time setup
- Create the project folder C:\wordpress-docker and save the mega script above as create-files.ps1 in that folder.[1]
- Open PowerShell (Run as Administrator recommended), run Set-ExecutionPolicy RemoteSigned -Scope CurrentUser once to allow scripts.[6]
- Run .\create-files.ps1 to generate all configs, Dockerfiles, and scripts.[1]
- Open .env and change all passwords (WORDPRESS_DB_PASSWORD, MYSQL_ROOT_PASSWORD, WORDPRESS_ADMIN_PASSWORD, and admin username).[4]
- Run .\quick-start.ps1 to generate SSL silently, update hosts, build images, and start containers.[2]

### Access
- Site: https://localhost.local (accept self‑signed SSL warning on first visit).[6]
- Admin: https://localhost.local/wp-admin using the credentials defined in .env after first‑time WordPress setup.[4]
- phpMyAdmin: http://localhost:8080 with server mariadb and root password from .env MYSQL_ROOT_PASSWORD.[3]

### Daily commands
- Start: .\scripts\start.ps1 for running all containers in the background quickly.[1]
- Stop: .\scripts\stop.ps1 for cleanly stopping the services without removing volumes.[1]
- Logs: .\scripts\logs.ps1 -Service nginx|wordpress|mariadb -Lines 200 -Follow for troubleshooting. [6]
- Backup: .\scripts\backup.ps1 to create a timestamped ZIP with DB dump, files, and configs in backups\.[3]

### Editing configs
- Nginx: edit nginx\nginx.conf and nginx\conf.d\default.conf, then docker-compose restart nginx to apply.[1]
- PHP: edit php\php.ini or php\php-fpm.conf, then docker-compose restart wordpress to reload.[4]
- MariaDB: edit mariadb\my.cnf, then docker-compose restart mariadb to reconfigure.[3]
- Ports and domain: edit .env for NGINX_HTTP_PORT, NGINX_HTTPS_PORT, PHPMYADMIN_PORT, and DOMAIN_NAME, then docker-compose down && docker-compose up -d.[1]

### Notes on images and compatibility
- nginx:alpine is the smallest official Nginx variant and is widely recommended for container builds due to its minimal base and robust package repository.[2][1]
- wordpress:php8.3-fpm-alpine pairs with Nginx via FastCGI (not Apache), following standard Nginx + FPM architecture for WordPress in containers.[4]
- MariaDB 11.6.x is GA in the rolling line and supports utf8mb4 out of the box, aligning with modern WordPress defaults.[5][3]

### SSL behavior and fix
- The quick-start and ssl-setup scripts use Start-Process with separate stdout/stderr redirection to fully silence OpenSSL’s progress output while creating cert.pem and key.pem in ssl\.[6]

### Troubleshooting
- If ports 80/443/8080 are busy, change NGINX_HTTP_PORT/HTTPS/PHPMYADMIN_PORT in .env and re‑create the stack.[1]
- If https://localhost.local warns about SSL, install Git for Windows to ensure OpenSSL exists and rerun quick-start to regenerate the self‑signed cert silently.[2]
- If WordPress shows “Bad Gateway”, check docker-compose logs nginx and ensure the wordpress container is healthy and reachable on port 9000.[6]
- For slow performance, verify OPcache is enabled in php.ini and FastCGI cache headers show HIT after first request to cached pages.[4]

This setup uses official images and patterns that are standard for Dockerized WordPress with Nginx and PHP‑FPM, keeping images small, builds fast, and configuration clean on Windows 11 with Docker Desktop.[3][2][4][1]

[1](https://hub.docker.com/_/nginx)
[2](https://hub.docker.com/_/alpine)
[3](https://mariadb.com/docs/release-notes/community-server/old-releases/release-notes-mariadb-11-6-rolling-releases/what-is-mariadb-116)
[4](https://www.digitalocean.com/community/tutorials/how-to-install-wordpress-with-docker-compose)
[5](https://mariadb.com/docs/release-notes/community-server/old-releases/release-notes-mariadb-11-6-rolling-releases/mariadb-11-6-2-release-notes)
[6](https://nginx.org/en/docs/)
[7](https://docs.nginx.com/nginx/admin-guide/installing-nginx/installing-nginx-docker/)
[8](https://github.com/nginx/docker-nginx)
[9](https://octopus.com/blog/using-nginx-docker-image)
[10](https://forums.docker.com/t/alpine-image-editor-module-not-working/127761)
[11](https://github.com/thbe/docker-nginx)
[12](https://github.com/Saboteur777/wordpress-php-docker)
[13](https://mariadb.org/tag/mariadb-11-6/)
[14](https://docs.nginx.com/waf/install/docker/)
[15](https://stackoverflow.com/questions/75921203/docker-compose-with-wordpressphp8-2-fpm-alpine-returning-err-empty-response)
[16](https://mariadb.com/docs/release-notes/community-server/old-releases/release-notes-mariadb-11-6-rolling-releases/mariadb-11-6-0-release-notes)
[17](https://stackoverflow.com/questions/55270099/how-do-i-build-a-custom-nginxalpine-based-container-listening-on-port-other-tha)
[18](https://stackoverflow.com/questions/78256616/wordpress-docker-application-with-php-fpm-8-3-based-on-alpine-linux-not-loading)
[19](https://mariadb.com/docs/release-notes/community-server/old-releases/release-notes-mariadb-11-6-rolling-releases/mariadb-11-6-1-release-notes)
[20](https://dockerfile.readthedocs.io/en/latest/content/DockerImages/dockerfiles/php-nginx.html)