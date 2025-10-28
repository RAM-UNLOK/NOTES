# WordPress Docker Stack - Complete Installation Guide 2025

## 📋 Table of Contents

- [Prerequisites](#prerequisites)
- [Quick Start Installation](#quick-start-installation)
- [Manual Configuration](#manual-configuration)
- [File Structure](#file-structure)
- [Management Commands](#management-commands)
- [Security Features](#security-features)
- [Performance Features](#performance-features)
- [Troubleshooting](#troubleshooting)
- [Advanced Configuration](#advanced-configuration)
- [Maintenance](#maintenance)

***

## Prerequisites

### System Requirements

| Component | Requirement |
|-----------|-------------|
| **OS** | Windows 11 (64-bit) |
| **RAM** | 8GB minimum, 16GB recommended |
| **Storage** | 20GB free disk space |
| **Privileges** | Administrator access required |
| **Network** | Internet connection for downloads |

### Required Software

#### 1. Docker Desktop for Windows
```powershell
# Download from: https://www.docker.com/products/docker-desktop/
# After installation, configure:
# - Enable WSL 2 backend
# - Allocate 4GB+ RAM to Docker
# - Enable file sharing for project directory
```

#### 2. PowerShell (Pre-installed)
```powershell
# Check PowerShell version
$PSVersionTable.PSVersion

# Enable script execution (run as Administrator)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine
```

#### 3. OpenSSL (Optional)
```powershell
# Download from: https://slproweb.com/products/Win32OpenSSL.html
# Or install via Chocolatey:
choco install openssl

# Verify installation:
openssl version
```

### Latest Stack Versions (2025)

- **NGINX**: `1.28-alpine` (Latest stable)
- **PHP**: `8.4-fpm-alpine` (Latest with JIT)
- **MariaDB**: `11.8` (LTS with Vector support)
- **WordPress**: `latest` (Auto-updated)
- **Redis**: `7-alpine` (Object caching)

***

## Quick Start Installation

### Step 1: Setup Project Directory

```powershell
# Create project directory
cd "C:\"
mkdir WordPress-Docker-2025
cd WordPress-Docker-2025

# Download/extract the stack files here
```

### Step 2: Run Installation

#### Basic Installation (Recommended)
```powershell
# Run with default settings
.\PowerShell\setup-wordpress-docker.ps1
```

#### Custom Installation
```powershell
# Run with custom parameters
.\PowerShell\setup-wordpress-docker.ps1 `
    -ProjectName "my-wordpress" `
    -Domain "mysite.local" `
    -WordPressUser "myadmin" `
    -WordPressPassword "SecurePass123!" `
    -WordPressEmail "admin@mysite.local"
```

#### Advanced Installation Options
```powershell
# Full customization
.\PowerShell\setup-wordpress-docker.ps1 `
    -ProjectName "production-site" `
    -Domain "mycompany.local" `
    -WordPressUser "admin" `
    -WordPressPassword "MyStrongPassword2025!" `
    -WordPressEmail "webmaster@mycompany.com" `
    -DBName "company_wp" `
    -DBUser "wp_admin" `
    -GenerateSSL `
    -Verbose
```

### Step 3: Verify Installation

```powershell
# Check container status
cd docker
docker-compose ps

# Expected output should show all services as "Up"
```

#### Access Your Site
- **WordPress Site**: https://localhost
- **WordPress Admin**: https://localhost/wp-admin  
- **phpMyAdmin**: http://localhost:8080
- **Credentials**: Check `CREDENTIALS.txt` file

***

## Manual Configuration

### Environment Variables

Edit `docker/.env` file for custom configuration:

```bash
# Project Settings
PROJECT_NAME=my-wordpress
DOMAIN=localhost

# WordPress Settings  
WORDPRESS_ADMIN_USER=admin
WORDPRESS_ADMIN_PASSWORD=your_password_here
WORDPRESS_ADMIN_EMAIL=admin@localhost.com

# Database Settings
MYSQL_ROOT_PASSWORD=root_password_here
MYSQL_DATABASE=wordpress
MYSQL_USER=wpuser
MYSQL_PASSWORD=user_password_here

# Performance Settings
PHP_MEMORY_LIMIT=512M
PHP_MAX_EXECUTION_TIME=300
PHP_UPLOAD_MAX_FILESIZE=128M
PHP_POST_MAX_SIZE=128M

# Port Settings (change if needed)
HTTP_PORT=80
HTTPS_PORT=443
MYSQL_PORT=3306
PHPMYADMIN_PORT=8080
```

### NGINX Configuration

#### Main Config: `config/nginx/nginx.conf`

```nginx
# Key settings to modify:
worker_processes auto;
worker_connections 4096;

# Adjust buffer sizes for your needs:
client_max_body_size 128m;
client_body_buffer_size 128k;

# Modify security headers:
add_header Strict-Transport-Security "max-age=31536000" always;
```

#### WordPress Config: `config/nginx/conf.d/default.conf`

```nginx
# Key areas to customize:

# Change domain
server_name your-domain.com www.your-domain.com;

# Modify SSL certificate paths
ssl_certificate /etc/ssl/certs/your-cert.crt;
ssl_certificate_key /etc/ssl/private/your-key.key;

# Adjust rate limiting
limit_req zone=wp_login burst=2 nodelay;
```

### PHP Configuration

#### Main PHP Settings: `config/php/php.ini`

```ini
# Memory and execution
memory_limit = 512M
max_execution_time = 300
max_input_vars = 3000

# File uploads
upload_max_filesize = 128M
post_max_size = 128M
max_file_uploads = 20

# OPcache + JIT (PHP 8.4)
opcache.enable = 1
opcache.memory_consumption = 512
opcache.jit = 1255
opcache.jit_buffer_size = 128M

# Security
expose_php = Off
allow_url_include = Off
```

#### PHP-FPM Pool: `config/php/www.conf`

```ini
# Process management
pm = dynamic
pm.max_children = 20
pm.start_servers = 4
pm.min_spare_servers = 2
pm.max_spare_servers = 8
pm.max_requests = 1000

# Timeouts
request_terminate_timeout = 120s
```

### MariaDB Configuration

#### Database Settings: `config/mysql/my.cnf`

```ini
[mysqld]
# Performance settings
innodb_buffer_pool_size = 512M
innodb_buffer_pool_instances = 4
max_connections = 200
query_cache_size = 128M

# Security settings  
local_infile = 0
symbolic_links = 0

# MariaDB 11.8 features
plugin_load_add = vector
optimizer_use_condition_selectivity = 4
```

***

## File Structure

### Directory Layout

```
WordPress-Docker-Stack/
│
├── 📁 docker/                     # Docker configuration
│   ├── docker-compose.yml        # Main Docker setup
│   └── .env                      # Environment variables
│
├── 📁 config/                     # Server configurations
│   ├── 📁 nginx/
│   │   ├── nginx.conf            # NGINX main config
│   │   └── conf.d/
│   │       └── default.conf      # WordPress virtual host
│   ├── 📁 php/
│   │   ├── php.ini              # PHP settings
│   │   ├── php-fpm.conf         # PHP-FPM main
│   │   ├── www.conf             # PHP-FPM pool
│   │   └── conf.d/              # Additional PHP configs
│   └── 📁 mysql/
│       ├── my.cnf               # MariaDB config
│       └── conf.d/              # Additional DB configs
│
├── 📁 wordpress/                  # WordPress files (editable)
│   ├── 📁 wp-content/
│   │   ├── 📁 themes/           # WordPress themes
│   │   ├── 📁 plugins/          # WordPress plugins
│   │   └── 📁 uploads/          # Media files
│   ├── wp-config.php            # WordPress config
│   └── [core files]             # WordPress core
│
├── 📁 ssl/                        # SSL certificates
│   ├── 📁 certificates/          # Public certs
│   └── 📁 private/               # Private keys
│
├── 📁 backups/                    # Backup storage
│   ├── 📁 database/              # DB backups
│   └── 📁 files/                 # File backups
│
├── 📁 logs/                       # Application logs
│   ├── 📁 nginx/                 # NGINX logs
│   ├── 📁 php/                   # PHP logs
│   └── 📁 mysql/                 # MariaDB logs
│
├── 📁 PowerShell/                 # Management scripts
│   ├── setup-wordpress-docker.ps1
│   ├── backup-wordpress.ps1
│   └── generate-ssl.ps1
│
└── CREDENTIALS.txt                # Login information
```

### File Access

All files are directly editable through Windows File Manager:

- **WordPress Files**: Edit directly in `wordpress/` folder
- **Themes**: `wordpress/wp-content/themes/`
- **Plugins**: `wordpress/wp-content/plugins/`
- **Media**: `wordpress/wp-content/uploads/`
- **Config Files**: Edit in respective `config/` subdirectories

***

## Management Commands

### Container Operations

#### Start/Stop Services
```powershell
# Navigate to docker directory
cd docker

# Start all services
docker-compose up -d

# Stop all services
docker-compose down

# Restart all services
docker-compose restart

# Restart specific service
docker-compose restart nginx
docker-compose restart php
docker-compose restart mariadb
```

#### Container Status
```powershell
# View container status
docker-compose ps

# View resource usage
docker stats

# View container details
docker inspect wordpress-docker_nginx
```

#### Update Containers
```powershell
# Pull latest images
docker-compose pull

# Recreate containers with new images
docker-compose up -d --force-recreate

# Remove old unused images
docker image prune -f
```

### Log Management

#### View Logs
```powershell
# View all service logs
docker-compose logs -f

# View specific service logs
docker-compose logs -f nginx
docker-compose logs -f php  
docker-compose logs -f mariadb
docker-compose logs -f phpmyadmin

# View last 50 lines
docker-compose logs --tail=50 nginx

# View logs since timestamp
docker-compose logs --since="2025-10-28T00:00:00" php
```

#### Access Log Files Directly
```powershell
# NGINX logs
Get-Content .\logs\nginx\access.log -Tail 50 -Wait
Get-Content .\logs\nginx\error.log -Tail 50 -Wait

# PHP logs
Get-Content .\logs\php\error.log -Tail 50 -Wait
Get-Content .\logs\php\slow.log -Tail 50 -Wait

# MariaDB logs
Get-Content .\logs\mysql\error.log -Tail 50 -Wait
Get-Content .\logs\mysql\mysql-slow.log -Tail 50 -Wait
```

### Backup Operations

#### Automated Backups
```powershell
# Full backup (database + files)
.\PowerShell\backup-wordpress.ps1

# Database only
.\PowerShell\backup-wordpress.ps1 -DatabaseOnly

# Files only  
.\PowerShell\backup-wordpress.ps1 -FilesOnly

# Custom backup location
.\PowerShell\backup-wordpress.ps1 -BackupPath "D:\MyBackups"

# With custom retention period
.\PowerShell\backup-wordpress.ps1 -RetentionDays 60

# Verbose output
.\PowerShell\backup-wordpress.ps1 -Verbose
```

#### Manual Database Operations
```powershell
# Export database
docker exec wordpress-docker_mariadb mysqldump -u root -p wordpress > backup.sql

# Import database  
docker exec -i wordpress-docker_mariadb mysql -u root -p wordpress < backup.sql

# Access MySQL command line
docker exec -it wordpress-docker_mariadb mysql -u root -p

# Check database size
docker exec wordpress-docker_mariadb mysql -u root -p -e "SELECT table_schema AS 'Database', ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS 'Size (MB)' FROM information_schema.tables WHERE table_schema = 'wordpress';"
```

### SSL Certificate Management

#### Generate SSL Certificates
```powershell
# Generate certificates for localhost
.\PowerShell\generate-ssl.ps1

# Generate for custom domain
.\PowerShell\generate-ssl.ps1 -Domain "mysite.local"

# Custom validity period (default: 730 days)
.\PowerShell\generate-ssl.ps1 -Domain "mysite.local" -ValidityDays 365

# Skip DH parameters generation (faster)
.\PowerShell\generate-ssl.ps1 -Domain "mysite.local" -GenerateDH:$false
```

#### Certificate Information
```powershell
# View certificate details
openssl x509 -in .\ssl\certificates\server.crt -text -noout

# Check certificate expiry
openssl x509 -in .\ssl\certificates\server.crt -noout -dates

# Verify certificate
openssl verify .\ssl\certificates\server.crt

# Test certificate with domain
openssl s_client -connect localhost:443 -servername localhost
```

***

## Security Features

### NGINX Security

#### Security Headers Enabled
```nginx
Strict-Transport-Security: max-age=63072000; includeSubDomains; preload
X-Frame-Options: SAMEORIGIN  
X-Content-Type-Options: nosniff
X-XSS-Protection: 1; mode=block
Referrer-Policy: strict-origin-when-cross-origin
Permissions-Policy: camera=(), microphone=(), geolocation=()
```

#### Rate Limiting Protection
- **Login Attempts**: 1 request/second
- **Admin Area**: 5 requests/second  
- **REST API**: 10 requests/second
- **General Traffic**: 20 requests/second

#### File Access Control
- Blocks sensitive files (`.htaccess`, `.conf`, `.log`, `.sql`)
- Prevents PHP execution in upload directories
- Restricts WordPress config file access
- Blocks hidden files and directories

### PHP Security

#### Security Settings
```ini
expose_php = Off
allow_url_include = Off
file_uploads = On (restricted)
open_basedir = /var/www/html:/tmp
```

#### Session Security
```ini
session.cookie_httponly = On
session.cookie_secure = On  
session.cookie_samesite = "Strict"
session.use_strict_mode = On
```

### MariaDB Security

#### Access Control
- Limited user privileges
- Disabled local file loading
- Secure root password (auto-generated)
- Network access restricted to container network

#### Security Settings
```ini
local_infile = 0
symbolic_links = 0
secure_file_priv = /tmp
skip_show_database
```

***

## Performance Features

### NGINX Performance

#### Caching Enabled
- **FastCGI Cache**: Full-page caching for WordPress
- **Static File Cache**: Long-term caching for assets
- **Browser Cache**: Optimized cache headers

#### Compression
- **Gzip**: Enabled for text-based files
- **Compression Level**: 6 (balanced)
- **Minimum Size**: 1KB files

#### HTTP/2 Support
```nginx
listen 443 ssl http2;
```

### PHP Performance

#### OPcache + JIT (PHP 8.4)
```ini
opcache.enable = 1
opcache.memory_consumption = 512
opcache.jit = 1255
opcache.jit_buffer_size = 128M
opcache.max_accelerated_files = 10000
```

#### Process Management
```ini
pm = dynamic
pm.max_children = 20
pm.start_servers = 4
pm.process_idle_timeout = 30s
```

### MariaDB Performance

#### Buffer Pool Optimization
```ini
innodb_buffer_pool_size = 512M
innodb_buffer_pool_instances = 4
```

#### Query Cache
```ini
query_cache_type = 1
query_cache_size = 128M
query_cache_limit = 4M
```

### Redis Caching

#### Object Cache Available
```powershell
# Redis is available for WordPress object caching
# Install WordPress Redis plugin for full integration
```

***

## Troubleshooting

### Common Issues

#### Docker Desktop Not Running
```powershell
# Check Docker status
docker --version
docker ps

# Start Docker Desktop manually from Start Menu
# Or restart Docker service:
Restart-Service docker
```

#### Port Conflicts
```powershell
# Check what's using ports
netstat -an | findstr ":80"
netstat -an | findstr ":443"  
netstat -an | findstr ":3306"

# Solution: Change ports in .env file
HTTP_PORT=8080
HTTPS_PORT=8443
MYSQL_PORT=3307
```

#### Container Won't Start
```powershell
# Check container logs
docker-compose logs nginx
docker-compose logs php
docker-compose logs mariadb

# Common solutions:
# 1. Restart Docker Desktop
# 2. Check disk space
# 3. Verify file permissions
# 4. Remove containers and restart:
docker-compose down -v
docker-compose up -d
```

#### SSL Certificate Issues
```powershell
# Regenerate certificates
.\PowerShell\generate-ssl.ps1

# Check certificate files exist
ls .\ssl\certificates\
ls .\ssl\private\

# Verify NGINX can read certificates
docker exec wordpress-docker_nginx ls -la /etc/ssl/certs/
docker exec wordpress-docker_nginx ls -la /etc/ssl/private/
```

#### WordPress Issues
```powershell
# Check WordPress files
ls .\wordpress\

# Reset WordPress (keeps database)
docker-compose exec php wp core download --force --allow-root

# Check WordPress status
docker exec wordpress-docker_php wp core is-installed --allow-root
```

#### Database Connection Issues
```powershell
# Test database connection
docker exec wordpress-docker_mariadb mysql -u root -p -e "SHOW DATABASES;"

# Check WordPress database config
docker exec wordpress-docker_php wp config get --allow-root

# Reset database password in .env file, then:
docker-compose down
docker-compose up -d
```

### Performance Issues

#### Slow Website Loading
```powershell
# Check container resources
docker stats

# Increase Docker memory allocation:
# Docker Desktop → Settings → Resources → Advanced
# Increase Memory to 8GB+

# Check cache status
curl -I https://localhost | grep -i cache
```

#### High Memory Usage
```powershell
# Check PHP memory usage
docker exec wordpress-docker_php php -i | grep memory_limit

# Optimize in config/php/php.ini:
memory_limit = 256M  # Reduce if needed
opcache.memory_consumption = 256  # Reduce if needed
```

### Log Analysis

#### Error Investigation
```powershell
# Check all error logs
Get-Content .\logs\nginx\error.log -Tail 50
Get-Content .\logs\php\error.log -Tail 50  
Get-Content .\logs\mysql\error.log -Tail 50

# Search for specific errors
Select-String "error" .\logs\nginx\error.log | Select-Object -Last 10
Select-String "fatal" .\logs\php\error.log | Select-Object -Last 10
```

***

## Advanced Configuration

### Custom Domain Setup

#### Windows Hosts File
```powershell
# Edit hosts file (as Administrator)
notepad C:\Windows\System32\drivers\etc\hosts

# Add entry:
127.0.0.1    mysite.local
127.0.0.1    www.mysite.local
```

#### Update Configuration
```powershell
# Update .env file
DOMAIN=mysite.local

# Regenerate SSL certificates
.\PowerShell\generate-ssl.ps1 -Domain "mysite.local"

# Restart containers
docker-compose down
docker-compose up -d
```

### WordPress Multisite

#### Enable Multisite
```powershell
# Add to wp-config.php
docker exec wordpress-docker_php wp config set WP_ALLOW_MULTISITE true --raw --allow-root

# Install multisite
docker exec wordpress-docker_php wp core multisite-install --title="My Network" --allow-root
```

### Custom PHP Extensions

#### Add Extensions via Dockerfile
Create `config/php/Dockerfile`:
```dockerfile
FROM wordpress:8.4-fpm-alpine

# Install additional extensions
RUN apk add --no-cache imagemagick-dev
RUN docker-php-ext-install imagick

# Install Redis extension
RUN pecl install redis
RUN docker-php-ext-enable redis
```

#### Update docker-compose.yml
```yaml
php:
  build:
    context: ./config/php
    dockerfile: Dockerfile
  # ... rest of configuration
```

### Database Optimization

#### Optimize Tables
```powershell
# Optimize all WordPress tables
docker exec wordpress-docker_mariadb mysql -u root -p wordpress -e "OPTIMIZE TABLE wp_posts, wp_postmeta, wp_options;"

# Check table sizes
docker exec wordpress-docker_mariadb mysql -u root -p wordpress -e "SELECT table_name, ROUND(((data_length + index_length) / 1024 / 1024), 2) AS 'Size (MB)' FROM information_schema.tables WHERE table_schema = 'wordpress' ORDER BY (data_length + index_length) DESC;"
```

### Monitoring Setup

#### Enable Status Pages
```nginx
# Add to nginx configuration
location /nginx-status {
    stub_status on;
    access_log off;
    allow 127.0.0.1;
    deny all;
}
```

```powershell
# Check NGINX status
curl http://localhost/nginx-status

# Check PHP-FPM status  
curl http://localhost/php-fpm-status
```

***

## Maintenance

### Daily Tasks
```powershell
# Check container health
docker-compose ps

# Monitor logs for errors
docker-compose logs --tail=50 | Select-String "error|warning|fatal"

# Verify backup completion
ls .\backups\ | Sort-Object LastWriteTime -Descending | Select-Object -First 5
```

### Weekly Tasks
```powershell
# Update WordPress core, themes, plugins
docker exec wordpress-docker_php wp core update --allow-root
docker exec wordpress-docker_php wp plugin update --all --allow-root  
docker exec wordpress-docker_php wp theme update --all --allow-root

# Optimize database
docker exec wordpress-docker_mariadb mysql -u root -p wordpress -e "OPTIMIZE TABLE wp_options, wp_posts, wp_postmeta;"

# Clean up old logs
Get-ChildItem .\logs\ -Recurse -File | Where-Object {$_.LastWriteTime -lt (Get-Date).AddDays(-7)} | Remove-Item
```

### Monthly Tasks
```powershell
# Update Docker images
docker-compose pull
docker-compose up -d --force-recreate

# Test backup restore procedure
.\PowerShell\backup-wordpress.ps1
# Test restore on development environment

# Update SSL certificates if needed (before expiry)
.\PowerShell\generate-ssl.ps1 -Domain "your-domain.local"

# Security audit
docker exec wordpress-docker_php wp plugin list --status=inactive --allow-root
docker exec wordpress-docker_php wp user list --allow-root
```

### Backup Schedule
```powershell
# Create automated backup task in Windows Task Scheduler
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-File C:\WordPress-Docker-2025\PowerShell\backup-wordpress.ps1"
$trigger = New-ScheduledTaskTrigger -Daily -At 2:00AM
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
Register-ScheduledTask -TaskName "WordPress Docker Backup" -Action $action -Trigger $trigger -Settings $settings -Description "Daily WordPress Docker backup"
```

***

## Support Resources

### Documentation Links
- [WordPress Codex](https://codex.wordpress.org/)
- [Docker Compose Reference](https://docs.docker.com/compose/)
- [NGINX Documentation](https://nginx.org/en/docs/)
- [MariaDB Knowledge Base](https://mariadb.com/kb/en/)
- [PHP 8.4 Documentation](https://www.php.net/docs.php)

### Community Support
- [WordPress Support Forums](https://wordpress.org/support/)
- [Docker Community](https://forums.docker.com/)
- [Stack Overflow WordPress](https://stackoverflow.com/questions/tagged/wordpress)

### Emergency Recovery
```powershell
# If everything fails, complete reset:
docker-compose down -v --remove-orphans
docker system prune -af --volumes
.\PowerShell\setup-wordpress-docker.ps1

# Restore from backup:
# 1. Restore files: Extract backup to wordpress/ folder  
# 2. Restore database: Import SQL backup via phpMyAdmin
# 3. Update wp-config.php with new database credentials
```

***

**WordPress Docker Stack 2025 - Complete Installation Guide**  
*Optimized for Windows 11 with latest stable versions*