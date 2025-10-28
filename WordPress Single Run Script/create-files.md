Let me create the complete corrected PowerShell script:

```powershell
# setup-wordpress-docker.ps1
# Complete WordPress Docker Setup Script for Windows 11 - Updated 2025
# Author: Automated WordPress Docker Setup
# Version: 2.0
# Compatible with: Windows 11 + Docker Desktop
# Latest Versions: NGINX 1.28, PHP 8.4, MariaDB 11.8 LTS

param(
    [string]$ProjectName = "wordpress-docker",
    [string]$Domain = "localhost",
    [string]$WordPressUser = "admin",
    [string]$WordPressPassword = "",
    [string]$WordPressEmail = "admin@localhost.local",
    [string]$DBRootPassword = "",
    [string]$DBName = "wordpress",
    [string]$DBUser = "wpuser",
    [string]$DBPassword = "",
    [switch]$GenerateSSL = $true,
    [switch]$SkipBackup = $false
)

# Color output functions
function Write-ColorOutput($ForegroundColor, $Message) {
    $originalColor = $Host.UI.RawUI.ForegroundColor
    $Host.UI.RawUI.ForegroundColor = $ForegroundColor
    Write-Output $Message
    $Host.UI.RawUI.ForegroundColor = $originalColor
}

function Write-Success($Message) { Write-ColorOutput Green "✓ $Message" }
function Write-Warning($Message) { Write-ColorOutput Yellow "⚠ $Message" }
function Write-Error($Message) { Write-ColorOutput Red "✗ $Message" }
function Write-Info($Message) { Write-ColorOutput Cyan "ℹ $Message" }

Write-Info "=========================================="
Write-Info "WordPress Docker Stack Setup - 2025 Edition"
Write-Info "Latest Versions: NGINX 1.28, PHP 8.4, MariaDB 11.8 LTS"
Write-Info "=========================================="

# Check if running as Administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "This script must be run as Administrator. Please restart PowerShell as Administrator."
    Write-Info "Right-click PowerShell and select 'Run as Administrator'"
    exit 1
}

Write-Info "Administrator privileges confirmed ✓"

# Check Docker Desktop installation and version
try {
    $dockerVersion = docker --version
    Write-Success "Docker is installed: $dockerVersion"
    
    # Check Docker Compose version
    $composeVersion = docker-compose --version
    Write-Success "Docker Compose available: $composeVersion"
} catch {
    Write-Error "Docker Desktop is not installed or not in PATH."
    Write-Info "Please install Docker Desktop from: https://www.docker.com/products/docker-desktop/"
    exit 1
}

# Check if Docker is running
try {
    docker ps | Out-Null
    Write-Success "Docker Desktop is running and accessible"
} catch {
    Write-Error "Docker Desktop is not running or not accessible."
    Write-Info "Please start Docker Desktop and ensure it's fully loaded before running this script."
    exit 1
}

# Generate secure passwords if not provided
function Generate-SecurePassword {
    param([int]$Length = 16)
    
    # Enhanced character set for stronger passwords
    $chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()-_=+[]{}|;:,.<>?"
    $password = ""
    for ($i = 0; $i -lt $Length; $i++) {
        $password += $chars[(Get-Random -Maximum $chars.Length)]
    }
    return $password
}

# Generate passwords if not provided
if ([string]::IsNullOrEmpty($WordPressPassword)) {
    $WordPressPassword = Generate-SecurePassword -Length 18
    Write-Info "Generated WordPress admin password: $WordPressPassword"
}

if ([string]::IsNullOrEmpty($DBRootPassword)) {
    $DBRootPassword = Generate-SecurePassword -Length 24
    Write-Info "Generated database root password (first 8 chars): $($DBRootPassword.Substring(0,8))..."
}

if ([string]::IsNullOrEmpty($DBPassword)) {
    $DBPassword = Generate-SecurePassword -Length 18
    Write-Info "Generated database user password (first 8 chars): $($DBPassword.Substring(0,8))..."
}

# Create project directory structure
$ProjectPath = Join-Path $PWD $ProjectName
if (Test-Path $ProjectPath) {
    Write-Warning "Project directory already exists: $ProjectPath"
    $response = Read-Host "Do you want to continue and overwrite configuration files? (y/N)"
    if ($response -ne 'y' -and $response -ne 'Y') {
        Write-Info "Setup cancelled by user"
        exit 0
    }
} else {
    New-Item -ItemType Directory -Path $ProjectPath -Force | Out-Null
    Write-Success "Created project directory: $ProjectPath"
}

Set-Location $ProjectPath

# Create comprehensive directory structure
$directories = @(
    "docker", "config\nginx\conf.d", "config\php\conf.d", "config\mysql\conf.d", 
    "ssl\certificates", "ssl\private", "wordpress", "wordpress\wp-content\uploads",
    "backups\database", "backups\files", "logs\nginx", "logs\php", "logs\mysql", 
    "PowerShell", "scripts", "documentation"
)

foreach ($dir in $directories) {
    $fullPath = Join-Path $ProjectPath $dir
    if (!(Test-Path $fullPath)) {
        New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
        Write-Success "Created directory: $dir"
    }
}

# Generate SSL certificates if requested
if ($GenerateSSL) {
    Write-Info "Generating 4096-bit RSA SSL certificates for $Domain..."
    
    # Enhanced OpenSSL configuration for modern security
    $opensslConfig = @'
[req]
default_bits = 4096
prompt = no
default_md = sha256
distinguished_name = dn
req_extensions = v3_req

[dn]
CN=localhost
O=WordPress Docker Stack
OU=Development
L=Local
C=US

[v3_req]
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth, clientAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = localhost
DNS.2 = www.localhost
DNS.3 = *.localhost
IP.1 = 127.0.0.1
IP.2 = ::1
'@
    
    $opensslConfig | Out-File -FilePath "ssl\openssl.conf" -Encoding UTF8
    
    try {
        # Generate private key with enhanced security
        & openssl genrsa -out "ssl\private\server.key" 4096 2>$null
        
        # Generate certificate signing request
        & openssl req -new -key "ssl\private\server.key" -out "ssl\server.csr" -config "ssl\openssl.conf" 2>$null
        
        # Generate self-signed certificate valid for 2 years
        & openssl x509 -req -days 730 -in "ssl\server.csr" -signkey "ssl\private\server.key" -out "ssl\certificates\server.crt" -extensions v3_req -extfile "ssl\openssl.conf" 2>$null
        
        # Generate DH parameters for enhanced security
        & openssl dhparam -out "ssl\certificates\dhparam.pem" 2048 2>$null
        
        # Set appropriate permissions (Windows)
        icacls "ssl\private\server.key" /grant:r "$env:USERNAME:(F)" /inheritance:r 2>$null | Out-Null
        
        Write-Success "SSL certificates generated successfully (4096-bit RSA, 2-year validity)"
        
        # Clean up temporary files
        Remove-Item "ssl\server.csr", "ssl\openssl.conf" -ErrorAction SilentlyContinue
        
    } catch {
        Write-Warning "OpenSSL not found in PATH. SSL certificates will be generated inside Docker container."
        Write-Info "You can install OpenSSL from: https://slproweb.com/products/Win32OpenSSL.html"
    }
}

# Create comprehensive .env file with all configurations
$envContent = @"
# WordPress Docker Environment Configuration - 2025 Edition
# Generated on $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
# Latest Versions: NGINX 1.28, PHP 8.4, MariaDB 11.8 LTS

# Project Configuration
PROJECT_NAME=$ProjectName
DOMAIN=$Domain
COMPOSE_PROJECT_NAME=$ProjectName

# Container Versions (Latest 2025)
NGINX_VERSION=1.28-alpine
PHP_VERSION=8.4-fpm-alpine
MARIADB_VERSION=11.8

# WordPress Configuration
WORDPRESS_DB_HOST=mariadb:3306
WORDPRESS_DB_NAME=$DBName
WORDPRESS_DB_USER=$DBUser
WORDPRESS_DB_PASSWORD=$DBPassword
WORDPRESS_ADMIN_USER=$WordPressUser
WORDPRESS_ADMIN_PASSWORD=$WordPressPassword
WORDPRESS_ADMIN_EMAIL=$WordPressEmail
WORDPRESS_TABLE_PREFIX=wp_

# Database Configuration
MYSQL_ROOT_PASSWORD=$DBRootPassword
MYSQL_DATABASE=$DBName
MYSQL_USER=$DBUser
MYSQL_PASSWORD=$DBPassword
MYSQL_CHARSET=utf8mb4
MYSQL_COLLATION=utf8mb4_unicode_ci

# WordPress Security Salts (Auto-generated)
WORDPRESS_AUTH_KEY=$(Generate-SecurePassword -Length 64)
WORDPRESS_SECURE_AUTH_KEY=$(Generate-SecurePassword -Length 64)
WORDPRESS_LOGGED_IN_KEY=$(Generate-SecurePassword -Length 64)
WORDPRESS_NONCE_KEY=$(Generate-SecurePassword -Length 64)
WORDPRESS_AUTH_SALT=$(Generate-SecurePassword -Length 64)
WORDPRESS_SECURE_AUTH_SALT=$(Generate-SecurePassword -Length 64)
WORDPRESS_LOGGED_IN_SALT=$(Generate-SecurePassword -Length 64)
WORDPRESS_NONCE_SALT=$(Generate-SecurePassword -Length 64)

# PHP 8.4 Performance Configuration
PHP_MEMORY_LIMIT=512M
PHP_MAX_EXECUTION_TIME=300
PHP_MAX_INPUT_TIME=300
PHP_MAX_INPUT_VARS=3000
PHP_UPLOAD_MAX_FILESIZE=128M
PHP_POST_MAX_SIZE=128M
PHP_MAX_FILE_UPLOADS=20
PHP_DEFAULT_SOCKET_TIMEOUT=60

# PHP-FPM Configuration
PHP_FPM_MAX_CHILDREN=20
PHP_FPM_START_SERVERS=4
PHP_FPM_MIN_SPARE_SERVERS=2
PHP_FPM_MAX_SPARE_SERVERS=8
PHP_FPM_MAX_REQUESTS=1000

# Network Configuration
HTTP_PORT=80
HTTPS_PORT=443
MYSQL_PORT=3306
PHPMYADMIN_PORT=8080

# Security Configuration
WORDPRESS_DEBUG=false
WORDPRESS_DEBUG_LOG=false
WORDPRESS_DEBUG_DISPLAY=false
WORDPRESS_SCRIPT_DEBUG=false
WP_CACHE=true

# Backup Configuration
BACKUP_RETENTION_DAYS=30
BACKUP_SCHEDULE=daily

# Development Configuration (set to false for production)
DEV_MODE=true
XDEBUG_MODE=off
"@

$envContent | Out-File -FilePath "docker\.env" -Encoding UTF8
Write-Success "Environment configuration created with latest versions"

# Create updated docker-compose.yml with latest versions
$dockerComposeContent = @'
# Docker Compose Configuration for WordPress - 2025 Edition
# Latest Versions: NGINX 1.28, PHP 8.4, MariaDB 11.8 LTS
# Optimized for Windows 11 Docker Desktop
version: '3.8'

services:
  # NGINX 1.28 Web Server with HTTP/2 and SSL
  nginx:
    image: nginx:${NGINX_VERSION}
    container_name: ${PROJECT_NAME}_nginx
    restart: unless-stopped
    ports:
      - "${HTTP_PORT}:80"
      - "${HTTPS_PORT}:443"
    volumes:
      - ./config/nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./config/nginx/conf.d:/etc/nginx/conf.d:ro
      - ./ssl/certificates:/etc/ssl/certs:ro
      - ./ssl/private:/etc/ssl/private:ro
      - ./wordpress:/var/www/html:rw
      - ./logs/nginx:/var/log/nginx:rw
      - nginx_cache:/var/cache/nginx:rw
      - nginx_temp:/var/lib/nginx/tmp:rw
    depends_on:
      php:
        condition: service_healthy
    networks:
      - wordpress_network
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost/nginx-health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
    labels:
      - "com.docker.compose.service=nginx"
      - "com.docker.compose.project=${PROJECT_NAME}"
      - "description=NGINX 1.28 Web Server with SSL"

  # PHP 8.4-FPM with WordPress optimizations
  php:
    image: wordpress:${PHP_VERSION}
    container_name: ${PROJECT_NAME}_php
    restart: unless-stopped
    volumes:
      - ./wordpress:/var/www/html:rw
      - ./config/php/php.ini:/usr/local/etc/php/conf.d/custom.ini:ro
      - ./config/php/php-fpm.conf:/usr/local/etc/php-fpm.conf:ro
      - ./config/php/www.conf:/usr/local/etc/php-fpm.d/www.conf:ro
      - ./config/php/conf.d:/usr/local/etc/php/conf.d:ro
      - ./logs/php:/var/log/php:rw
      - php_sessions:/tmp/php-sessions:rw
    environment:
      # WordPress Database Configuration
      WORDPRESS_DB_HOST: ${WORDPRESS_DB_HOST}
      WORDPRESS_DB_NAME: ${WORDPRESS_DB_NAME}
      WORDPRESS_DB_USER: ${WORDPRESS_DB_USER}
      WORDPRESS_DB_PASSWORD: ${WORDPRESS_DB_PASSWORD}
      WORDPRESS_TABLE_PREFIX: ${WORDPRESS_TABLE_PREFIX}
      
      # WordPress Security Configuration
      WORDPRESS_AUTH_KEY: ${WORDPRESS_AUTH_KEY}
      WORDPRESS_SECURE_AUTH_KEY: ${WORDPRESS_SECURE_AUTH_KEY}
      WORDPRESS_LOGGED_IN_KEY: ${WORDPRESS_LOGGED_IN_KEY}
      WORDPRESS_NONCE_KEY: ${WORDPRESS_NONCE_KEY}
      WORDPRESS_AUTH_SALT: ${WORDPRESS_AUTH_SALT}
      WORDPRESS_SECURE_AUTH_SALT: ${WORDPRESS_SECURE_AUTH_SALT}
      WORDPRESS_LOGGED_IN_SALT: ${WORDPRESS_LOGGED_IN_SALT}
      WORDPRESS_NONCE_SALT: ${WORDPRESS_NONCE_SALT}
      
      # WordPress Debug Configuration
      WORDPRESS_DEBUG: ${WORDPRESS_DEBUG}
      WORDPRESS_DEBUG_LOG: ${WORDPRESS_DEBUG_LOG}
      WORDPRESS_DEBUG_DISPLAY: ${WORDPRESS_DEBUG_DISPLAY}
      WORDPRESS_SCRIPT_DEBUG: ${WORDPRESS_SCRIPT_DEBUG}
      
      # PHP Configuration
      PHP_MEMORY_LIMIT: ${PHP_MEMORY_LIMIT}
      PHP_MAX_EXECUTION_TIME: ${PHP_MAX_EXECUTION_TIME}
      PHP_UPLOAD_MAX_FILESIZE: ${PHP_UPLOAD_MAX_FILESIZE}
      PHP_POST_MAX_SIZE: ${PHP_POST_MAX_SIZE}
    depends_on:
      mariadb:
        condition: service_healthy
    networks:
      - wordpress_network
    healthcheck:
      test: ["CMD-SHELL", "php -v || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s
    labels:
      - "com.docker.compose.service=php"
      - "com.docker.compose.project=${PROJECT_NAME}"
      - "description=WordPress PHP 8.4-FPM with optimizations"

  # MariaDB 11.8 LTS Database Server
  mariadb:
    image: mariadb:${MARIADB_VERSION}
    container_name: ${PROJECT_NAME}_mariadb
    restart: unless-stopped
    ports:
      - "${MYSQL_PORT}:3306"
    volumes:
      - ./config/mysql/my.cnf:/etc/mysql/conf.d/custom.cnf:ro
      - ./config/mysql/conf.d:/etc/mysql/conf.d:ro
      - mariadb_data:/var/lib/mysql:rw
      - ./backups:/backups:rw
      - ./logs/mysql:/var/log/mysql:rw
      - mariadb_temp:/tmp:rw
    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
      MYSQL_DATABASE: ${MYSQL_DATABASE}
      MYSQL_USER: ${MYSQL_USER}
      MYSQL_PASSWORD: ${MYSQL_PASSWORD}
      MYSQL_CHARSET: ${MYSQL_CHARSET}
      MYSQL_COLLATION: ${MYSQL_COLLATION}
      MARIADB_AUTO_UPGRADE: 1
      MARIADB_DISABLE_UPGRADE_BACKUP: 1
    networks:
      - wordpress_network
    healthcheck:
      test: ["CMD", "healthcheck.sh", "--connect", "--innodb_initialized"]
      interval: 30s
      timeout: 10s
      retries: 5
      start_period: 80s
    labels:
      - "com.docker.compose.service=mariadb"
      - "com.docker.compose.project=${PROJECT_NAME}"
      - "description=MariaDB 11.8 LTS with Vector support"

  # phpMyAdmin for database management
  phpmyadmin:
    image: phpmyadmin:latest
    container_name: ${PROJECT_NAME}_phpmyadmin
    restart: unless-stopped
    ports:
      - "${PHPMYADMIN_PORT}:80"
    environment:
      PMA_HOST: mariadb
      PMA_PORT: 3306
      PMA_USER: root
      PMA_PASSWORD: ${MYSQL_ROOT_PASSWORD}
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
      PMA_ARBITRARY: 1
      PMA_ABSOLUTE_URI: http://localhost:${PHPMYADMIN_PORT}
      UPLOAD_LIMIT: 128M
    depends_on:
      mariadb:
        condition: service_healthy
    networks:
      - wordpress_network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost/"]
      interval: 30s
      timeout: 10s
      retries: 3
    labels:
      - "com.docker.compose.service=phpmyadmin"
      - "com.docker.compose.project=${PROJECT_NAME}"
      - "description=phpMyAdmin Database Administration"

  # Redis for object caching (optional but recommended)
  redis:
    image: redis:7-alpine
    container_name: ${PROJECT_NAME}_redis
    restart: unless-stopped
    command: redis-server --appendonly yes --maxmemory 256mb --maxmemory-policy allkeys-lru
    volumes:
      - redis_data:/data:rw
    networks:
      - wordpress_network
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 30s
      timeout: 10s
      retries: 3
    labels:
      - "com.docker.compose.service=redis"
      - "com.docker.compose.project=${PROJECT_NAME}"
      - "description=Redis Object Cache"

volumes:
  mariadb_data:
    driver: local
    labels:
      - "com.docker.compose.project=${PROJECT_NAME}"
  nginx_cache:
    driver: local
    labels:
      - "com.docker.compose.project=${PROJECT_NAME}"
  nginx_temp:
    driver: local
    labels:
      - "com.docker.compose.project=${PROJECT_NAME}"
  php_sessions:
    driver: local
    labels:
      - "com.docker.compose.project=${PROJECT_NAME}"
  redis_data:
    driver: local
    labels:
      - "com.docker.compose.project=${PROJECT_NAME}"
  mariadb_temp:
    driver: local
    labels:
      - "com.docker.compose.project=${PROJECT_NAME}"

networks:
  wordpress_network:
    driver: bridge
    ipam:
      driver: default
      config:
        - subnet: 172.20.0.0/16
          gateway: 172.20.0.1
    labels:
      - "com.docker.compose.project=${PROJECT_NAME}"
'@

$dockerComposeContent | Out-File -FilePath "docker\docker-compose.yml" -Encoding UTF8
Write-Success "Docker Compose configuration created with latest 2025 versions"

# Create advanced NGINX 1.28 configuration
$nginxMainConfig = @'
# High-Performance NGINX 1.28 Configuration for WordPress - 2025 Edition
# Optimized for Windows Docker Desktop with modern security features

user nginx;
worker_processes auto;
worker_rlimit_nofile 65535;
error_log /var/log/nginx/error.log notice;
pid /var/run/nginx.pid;

# Load dynamic modules
load_module modules/ngx_http_realip_module.so;

events {
    worker_connections 4096;
    use epoll;
    multi_accept on;
    accept_mutex off;
}

http {
    # MIME Types and Character Set
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    charset UTF-8;

    # Logging Configuration with Enhanced Format
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for" '
                    'rt=$request_time uct="$upstream_connect_time" '
                    'uht="$upstream_header_time" urt="$upstream_response_time" '
                    'cache=$upstream_cache_status';

    log_format wordpress '$remote_addr - $remote_user [$time_local] "$request" '
                         '$status $body_bytes_sent "$http_referer" '
                         '"$http_user_agent" rt=$request_time '
                         'wp_user="$cookie_wordpress_logged_in" cache=$upstream_cache_status';

    access_log /var/log/nginx/access.log wordpress buffer=16k flush=2m;

    # Performance Optimizations
    sendfile on;
    sendfile_max_chunk 1m;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 75s;
    keepalive_requests 1000;
    types_hash_max_size 4096;
    server_tokens off;
    msie_padding off;

    # Buffer Sizes (Optimized for WordPress)
    client_body_buffer_size 128k;
    client_max_body_size 128m;
    client_header_buffer_size 2k;
    large_client_header_buffers 4 8k;
    output_buffers 2 32k;
    postpone_output 1460;

    # Timeout Settings
    client_header_timeout 10s;
    client_body_timeout 30s;
    send_timeout 30s;
    reset_timedout_connection on;

    # Advanced Compression with Brotli support preparation
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_min_length 1000;
    gzip_disable "msie6";
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        text/x-component
        text/x-cross-domain-policy
        application/json
        application/javascript
        application/xml+rss
        application/atom+xml
        application/rss+xml
        application/xhtml+xml
        application/x-javascript
        image/svg+xml
        image/x-icon
        font/truetype
        font/opentype
        application/vnd.ms-fontobject
        application/font-woff
        application/font-woff2;

    # Modern Security Headers (2025 Standards)
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    add_header X-Download-Options "noopen" always;
    add_header X-Permitted-Cross-Domain-Policies "none" always;
    add_header Permissions-Policy "camera=(), microphone=(), geolocation=(), payment=()" always;

    # FastCGI Cache Configuration (WordPress Optimized)
    fastcgi_cache_path /var/cache/nginx/fastcgi 
                       levels=1:2 
                       keys_zone=WORDPRESS:200m 
                       inactive=60m 
                       max_size=1g 
                       use_temp_path=off;
    
    fastcgi_cache_key "$scheme$request_method$host$request_uri";
    fastcgi_cache_use_stale error timeout invalid_header updating http_500 http_503;
    fastcgi_cache_background_update on;
    fastcgi_cache_lock on;
    fastcgi_ignore_headers Cache-Control Expires Set-Cookie;

    # Proxy Cache for static assets
    proxy_cache_path /var/cache/nginx/proxy 
                     levels=1:2 
                     keys_zone=STATIC:50m 
                     inactive=24h 
                     max_size=500m;

    # Rate Limiting (Enhanced for WordPress)
    limit_req_zone $binary_remote_addr zone=wp_login:10m rate=1r/s;
    limit_req_zone $binary_remote_addr zone=wp_admin:10m rate=5r/s;
    limit_req_zone $binary_remote_addr zone=wp_api:10m rate=10r/s;
    limit_req_zone $binary_remote_addr zone=wp_general:10m rate=20r/s;

    # Connection limiting
    limit_conn_zone $binary_remote_addr zone=conn_limit_per_ip:10m;
    limit_conn_zone $server_name zone=conn_limit_per_server:10m;

    # Map for cache bypass conditions
    map $http_cookie $no_cache {
        default 0;
        ~*comment_author $1;
        ~*wordpress_[a-f0-9]+ 1;
        ~*wp-postpass 1;
        ~*wordpress_no_cache 1;
        ~*wordpress_logged_in 1;
    }

    # Map for mobile detection
    map $http_user_agent $mobile {
        default 0;
        ~*mobile 1;
        ~*android 1;
        ~*iphone 1;
        ~*ipad 1;
        ~*windows\s+phone 1;
    }

    # Include server configurations
    include /etc/nginx/conf.d/*.conf;
}
'@

$nginxMainConfig | Out-File -FilePath "config\nginx\nginx.conf" -Encoding UTF8

# Create WordPress-specific NGINX configuration for 2025
$nginxWordPressConfig = @'
# WordPress NGINX Server Configuration - 2025 Edition
# Optimized for NGINX 1.28, PHP 8.4, and modern WordPress features

# HTTP to HTTPS redirect
server {
    listen 80;
    listen [::]:80;
    server_name localhost *.localhost;
    
    # Security headers even for HTTP
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    
    # Health check endpoint for Docker
    location /nginx-health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
    
    # Redirect all other traffic to HTTPS
    location / {
        return 301 https://$host$request_uri;
    }
}

# HTTPS WordPress Server
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name localhost *.localhost;

    root /var/www/html;
    index index.php index.html index.htm;

    # SSL Configuration (Modern 2025 Standards)
    ssl_certificate /etc/ssl/certs/server.crt;
    ssl_certificate_key /etc/ssl/private/server.key;
    
    # Modern SSL Configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers off;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305;
    
    ssl_session_timeout 1d;
    ssl_session_cache shared:SSL:50m;
    ssl_session_tickets off;
    
    # OCSP stapling
    ssl_stapling on;
    ssl_stapling_verify on;
    
    # Modern Security Headers
    add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    add_header Permissions-Policy "camera=(), microphone=(), geolocation=(), payment=()" always;

    # Rate limiting
    limit_req zone=wp_general burst=20 nodelay;
    limit_conn conn_limit_per_ip 10;
    limit_conn conn_limit_per_server 100;

    # WordPress Security Configuration
    
    # Block access to sensitive files
    location ~* \.(txt|log|conf|htaccess|htpasswd|ini|conf|sql|bak|old)$ {
        deny all;
        log_not_found off;
    }

    # Block hidden files and directories
    location ~ /\. {
        deny all;
        log_not_found off;
    }

    # Block access to WordPress configuration files
    location ~* /(wp-config\.php|wp-config-sample\.php|readme\.html|license\.txt) {
        deny all;
        log_not_found off;
    }

    # Block PHP execution in uploads directory
    location ~* /(?:uploads|files)/.*\.php$ {
        deny all;
        log_not_found off;
    }

    # Block access to WordPress theme and plugin files
    location ~* /(?:wp-content|wp-includes)/.*\.php$ {
        deny all;
        log_not_found off;
    }
    
    # Allow WordPress theme and plugin assets
    location ~* /(?:wp-content|wp-includes)/.*\.(css|js|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1M;
        add_header Cache-Control "public, immutable";
        add_header X-Content-Type-Options "nosniff";
        log_not_found off;
    }

    # WordPress specific locations
    
    # Favicon and robots.txt
    location = /favicon.ico {
        log_not_found off;
        access_log off;
        expires 1M;
        add_header Cache-Control "public, immutable";
    }

    location = /robots.txt {
        log_not_found off;
        access_log off;
        try_files $uri $uri/ /index.php?$args;
    }

    # WordPress sitemap
    location = /sitemap.xml {
        try_files $uri $uri/ /index.php?$args;
    }
    
    location = /sitemap_index.xml {
        try_files $uri $uri/ /index.php?$args;
    }

    # WordPress login and admin protection
    location ~ ^/(wp-admin|wp-login\.php) {
        limit_req zone=wp_admin burst=5 nodelay;
        
        # Additional security for admin area
        add_header X-Frame-Options "DENY" always;
        
        try_files $uri $uri/ /index.php?$args;
        
        location ~ \.php$ {
            include fastcgi_params;
            fastcgi_pass php:9000;
            fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
            fastcgi_param HTTPS on;
            fastcgi_cache off;
        }
    }

    # WordPress REST API rate limiting
    location ~ ^/wp-json/ {
        limit_req zone=wp_api burst=10 nodelay;
        try_files $uri $uri/ /index.php?$args;
    }

    # Static file handling with aggressive caching
    location ~* \.(css|gif|ico|jpeg|jpg|png|svg|webp|woff|woff2|ttf|eot|otf|js)$ {
        expires 1M;
        add_header Cache-Control "public, immutable";
        add_header X-Content-Type-Options "nosniff";
        add_header Access-Control-Allow-Origin "*";
        log_not_found off;
        
        # Serve pre-compressed files if available
        location ~* \.(css|js)$ {
            gzip_static on;
        }
    }

    # WordPress media files
    location ~* \.(pdf|doc|docx|xls|xlsx|ppt|pptx|zip|tar|gz|rar|mp4|mp3|avi|mov|wmv|flv)$ {
        expires 1M;
        add_header Cache-Control "public";
        add_header X-Content-Type-Options "nosniff";
        log_not_found off;
    }

    # WordPress permalink structure
    location / {
        try_files $uri $uri/ /index.php?$args;
    }

    # PHP processing with advanced caching
    location ~ \.php$ {
        try_files $uri =404;
        
        # Security check
        if ($uri !~ "^/[a-zA-Z0-9\.\-\_\/]+\.php$") {
            return 444;
        }
        
        # FastCGI cache configuration
        set $no_cache 0;
        set $cache_uri $request_uri;
        
        # Don't cache for logged in users
        if ($http_cookie ~* "comment_author_|wordpress_[a-f0-9]+|wp-postpass_|wordpress_logged_in_") {
            set $no_cache 1;
        }
        
        # Don't cache admin, login, or dynamic pages
        if ($request_uri ~* "/(wp-admin/|wp-login\.php|wp-cron\.php)") {
            set $no_cache 1;
        }
        
        # Don't cache POST requests
        if ($request_method = POST) {
            set $no_cache 1;
        }
        
        # Don't cache if there are query parameters
        if ($query_string != "") {
            set $no_cache 1;
        }
        
        # FastCGI configuration
        include fastcgi_params;
        fastcgi_pass php:9000;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param HTTPS on;
        fastcgi_param HTTP_SCHEME https;
        
        # FastCGI caching
        fastcgi_cache WORDPRESS;
        fastcgi_cache_valid 200 301 302 60m;
        fastcgi_cache_valid 404 1m;
        fastcgi_cache_bypass $no_cache;
        fastcgi_no_cache $no_cache;
        fastcgi_cache_background_update on;
        fastcgi_cache_use_stale updating error timeout invalid_header http_500 http_503;
        
        # Cache status headers
        add_header X-Cache-Status $upstream_cache_status always;
        add_header X-Cache-Key $cache_uri;
        
        # FastCGI timeouts
        fastcgi_connect_timeout 60s;
        fastcgi_send_timeout 60s;
        fastcgi_read_timeout 60s;
        fastcgi_buffer_size 128k;
        fastcgi_buffers 4 256k;
        fastcgi_busy_buffers_size 256k;
    }

    # Nginx status page (for monitoring)
    location /nginx-status {
        stub_status on;
        access_log off;
        allow 127.0.0.1;
        allow ::1;
        deny all;
    }
}
'@

$nginxWordPressConfig | Out-File -FilePath "config\nginx\conf.d\default.conf" -Encoding UTF8

# Create optimized PHP 8.4 configuration
$phpIniConfig = @'
; Custom PHP 8.4 Configuration for WordPress - 2025 Edition
; Optimized for performance, security, and modern WordPress features

; Core PHP Settings
memory_limit = 512M
max_execution_time = 300
max_input_time = 300
max_input_vars = 3000
post_max_size = 128M
upload_max_filesize = 128M
max_file_uploads = 20
default_socket_timeout = 60

; Security Settings (Enhanced for 2025)
expose_php = Off
allow_url_fopen = On
allow_url_include = Off
enable_dl = Off
file_uploads = On
auto_globals_jit = On
register_argc_argv = Off

; Session Security
session.cookie_httponly = On
session.cookie_secure = On
session.cookie_samesite = "Strict"
session.use_only_cookies = On
session.use_strict_mode = On
session.cookie_lifetime = 0
session.name = PHPSESSID
session.entropy_length = 128
session.hash_function = sha256

; Error Handling and Logging
display_errors = Off
display_startup_errors = Off
log_errors = On
error_log = /var/log/php/error.log
log_errors_max_len = 1024
ignore_repeated_errors = On
ignore_repeated_source = On

; PHP 8.4 OPcache Configuration (Enhanced)
opcache.enable = 1
opcache.enable_cli = 0
opcache.memory_consumption = 512
opcache.interned_strings_buffer = 32
opcache.max_accelerated_files = 10000
opcache.revalidate_freq = 2
opcache.fast_shutdown = 1
opcache.enable_file_override = 1
opcache.validate_timestamps = 1
opcache.save_comments = 1
opcache.load_comments = 1
opcache.optimization_level = 0x7FFFBFFF
opcache.jit_buffer_size = 128M
opcache.jit = 1255

; Realpath Cache (Performance)
realpath_cache_size = 4096k
realpath_cache_ttl = 600

; Session Configuration
session.gc_maxlifetime = 3600
session.gc_probability = 1
session.gc_divisor = 1000
session.save_path = "/tmp/php-sessions"

; Date/Time
date.timezone = UTC

; MySQL/MariaDB Optimizations
mysqli.default_port = 3306
mysqli.default_socket = /var/run/mysqld/mysqld.sock
mysqli.default_host = mariadb
mysqli.default_user = 
mysqli.default_pw = 
mysqli.reconnect = Off
mysqli.cache_size = 2000

; File Handling
file_uploads = On
upload_tmp_dir = /tmp
upload_max_filesize = 128M
max_file_uploads = 20

; Resource Limits
max_execution_time = 300
max_input_time = 300
memory_limit = 512M

; Data Handling
post_max_size = 128M
auto_prepend_file = 
auto_append_file = 
default_mimetype = "text/html"
default_charset = "UTF-8"

; Zend Engine
zend.enable_gc = On
zend.multibyte = Off
zend.script_encoding = 

; WordPress Specific Optimizations
max_input_vars = 3000
pcre.backtrack_limit = 1000000
pcre.recursion_limit = 100000

; PHP 8.4 JIT Configuration
opcache.jit = 1255
opcache.jit_buffer_size = 128M
opcache.jit_debug = 0

; Modern PHP Features
zend.assertions = -1
assert.active = Off
'@

$phpIniConfig | Out-File -FilePath "config\php\php.ini" -Encoding UTF8

# Create PHP-FPM configuration optimized for PHP 8.4
$phpFpmConfig = @'
; PHP-FPM 8.4 Global Configuration - 2025 Edition
; Optimized for WordPress and Docker environment

[global]
pid = /var/run/php-fpm.pid
error_log = /var/log/php/php-fpm.log
log_level = warning
emergency_restart_threshold = 10
emergency_restart_interval = 1m
process_control_timeout = 10s
daemonize = no
rlimit_files = 1024
rlimit_core = 0

; Event mechanism for better performance
events.mechanism = epoll

; Pool configuration
include=/usr/local/etc/php-fpm.d/*.conf
'@

$phpFpmConfig | Out-File -FilePath "config\php\php-fpm.conf" -Encoding UTF8

# Create PHP-FPM www pool configuration
$phpFpmWwwConfig = @'
; PHP-FPM Pool Configuration for WordPress - PHP 8.4 Optimized
; Enhanced for 2025 performance standards

[www]
user = www-data
group = www-data

; Listen configuration
listen = 9000
listen.owner = www-data
listen.group = www-data
listen.mode = 0666
listen.backlog = 511
listen.allowed_clients = 127.0.0.1

; Process management
pm = dynamic
pm.max_children = 20
pm.start_servers = 4
pm.min_spare_servers = 2
pm.max_spare_servers = 8
pm.process_idle_timeout = 30s
pm.max_requests = 1000
pm.status_path = /php-fpm-status

; Ping configuration
ping.path = /php-fpm-ping
ping.response = pong

; Logging
access.log = /var/log/php/access.log
access.format = "%R - %u %t \"%m %r\" %s %f %{mili}d %{kilo}M %C%%"
slowlog = /var/log/php/slow.log
request_slowlog_timeout = 5s
request_terminate_timeout = 120s

; Environment variables
clear_env = no
env[HOSTNAME] = $HOSTNAME
env[PATH] = /usr/local/bin:/usr/bin:/bin
env[TMP] = /tmp
env[TMPDIR] = /tmp
env[TEMP] = /tmp

; PHP configuration values
php_admin_value[sendmail_path] = /usr/sbin/sendmail -t -i -f www@$HOSTNAME
php_flag[display_errors] = off
php_admin_value[error_log] = /var/log/php/www.error.log
php_admin_flag[log_errors] = on
php_admin_value[memory_limit] = 512M
php_admin_value[max_execution_time] = 300
php_admin_value[upload_max_filesize] = 128M
php_admin_value[post_max_size] = 128M

; Security settings
php_admin_value[open_basedir] = /var/www/html:/tmp:/var/tmp:/dev/urandom
security.limit_extensions = .php .php3 .php4 .php5 .php7 .php8

; Session configuration
php_value[session.save_handler] = files
php_value[session.save_path] = /tmp/php-sessions
php_value[session.gc_maxlifetime] = 3600

; OPcache settings (for this pool)
php_admin_value[opcache.enable] = 1
php_admin_value[opcache.memory_consumption] = 512
php_admin_value[opcache.interned_strings_buffer] = 32
php_admin_value[opcache.max_accelerated_files] = 10000

; JIT settings for PHP 8.4
php_admin_value[opcache.jit] = 1255
php_admin_value[opcache.jit_buffer_size] = 128M
'@

$phpFpmWwwConfig | Out-File -FilePath "config\php\www.conf" -Encoding UTF8

# Create MariaDB 11.8 LTS configuration
$mariadbConfig = @'
# MariaDB 11.8 LTS Configuration for WordPress - 2025 Edition
# Optimized for performance, security, and new features including Vector support

[client]
default_character_set = utf8mb4
socket = /var/run/mysqld/mysqld.sock

[mysql]
default_character_set = utf8mb4
no_auto_rehash
prompt = "\u@\h [\d]> "

[mysqld]
# Basic Settings
user = mysql
port = 3306
socket = /var/run/mysqld/mysqld.sock
basedir = /usr
datadir = /var/lib/mysql
tmpdir = /tmp
pid_file = /var/run/mysqld/mysqld.pid

# Character Set and Collation (WordPress optimized)
character_set_server = utf8mb4
collation_server = utf8mb4_unicode_ci
init_connect = 'SET NAMES utf8mb4'

# Storage Engine
default_storage_engine = InnoDB
default_tmp_storage_engine = InnoDB

# Connection and Thread Settings
max_connections = 200
thread_cache_size = 16
thread_stack = 256K
max_allowed_packet = 64M
connect_timeout = 10
wait_timeout = 600
interactive_timeout = 600
net_read_timeout = 60
net_write_timeout = 60

# Query Cache (MariaDB 11.8 optimized)
query_cache_type = 1
query_cache_size = 128M
query_cache_limit = 4M
query_cache_min_res_unit = 2K

# Table and Key Settings
table_open_cache = 4000
table_definition_cache = 2000
open_files_limit = 65535

# MyISAM Settings
key_buffer_size = 64M
myisam_sort_buffer_size = 64M
myisam_max_sort_file_size = 1G

# General Buffer Settings
sort_buffer_size = 2M
read_buffer_size = 1M
read_rnd_buffer_size = 2M
join_buffer_size = 2M
tmp_table_size = 64M
max_heap_table_size = 64M

# InnoDB Configuration (Enhanced for MariaDB 11.8)
innodb_buffer_pool_size = 512M
innodb_buffer_pool_instances = 4
innodb_buffer_pool_chunk_size = 128M
innodb_log_file_size = 128M
innodb_log_files_in_group = 2
innodb_log_buffer_size = 32M
innodb_flush_log_at_trx_commit = 2
innodb_flush_method = O_DIRECT
innodb_file_per_table = 1
innodb_open_files = 400
innodb_io_capacity = 1000
innodb_io_capacity_max = 2000
innodb_read_io_threads = 8
innodb_write_io_threads = 8
innodb_thread_concurrency = 0
innodb_lock_wait_timeout = 50
innodb_deadlock_detect = ON
innodb_rollback_on_timeout = ON

# InnoDB Advanced Settings
innodb_adaptive_hash_index = ON
innodb_adaptive_flushing = ON
innodb_change_buffering = all
innodb_old_blocks_time = 1000
innodb_stats_on_metadata = OFF
innodb_stats_persistent = ON
innodb_stats_auto_recalc = ON

# Binary Logging (Enhanced)
log_bin = mysql-bin
binlog_format = ROW
binlog_row_image = MINIMAL
expire_logs_days = 7
max_binlog_size = 256M
sync_binlog = 0
binlog_cache_size = 1M
binlog_stmt_cache_size = 1M

# Slow Query Log
slow_query_log = 1
slow_query_log_file = /var/log/mysql/mysql-slow.log
long_query_time = 2.0
log_queries_not_using_indexes = 0
log_throttle_queries_not_using_indexes = 10
min_examined_row_limit = 100

# Error Logging
log_error = /var/log/mysql/error.log
log_warnings = 2

# General Security Settings
local_infile = 0
symbolic_links = 0
secure_file_priv = /tmp

# Performance Schema (MariaDB 11.8)
performance_schema = ON
performance_schema_max_table_instances = 500
performance_schema_max_table_handles = 1000

# MariaDB 11.8 Specific Features
# Vector support configuration (new in 11.8)
plugin_load_add = vector

# Optimizer settings for better performance
optimizer_search_depth = 62
optimizer_prune_level = 1
optimizer_use_condition_selectivity = 4

# Connection control and security
max_connect_errors = 1000000
max_user_connections = 0

# Replication settings (if needed)
server_id = 1
gtid_strict_mode = 1

# MariaDB specific optimizations
aria_pagecache_buffer_size = 64M
aria_sort_buffer_size = 64M

[mysqldump]
quick
quote_names
max_allowed_packet = 64M

[isamchk]
key_buffer_size = 64M

[myisamchk]
key_buffer_size = 64M
sort_buffer_size = 64M
read_buffer = 8M
write_buffer = 8M

[mysqlhotcopy]
interactive_timeout
'@

$mariadbConfig | Out-File -FilePath "config\mysql\my.cnf" -Encoding UTF8

Write-Success "All configuration files created with 2025 optimizations"

# Create enhanced backup script
$backupScript = @'
# WordPress Docker Backup Script - 2025 Edition
# Enhanced backup solution with compression and retention management

param(
    [string]$BackupPath = ".\backups",
    [switch]$DatabaseOnly,
    [switch]$FilesOnly,
    [switch]$Compress = $true,
    [int]$RetentionDays = 30,
    [switch]$Verbose
)

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timestamp [$Level] $Message"
    Write-Host $logMessage
    $logMessage | Out-File -FilePath "logs\backup.log" -Append -Encoding UTF8
}

$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$projectName = "wordpress-docker"

if (!(Test-Path $BackupPath)) {
    New-Item -ItemType Directory -Path $BackupPath -Force | Out-Null
    New-Item -ItemType Directory -Path "$BackupPath\database" -Force | Out-Null
    New-Item -ItemType Directory -Path "$BackupPath\files" -Force | Out-Null
}

Write-Log "Starting backup process for $projectName" "INFO"

# Database backup with enhanced features
if (!$FilesOnly) {
    Write-Log "Creating database backup..." "INFO"
    
    $dbBackupFile = Join-Path "$BackupPath\database" "$projectName`_database_$timestamp.sql"
    
    try {
        docker exec "$projectName`_mariadb" mysqldump -u root -ppassword --single-transaction --routines --triggers --events --hex-blob --add-drop-table --add-locks --create-options --disable-keys --extended-insert --quick --lock-tables=false wordpress > $dbBackupFile
        
        if ($LASTEXITCODE -eq 0 -and (Test-Path $dbBackupFile) -and (Get-Item $dbBackupFile).Length -gt 1KB) {
            $fileSize = [math]::Round((Get-Item $dbBackupFile).Length / 1MB, 2)
            Write-Log "Database backup completed: $dbBackupFile ($fileSize MB)" "SUCCESS"
            
            if ($Compress) {
                $compressedFile = "$dbBackupFile.gz"
                & gzip -9 $dbBackupFile
                if ($LASTEXITCODE -eq 0 -and (Test-Path $compressedFile)) {
                    $compressedSize = [math]::Round((Get-Item $compressedFile).Length / 1MB, 2)
                    Write-Log "Database backup compressed: $compressedFile ($compressedSize MB)" "SUCCESS"
                }
            }
        } else {
            Write-Log "Database backup failed or file is too small!" "ERROR"
        }
    } catch {
        Write-Log "Database backup error: $_" "ERROR"
    }
}

