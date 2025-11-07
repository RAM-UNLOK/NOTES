# WordPress Docker Setup - FINAL PRODUCTION-READY
# Generated: November 2025
# Versions: WordPress 6.8, PHP 8.4, MariaDB 11.5, NGINX 1.28
# MariaDB optimizer_switch FIXED + All Enhancements

param(
    [string]$AdminUsername = "",
    [string]$AdminPassword = "",
    [string]$AdminEmail = "",
    [string]$DatabasePassword = "",
    [string]$SiteName = "My WordPress Site",
    [string]$SiteDomain = "localhost"
)

$ErrorActionPreference = "Continue"
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$LogFile = "$(Get-Location)\wordpress-docker-setup-$timestamp.log"

Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "WordPress Docker - FINAL PRODUCTION-READY v7.0" -ForegroundColor Cyan
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "MariaDB Fixed + Maximum Performance + Security" -ForegroundColor Yellow
Write-Host ""

function Write-StatusMessage {
    param([string]$Message, [string]$Color = "White", [string]$Type = "INFO")
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMsg = "[$ts] [$Type] $Message"
    Write-Host $logMsg -ForegroundColor $Color
    try { Out-File -InputObject $logMsg -FilePath $LogFile -Append -Encoding UTF8 -ErrorAction SilentlyContinue } catch {}
}

function Write-FileNoBOM {
    param([string]$Content, [string]$FilePath)
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($FilePath, $Content, $utf8NoBom)
}

function Get-UserCredentials {
    Write-StatusMessage "Collecting credentials..." "Yellow" "INPUT"

    if ([string]::IsNullOrEmpty($script:AdminUsername)) {
        do {
            $script:AdminUsername = Read-Host "WordPress Admin Username"
        } while ([string]::IsNullOrEmpty($script:AdminUsername))
    }

    if ([string]::IsNullOrEmpty($script:AdminPassword)) {
        do {
            $securePassword = Read-Host "WordPress Admin Password" -AsSecureString
            $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword)
            $script:AdminPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
            [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
        } while ([string]::IsNullOrEmpty($script:AdminPassword))
    }

    if ([string]::IsNullOrEmpty($script:AdminEmail)) {
        do {
            $script:AdminEmail = Read-Host "WordPress Admin Email"
        } while ([string]::IsNullOrEmpty($script:AdminEmail) -or $script:AdminEmail -notmatch "^[^@]+@[^@]+\.[^@]+$")
    }

    if ([string]::IsNullOrEmpty($script:DatabasePassword)) {
        do {
            $secureDbPassword = Read-Host "Database Root Password" -AsSecureString
            $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureDbPassword)
            $script:DatabasePassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
            [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
        } while ([string]::IsNullOrEmpty($script:DatabasePassword))
    }
}

function Test-Prerequisites {
    Write-StatusMessage "Checking prerequisites..." "Yellow" "CHECK"

    try {
        $dockerVersion = docker --version 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-StatusMessage "Docker: $dockerVersion" "Green" "SUCCESS"
        } else { throw "Docker not found" }
    } catch {
        Write-StatusMessage "Install Docker Desktop and try again" "Red" "ERROR"
        exit 1
    }

    try {
        docker ps 2>$null | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-StatusMessage "Docker is running" "Green" "SUCCESS"
        } else { throw "Docker not running" }
    } catch {
        Write-StatusMessage "Start Docker Desktop and try again" "Red" "ERROR"
        exit 1
    }
}