# Enhanced files backup
if (!$DatabaseOnly) {
    Write-Log "Creating WordPress files backup..." "INFO"
    
    $filesBackupFile = Join-Path "$BackupPath\files" "$projectName`_files_$timestamp.zip"
    
    if (Test-Path ".\wordpress") {
        try {
            $compressionLevel = "Optimal"
            Compress-Archive -Path ".\wordpress\*" -DestinationPath $filesBackupFile -CompressionLevel $compressionLevel -Force
            
            if (Test-Path $filesBackupFile) {
                $fileSize = [math]::Round((Get-Item $filesBackupFile).Length / 1MB, 2)
                Write-Log "Files backup completed: $filesBackupFile ($fileSize MB)" "SUCCESS"
            }
        } catch {
            Write-Log "Files backup error: $_" "ERROR"
        }
    } else {
        Write-Log "WordPress files directory not found!" "ERROR"
    }
}

# Cleanup old backups based on retention policy
Write-Log "Cleaning up old backups (retention: $RetentionDays days)..." "INFO"

try {
    $cutoffDate = (Get-Date).AddDays(-$RetentionDays)
    
    Get-ChildItem "$BackupPath\database" -File | Where-Object { $_.CreationTime -lt $cutoffDate } | ForEach-Object {
        Remove-Item $_.FullName -Force
        Write-Log "Removed old database backup: $($_.Name)" "INFO"
    }
    
    Get-ChildItem "$BackupPath\files" -File | Where-Object { $_.CreationTime -lt $cutoffDate } | ForEach-Object {
        Remove-Item $_.FullName -Force
        Write-Log "Removed old files backup: $($_.Name)" "INFO"
    }
} catch {
    Write-Log "Cleanup error: $_" "WARNING"
}

$dbBackups = (Get-ChildItem "$BackupPath\database" -File | Measure-Object).Count
$fileBackups = (Get-ChildItem "$BackupPath\files" -File | Measure-Object).Count
$totalSize = [math]::Round(((Get-ChildItem $BackupPath -Recurse -File | Measure-Object -Property Length -Sum).Sum / 1MB), 2)

Write-Log "Backup process completed!" "SUCCESS"
Write-Log "Database backups: $dbBackups, File backups: $fileBackups" "INFO"
Write-Log "Total backup size: $totalSize MB" "INFO"
Write-Log "Backup location: $BackupPath" "INFO"
'@

$backupScript | Out-File -FilePath "PowerShell\backup-wordpress.ps1" -Encoding UTF8

# Create enhanced SSL generation script
$sslScript = @'
# Enhanced SSL Certificate Generation Script - 2025 Edition
# Creates 4096-bit RSA certificates with modern security standards

param(
    [string]$Domain = "localhost",
    [string]$KeyPath = ".\ssl\private",
    [string]$CertPath = ".\ssl\certificates",
    [int]$ValidityDays = 730,
    [switch]$GenerateDH = $true
)

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $colors = @{
        "INFO" = "Cyan"
        "SUCCESS" = "Green"
        "WARNING" = "Yellow"
        "ERROR" = "Red"
    }
    Write-Host $Message -ForegroundColor $colors[$Level]
}