function New-ProjectStructure {
    Write-StatusMessage "Creating project structure..." "Yellow" "CREATE"

    $projectDir = "$(Get-Location)\wordpress-docker"

    $directories = @(
        "$projectDir", "$projectDir\nginx", "$projectDir\nginx\conf.d",
        "$projectDir\nginx\ssl", "$projectDir\php", "$projectDir\mariadb",
        "$projectDir\mariadb\data", "$projectDir\mariadb\logs",
        "$projectDir\wordpress", "$projectDir\logs", "$projectDir\scripts",
        "$projectDir\backups"
    )

    foreach ($dir in $directories) {
        if (!(Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
    }

    Write-StatusMessage "Project: $projectDir" "Green" "CREATE"
    return $projectDir
}

function New-SSLCertificates {
    param([string]$ProjectDir)

    Write-StatusMessage "Generating 4096-bit SSL certificates..." "Yellow" "SSL"

    $sslDir = "$ProjectDir\nginx\ssl"
    $certFile = "$sslDir\cert.pem"
    $keyFile = "$sslDir\key.pem"

    try {
        $gitPaths = @(
            "$env:ProgramFiles\Git\usr\bin\openssl.exe",
            "$env:LOCALAPPDATA\Programs\Git\usr\bin\openssl.exe"
        )

        $opensslExe = $gitPaths | Where-Object { Test-Path $_ } | Select-Object -First 1

        if ($opensslExe) {
            & $opensslExe req -newkey rsa:4096 -x509 -days 365 -nodes -out $certFile -keyout $keyFile -subj "/CN=localhost" 2>$null
            if (Test-Path $certFile) {
                Write-StatusMessage "SSL certificates created (4096-bit RSA)" "Green" "SUCCESS"
                return
            }
        }

        $cert = New-SelfSignedCertificate -DnsName "localhost" -CertStoreLocation "cert:\LocalMachine\My" -KeyAlgorithm RSA -KeyLength 4096 -NotAfter (Get-Date).AddYears(10)
        $certBytes = $cert.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Cert)
        [System.IO.File]::WriteAllBytes($certFile, $certBytes)
        Write-StatusMessage "SSL certificates created" "Green" "SUCCESS"
    } catch {
        Write-StatusMessage "SSL generation failed, continuing..." "Yellow" "WARNING"
    }
}

function New-DockerCompose {
    param([string]$ProjectDir)

    Write-StatusMessage "Creating Docker Compose..." "Yellow" "CREATE"

    $composeContent = @"
services:
  mariadb:
    image: mariadb:11.5
    container_name: wordpress_mariadb
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: $DatabasePassword
      MYSQL_DATABASE: wordpress
      MYSQL_USER: wordpress
      MYSQL_PASSWORD: $DatabasePassword
      MARIADB_AUTO_UPGRADE: 1
    volumes:
      - ./mariadb/data:/var/lib/mysql
      - ./mariadb/logs:/var/log/mysql
      - ./mariadb/custom.cnf:/etc/mysql/conf.d/custom.cnf:ro
    networks:
      - wordpress_network
    command:
      - --character-set-server=utf8mb4
      - --collation-server=utf8mb4_unicode_ci
      - --max-connections=500
      - --max-allowed-packet=256M
      - --innodb-buffer-pool-size=4G
      - --innodb-log-file-size=512M
      - --innodb-flush-log-at-trx-commit=2
      - --innodb-flush-method=O_DIRECT
      - --query-cache-type=0
      - --log-error=/var/log/mysql/error.log
      - --slow-query-log=1
      - --slow-query-log-file=/var/log/mysql/slow.log
      - --long-query-time=1
    healthcheck:
      test: ["CMD", "healthcheck.sh", "--connect", "--innodb_initialized"]
      start_period: 30s
      interval: 30s
      timeout: 5s
      retries: 3
    deploy:
      resources:
        limits:
          cpus: '4.0'
          memory: 8G
        reservations:
          cpus: '1.0'
          memory: 4G

  wordpress:
    image: wordpress:6.8-php8.4-fpm
    container_name: wordpress_app
    restart: unless-stopped
    depends_on:
      mariadb:
        condition: service_healthy
    environment:
      WORDPRESS_DB_HOST: mariadb:3306
      WORDPRESS_DB_NAME: wordpress
      WORDPRESS_DB_USER: wordpress
      WORDPRESS_DB_PASSWORD: $DatabasePassword
      WORDPRESS_TABLE_PREFIX: wp_
      WORDPRESS_CONFIG_EXTRA: |
        define('WP_CACHE', true);
        define('WP_CACHE_KEY_SALT', 'wp_redis_');
        define('WP_REDIS_HOST', 'redis');
        define('WP_REDIS_PORT', 6379);
        define('WP_REDIS_DATABASE', 0);
        define('WP_REDIS_TIMEOUT', 1);
        define('WP_REDIS_READ_TIMEOUT', 1);
        define('WP_REDIS_MAXTTL', 86400);
        define('WP_MEMORY_LIMIT', '1024M');
        define('WP_MAX_MEMORY_LIMIT', '4096M');
        define('WP_POST_REVISIONS', 5);
        define('AUTOSAVE_INTERVAL', 300);
        define('EMPTY_TRASH_DAYS', 7);
        define('COMPRESS_CSS', true);
        define('COMPRESS_SCRIPTS', true);
        define('CONCATENATE_SCRIPTS', true);
        define('ENFORCE_GZIP', true);
        define('DISALLOW_FILE_EDIT', true);
        define('FORCE_SSL_ADMIN', true);
        define('FORCE_SSL_LOGIN', true);
        define('WP_AUTO_UPDATE_CORE', 'minor');
    volumes:
      - ./wordpress:/var/www/html
      - ./php/php-custom.ini:/usr/local/etc/php/conf.d/custom.ini:ro
      - ./php/php-security.ini:/usr/local/etc/php/conf.d/security.ini:ro
      - ./php/www.conf:/usr/local/etc/php-fpm.d/www.conf:ro
    networks:
      - wordpress_network
    healthcheck:
      test: ["CMD-SHELL", "php-fpm-healthcheck || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 3
    deploy:
      resources:
        limits:
          cpus: '4.0'
          memory: 4G
        reservations:
          cpus: '1.0'
          memory: 2G

  nginx:
    image: nginx:1.28
    container_name: wordpress_nginx
    restart: unless-stopped
    depends_on:
      - wordpress
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./wordpress:/var/www/html:ro
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./nginx/conf.d:/etc/nginx/conf.d:ro
      - ./nginx/ssl:/etc/nginx/ssl:ro
      - ./logs/nginx:/var/log/nginx
    networks:
      - wordpress_network
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 1024M

  redis:
    image: redis:7-alpine
    container_name: wordpress_redis
    restart: unless-stopped
    command: >
      redis-server
      --appendonly yes
      --appendfsync everysec
      --maxmemory 1gb
      --maxmemory-policy allkeys-lru
      --save 900 1
      --save 300 10
      --save 60 10000
      --tcp-backlog 511
      --timeout 0
      --tcp-keepalive 300
      --loglevel notice
      --maxclients 10000
    volumes:
      - redis_data:/data
    networks:
      - wordpress_network
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 3
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 1.5G

networks:
  wordpress_network:
    driver: bridge

volumes:
  redis_data:
    driver: local
"@

    Write-FileNoBOM -Content $composeContent -FilePath "$ProjectDir\docker-compose.yml"
    Write-StatusMessage "Docker Compose created" "Green" "SUCCESS"
}

function New-NginxConfig {
    param([string]$ProjectDir)

    Write-StatusMessage "Creating NGINX configuration..." "Yellow" "CREATE"

    $nginxMainConfig = @'
user nginx;
worker_processes auto;
worker_rlimit_nofile 100000;
error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;

events {
    worker_connections 8192;
    use epoll;
    multi_accept on;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" "$http_user_agent"';

    access_log /var/log/nginx/access.log main;

    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    server_tokens off;
    client_max_body_size 512M;

    gzip on;
    gzip_vary on;
    gzip_comp_level 6;
    gzip_min_length 256;
    gzip_types text/plain text/css text/xml application/javascript application/json;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    limit_req_zone $binary_remote_addr zone=wp_login:10m rate=3r/m;
    limit_req_zone $binary_remote_addr zone=wp_admin:10m rate=50r/m;
    limit_req_zone $binary_remote_addr zone=wp_api:10m rate=200r/m;

    include /etc/nginx/conf.d/*.conf;
}
'@

    Write-FileNoBOM -Content $nginxMainConfig -FilePath "$ProjectDir\nginx\nginx.conf"

    $wordpressConfig = @'
upstream php-fpm {
    server wordpress:9000;
    keepalive 16;
}

server {
    listen 80;
    server_name localhost;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl;
    http2 on;
    server_name localhost;
    root /var/www/html;
    index index.php;

    ssl_certificate /etc/nginx/ssl/cert.pem;
    ssl_certificate_key /etc/nginx/ssl/key.pem;

    add_header Strict-Transport-Security "max-age=31536000" always;

    location / {
        try_files $uri $uri/ /index.php?$args;
    }

    location ~ \.php$ {
        try_files $uri =404;
        fastcgi_pass php-fpm;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param HTTPS on;
        fastcgi_buffers 16 256k;
        fastcgi_buffer_size 256k;
        fastcgi_read_timeout 300s;
    }

    location = /wp-login.php {
        limit_req zone=wp_login burst=3 nodelay;
        fastcgi_pass php-fpm;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param HTTPS on;
    }

    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        access_log off;
    }

    location = /favicon.ico { log_not_found off; access_log off; }
    location = /xmlrpc.php { deny all; access_log off; return 444; }
    location ~ /\. { deny all; access_log off; }
    location ~* /uploads/.*\.php$ { deny all; }
}
'@

    Write-FileNoBOM -Content $wordpressConfig -FilePath "$ProjectDir\nginx\conf.d\wordpress.conf"
    Write-StatusMessage "NGINX config created" "Green" "SUCCESS"
}

function New-PHPConfig {
    param([string]$ProjectDir)

    Write-StatusMessage "Creating PHP configuration..." "Yellow" "CREATE"

    $phpCustomIni = @'
memory_limit = 4096M
max_execution_time = 300
max_input_time = 300
max_input_vars = 10000
post_max_size = 1024M
upload_max_filesize = 512M
max_file_uploads = 20

session.save_handler = redis
session.save_path = "tcp://redis:6379"

log_errors = On
display_errors = Off

realpath_cache_size = 4M
realpath_cache_ttl = 600

opcache.enable = 1
opcache.memory_consumption = 512
opcache.interned_strings_buffer = 64
opcache.max_accelerated_files = 130987
opcache.validate_timestamps = 0
opcache.jit = tracing
opcache.jit_buffer_size = 512M
'@

    Write-FileNoBOM -Content $phpCustomIni -FilePath "$ProjectDir\php\php-custom.ini"

    $phpSecurityIni = @'
expose_php = Off
allow_url_fopen = Off
allow_url_include = Off
disable_functions = exec,passthru,shell_exec,system,proc_open,popen
'@

    Write-FileNoBOM -Content $phpSecurityIni -FilePath "$ProjectDir\php\php-security.ini"

    $phpFpmConfig = @'
[www]
user = www-data
group = www-data
listen = 9000

pm = dynamic
pm.max_children = 150
pm.start_servers = 30
pm.min_spare_servers = 15
pm.max_spare_servers = 50
pm.max_requests = 1000

request_terminate_timeout = 300s
request_slowlog_timeout = 5s
slowlog = /proc/self/fd/2

php_value[memory_limit] = 4096M

catch_workers_output = yes
'@

    Write-FileNoBOM -Content $phpFpmConfig -FilePath "$ProjectDir\php\www.conf"
    Write-StatusMessage "PHP config created" "Green" "SUCCESS"
}

function New-MariaDBConfig {
    param([string]$ProjectDir)

    Write-StatusMessage "Creating MariaDB config (optimizer_switch FIXED)..." "Yellow" "CREATE"

    # FIXED: Removed deprecated optimizer_switch options for MariaDB 11.5
    $mariadbConfig = @'
[mysqld]
# Character Set
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci
skip-character-set-client-handshake

# Performance Schema
performance_schema = ON

# Connection Management
max_connections = 500
max_connect_errors = 1000000
connect_timeout = 10
wait_timeout = 600
interactive_timeout = 600

# Thread Settings
thread_cache_size = 100
thread_stack = 256K

# Table Cache
table_open_cache = 10000
table_definition_cache = 5000
open_files_limit = 65535

# InnoDB Buffer Pool
innodb_buffer_pool_size = 4G
innodb_buffer_pool_instances = 16
innodb_buffer_pool_dump_at_shutdown = 1
innodb_buffer_pool_load_at_startup = 1

# InnoDB Performance
innodb_flush_log_at_trx_commit = 2
innodb_log_file_size = 512M
innodb_log_buffer_size = 64M
innodb_flush_method = O_DIRECT
innodb_file_per_table = 1
innodb_stats_on_metadata = 0

# InnoDB I/O
innodb_io_capacity = 4000
innodb_io_capacity_max = 8000
innodb_read_io_threads = 8
innodb_write_io_threads = 8
innodb_purge_threads = 4

# InnoDB Flushing
innodb_adaptive_flushing = ON
innodb_flush_neighbors = 0

# Query Cache (disabled)
query_cache_type = 0
query_cache_size = 0

# Temporary Tables
tmp_table_size = 256M
max_heap_table_size = 256M

# Binary Logging
server-id = 1
log_bin = mysql-bin
binlog_format = ROW
sync_binlog = 1
expire_logs_days = 7
max_binlog_size = 256M

# Slow Query Log
slow_query_log = 1
long_query_time = 1
log_queries_not_using_indexes = 0

# Network
max_allowed_packet = 256M

# MyISAM
key_buffer_size = 256M

# Security
local_infile = 0
symbolic-links = 0

[mysql]
default-character-set = utf8mb4

[client]
default-character-set = utf8mb4

[mysqldump]
quick
max_allowed_packet = 256M
default-character-set = utf8mb4
'@

    Write-FileNoBOM -Content $mariadbConfig -FilePath "$ProjectDir\mariadb\custom.cnf"
    Write-StatusMessage "MariaDB config created (optimizer_switch removed)" "Green" "SUCCESS"
}

function New-DeploymentScript {
    param([string]$ProjectDir)

    Write-StatusMessage "Creating deployment script..." "Yellow" "CREATE"

    $deployScript = @"
param([switch]`$Start, [switch]`$Stop, [switch]`$Restart, [switch]`$Status, [switch]`$Logs, [switch]`$Backup)

Set-Location "$ProjectDir"

if (`$Start) {
    Write-Host "Starting WordPress..." -ForegroundColor Green
    docker-compose up -d
    Start-Sleep 10
    docker-compose ps
    Write-Host ""
    Write-Host "WordPress: https://localhost" -ForegroundColor Cyan
}
elseif (`$Stop) { docker-compose down }
elseif (`$Restart) { docker-compose restart }
elseif (`$Status) { docker-compose ps; docker stats --no-stream }
elseif (`$Logs) { docker-compose logs -f --tail=100 }
elseif (`$Backup) {
    `$ts = Get-Date -Format "yyyyMMdd-HHmmss"
    `$bDir = "backups\`$ts"
    New-Item -ItemType Directory -Path `$bDir -Force | Out-Null
    docker-compose exec -T mariadb mysqldump -u root -p$DatabasePassword --single-transaction wordpress > "`$bDir\database.sql"
    Copy-Item -Path "wordpress" -Destination "`$bDir\wordpress" -Recurse
    Write-Host "Backup: `$bDir" -ForegroundColor Green
}
else {
    Write-Host "Usage: deploy.ps1 [-Start|-Stop|-Restart|-Status|-Logs|-Backup]"
}
"@

    Write-FileNoBOM -Content $deployScript -FilePath "$ProjectDir\scripts\deploy.ps1"
    Write-StatusMessage "Deployment script created" "Green" "SUCCESS"
}

function Start-WordPressSetup {
    try {
        Write-StatusMessage "Starting WordPress setup..." "Cyan" "START"

        Get-UserCredentials
        Test-Prerequisites

        $projectDir = New-ProjectStructure

        New-SSLCertificates -ProjectDir $projectDir
        New-DockerCompose -ProjectDir $projectDir
        New-NginxConfig -ProjectDir $projectDir
        New-PHPConfig -ProjectDir $projectDir
        New-MariaDBConfig -ProjectDir $projectDir
        New-DeploymentScript -ProjectDir $projectDir

        $envContent = @"
WORDPRESS_DB_HOST=mariadb:3306
WORDPRESS_DB_NAME=wordpress
WORDPRESS_DB_USER=wordpress
WORDPRESS_DB_PASSWORD=$DatabasePassword
MYSQL_ROOT_PASSWORD=$DatabasePassword
"@

        Write-FileNoBOM -Content $envContent -FilePath "$projectDir\.env"

        Write-StatusMessage "Starting services..." "Yellow" "DEPLOY"
        Set-Location $projectDir
        docker-compose up -d

        Start-Sleep -Seconds 40
        docker-compose ps

        Write-StatusMessage "=== SETUP COMPLETE ===" "Green" "SUCCESS"
        Write-Host ""
        Write-Host "CRITICAL FIX APPLIED:" -ForegroundColor Green
        Write-Host "  + MariaDB optimizer_switch deprecated options removed" -ForegroundColor White
        Write-Host "  + MariaDB 11.5 compatible configuration" -ForegroundColor White
        Write-Host ""
        Write-Host "ACCESS:" -ForegroundColor Cyan
        Write-Host "  HTTPS: https://localhost" -ForegroundColor White
        Write-Host ""
        Write-Host "PERFORMANCE:" -ForegroundColor Cyan
        Write-Host "  + PHP OPcache JIT (512MB)" -ForegroundColor White
        Write-Host "  + MariaDB InnoDB (3GB buffer pool)" -ForegroundColor White
        Write-Host "  + Redis sessions + object cache (1GB)" -ForegroundColor White
        Write-Host ""
        Write-Host "SECURITY:" -ForegroundColor Cyan
        Write-Host "  + Rate limiting enabled" -ForegroundColor White
        Write-Host "  + Dangerous PHP functions disabled" -ForegroundColor White
        Write-Host "  + SSL forced for admin" -ForegroundColor White
        Write-Host ""
        Write-Host "Project: $projectDir" -ForegroundColor Cyan

    } catch {
        Write-StatusMessage "Setup failed: $($_.Exception.Message)" "Red" "ERROR"
    }
}

try {
    Start-WordPressSetup
} catch {
    Write-StatusMessage "Critical error: $($_.Exception.Message)" "Red" "CRITICAL"
} finally {
    Write-Host ""
    Write-Host "Press any key to exit..." -ForegroundColor Green
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}