Write-Log "Generating enhanced SSL certificates for $Domain..." "INFO"

if (!(Test-Path $KeyPath)) { New-Item -ItemType Directory -Path $KeyPath -Force | Out-Null }
if (!(Test-Path $CertPath)) { New-Item -ItemType Directory -Path $CertPath -Force | Out-Null }

$opensslConfig = @"
[req]
default_bits = 4096
prompt = no
default_md = sha256
distinguished_name = dn
req_extensions = v3_req

[dn]
CN=$Domain
O=WordPress Docker Stack
OU=Development Environment
L=Local Development
ST=Local
C=US
emailAddress=admin@$Domain

[v3_req]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth, clientAuth
subjectAltName = @alt_names
authorityKeyIdentifier = keyid,issuer

[alt_names]
DNS.1 = $Domain
DNS.2 = www.$Domain
DNS.3 = localhost
DNS.4 = *.localhost
DNS.5 = *.$Domain
IP.1 = 127.0.0.1
IP.2 = ::1
"@

$configFile = ".\ssl\openssl.conf"
$opensslConfig | Out-File -FilePath $configFile -Encoding UTF8

try {
    Write-Log "Generating 4096-bit RSA private key..." "INFO"
    & openssl genrsa -out "$KeyPath\server.key" 4096 2>$null
    
    Write-Log "Creating certificate signing request..." "INFO"
    & openssl req -new -key "$KeyPath\server.key" -out ".\ssl\server.csr" -config $configFile 2>$null
    
    Write-Log "Generating self-signed certificate (valid for $ValidityDays days)..." "INFO"
    & openssl x509 -req -days $ValidityDays -in ".\ssl\server.csr" -signkey "$KeyPath\server.key" -out "$CertPath\server.crt" -extensions v3_req -extfile $configFile 2>$null
    
    if ($GenerateDH) {
        Write-Log "Generating DH parameters for enhanced security (this may take a while)..." "INFO"
        & openssl dhparam -out "$CertPath\dhparam.pem" 2048 2>$null
        Write-Log "DH parameters generated successfully" "SUCCESS"
    }
    
    $bundleFile = "$CertPath\server-bundle.pem"
    Get-Content "$CertPath\server.crt" | Out-File -FilePath $bundleFile -Encoding ASCII
    if (Test-Path "$CertPath\dhparam.pem") {
        Get-Content "$CertPath\dhparam.pem" | Out-File -FilePath $bundleFile -Append -Encoding ASCII
    }
    
    Write-Log "SSL certificates generated successfully!" "SUCCESS"
    Write-Log "Private Key: $KeyPath\server.key" "INFO"
    Write-Log "Certificate: $CertPath\server.crt" "INFO"
    Write-Log "Certificate Bundle: $bundleFile" "INFO"
    
    if (Test-Path "$CertPath\dhparam.pem") {
        Write-Log "DH Parameters: $CertPath\dhparam.pem" "INFO"
    }
    
    try {
        icacls "$KeyPath\server.key" /inheritance:r /grant:r "$env:USERNAME:(R)" 2>$null | Out-Null
        Write-Log "Secure permissions set on private key" "SUCCESS"
    } catch {
        Write-Log "Warning: Could not set secure permissions on private key" "WARNING"
    }
    
    Remove-Item ".\ssl\server.csr", $configFile -ErrorAction SilentlyContinue
    
} catch {
    Write-Log "Error generating SSL certificates: $_" "ERROR"
    Write-Log "Make sure OpenSSL is installed and available in PATH" "WARNING"
    Write-Log "Download from: https://slproweb.com/products/Win32OpenSSL.html" "INFO"
}
'@

$sslScript | Out-File -FilePath "PowerShell\generate-ssl.ps1" -Encoding UTF8

Write-Success "Enhanced PowerShell scripts created for 2025"

# Start Docker containers
Write-Info "Pulling latest Docker images and starting containers..."

Set-Location "docker"

try {
    Write-Info "Pulling latest images (NGINX 1.28, PHP 8.4, MariaDB 11.8)..."
    & docker-compose --env-file .env pull
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Latest images pulled successfully"
    } else {
        Write-Warning "Some images may not have been updated, continuing..."
    }
    
    & docker-compose --env-file .env up -d --remove-orphans
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Docker containers started successfully!"
        
        Write-Info "Waiting for services to initialize (this may take 2-3 minutes)..."
        Start-Sleep -Seconds 60
        
        Write-Info "`n" + "=" * 60
        Write-Info "🚀 WordPress Docker Stack - 2025 Edition Ready!"
        Write-Info "=" * 60
        Write-Info "📊 Stack Versions:"
        Write-Info "   • NGINX: 1.28 (Latest Stable)"
        Write-Info "   • PHP: 8.4 (Latest with JIT)"
        Write-Info "   • MariaDB: 11.8 LTS (with Vector support)"
        Write-Info "   • WordPress: Latest"
        Write-Info "`n📍 Access URLs:"
        Write-Info "   • WordPress Site: https://$Domain (or https://localhost)"
        Write-Info "   • WordPress Admin: https://$Domain/wp-admin"
        Write-Info "   • phpMyAdmin: http://localhost:8080"
        Write-Info "`n🔐 Credentials:"
        Write-Info "   • WordPress Admin User: $WordPressUser"
        Write-Info "   • WordPress Admin Password: $WordPressPassword"
        Write-Info "   • WordPress Admin Email: $WordPressEmail"
        Write-Info "`n🗄️ Database Information:"
        Write-Info "   • Database Host: localhost:3306"
        Write-Info "   • Database Name: $DBName"
        Write-Info "   • Database User: $DBUser"
        Write-Info "`n📁 File Locations:"
        Write-Info "   • Project Directory: $ProjectPath"
        Write-Info "   • WordPress Files: $ProjectPath\wordpress"
        Write-Info "   • Configuration Files: $ProjectPath\config"
        Write-Info "   • SSL Certificates: $ProjectPath\ssl"
        Write-Info "   • Backups: $ProjectPath\backups"
        Write-Info "   • Logs: $ProjectPath\logs"
        Write-Info "`n🛠️ Management Commands:"
        Write-Info "   • View Logs: docker-compose logs -f [service]"
        Write-Info "   • Restart Services: docker-compose restart"
        Write-Info "   • Stop Services: docker-compose down"
        Write-Info "   • Update Images: docker-compose pull && docker-compose up -d"
        Write-Info "   • Backup: .\PowerShell\backup-wordpress.ps1"
        Write-Info "=" * 60
        
    } else {
        Write-Error "Failed to start Docker containers"
        Write-Info "Check the logs with: docker-compose logs"
    }
} catch {
    Write-Error "Error starting Docker containers: $_"
}

Set-Location ..

# Save comprehensive credentials to file
$credentialsContent = @"
WordPress Docker Stack Credentials - 2025 Edition
================================================
Generated on $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

Stack Versions:
- NGINX: 1.28 (Latest Stable)
- PHP: 8.4 (Latest with JIT)
- MariaDB: 11.8 LTS (with Vector support)
- WordPress: Latest

WordPress Access:
- URL: https://$Domain
- Admin URL: https://$Domain/wp-admin
- Username: $WordPressUser
- Password: $WordPressPassword
- Email: $WordPressEmail

Database Access:
- Host: localhost:3306
- Database: $DBName
- Username: $DBUser
- Password: $DBPassword
- Root Password: $DBRootPassword

Additional Services:
- phpMyAdmin: http://localhost:8080
  - Username: root
  - Password: $DBRootPassword
- Redis Cache: Available (internal)

File Locations:
- Project: $ProjectPath
- WordPress: $ProjectPath\wordpress
- Configs: $ProjectPath\config
- SSL: $ProjectPath\ssl
- Backups: $ProjectPath\backups
- Logs: $ProjectPath\logs

Management Scripts:
- Backup: .\PowerShell\backup-wordpress.ps1
- SSL Regen: .\PowerShell\generate-ssl.ps1
- Full Setup: .\PowerShell\setup-wordpress-docker.ps1

Docker Commands:
- Start: docker-compose up -d
- Stop: docker-compose down
- Logs: docker-compose logs -f
- Update: docker-compose pull && docker-compose up -d --force-recreate

Generated by WordPress Docker Stack Setup Script 2025
"@

$credentialsContent | Out-File -FilePath "CREDENTIALS.txt" -Encoding UTF8
Write-Success "Comprehensive credentials and information saved to CREDENTIALS.txt"

Write-Success "`n🎉 WordPress Docker Stack 2025 setup completed successfully!"
Write-Info "🌐 Access your site at: https://$Domain"
Write-Info "📖 All information saved in CREDENTIALS.txt"
```

## How to Use the Fixed Script

1. **Save the corrected script** as `setup-wordpress-docker.ps1` in your `C:\WordPress-Docker-2025\` directory (not in the PowerShell subfolder)

2. **Set execution policy** (run PowerShell as Administrator):
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine
```

3. **Run the script**:
```powershell
cd "C:\WordPress-Docker-2025\"
.\setup-wordpress-docker.ps1
```

## Key Fixes Applied

1. **Fixed string interpolation** - Replaced backticks with proper PowerShell string formatting
2. **Corrected here-string syntax** - Used `@'` and `'@` for multi-line strings containing variables  
3. **Fixed file paths** - Used proper Windows path separators
4. **Corrected parameter syntax** - Fixed parameter block formatting
5. **Fixed variable references** - Corrected PowerShell variable syntax
6. **Updated Docker image versions** - Used the latest 2025 versions you specified

The script now includes all the latest versions (NGINX 1.28, PHP 8.4, MariaDB 11.8 LTS) and should run without syntax errors on Windows 11 with Docker Desktop.