# WordPress Docker Setup - Complete Production Guide

## 📋 Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Installation Steps](#installation-steps)
- [Accessing WordPress](#accessing-wordpress)
- [Management Commands](#management-commands)
- [Manual Configuration](#manual-configuration)
- [Troubleshooting](#troubleshooting)
- [Optional Optimizations](#optional-optimizations)
- [Performance Tuning](#performance-tuning)
- [Security Hardening](#security-hardening)
- [Backup and Maintenance](#backup-and-maintenance)
- [Advanced Configuration](#advanced-configuration)

---

## Overview

### What You're Getting

This setup provides a **production-ready WordPress environment** with:

**Tech Stack:**
- **WordPress**: 6.8 "Cecil" (April 2025 release)
- **PHP**: 8.4 with OPcache JIT compilation
- **MariaDB**: 11.5 (GA stable release)
- **NGINX**: 1.28 (latest stable, April 2025)
- **Redis**: 7.4 (object cache + session storage)

**Key Features:**
- ⚡ **High Performance**: FastCGI cache, OPcache JIT, Redis caching
- 🛡️ **Enterprise Security**: Rate limiting, disabled dangerous functions, forced SSL
- 🔧 **Production Ready**: Resource limits, health checks, logging
- 📦 **Fully Automated**: One script setup, easy management

---

## Prerequisites

### System Requirements

**Minimum:**
- Windows 11 (or Windows 10 with WSL2)
- 8GB RAM
- 20GB free disk space
- Docker Desktop for Windows

**Recommended:**
- Windows 11
- 16GB RAM
- 50GB free disk space (for backups)
- SSD storage

### Software Requirements

1. **Docker Desktop**
   - Download: [https://www.docker.com/products/docker-desktop](https://www.docker.com/products/docker-desktop)
   - Version: 4.x or newer
   - Enable WSL2 backend

2. **PowerShell**
   - Version: 5.1 or newer (built into Windows)
   - Run as Administrator (for some operations)

3. **Git** (Optional - for SSL generation)
   - Download: [https://git-scm.com/download/win](https://git-scm.com/download/win)
   - Includes OpenSSL for better certificate generation

---

## Quick Start

### 1. Download the Setup Script

Download the file: **`WordPress-Docker-Setup-PRODUCTION-READY.ps1`**

### 2. Run the Script

```powershell
# Open PowerShell (right-click > Run as Administrator)
cd C:\path\to\script\location

# Run the script
.\WordPress-Docker-Setup-PRODUCTION-READY.ps1
```

### 3. Provide Credentials

When prompted, enter:
- WordPress Admin Username
- WordPress Admin Password
- WordPress Admin Email
- Database Root Password

### 4. Wait for Installation

The script will:
1. Check prerequisites
2. Create project structure
3. Generate SSL certificates
4. Create configuration files
5. Start all Docker containers

**Total time**: ~2-3 minutes

### 5. Access WordPress

Visit: **https://localhost/wp-admin/install.php**

Accept the SSL certificate warning (self-signed certificate) and complete the installation.

---

## Installation Steps

### Detailed Installation Process

#### Step 1: Prepare Your Environment

1. **Install Docker Desktop**
   ```powershell
   # Via winget
   winget install --id=Docker.DockerDesktop

   # Or download from docker.com
   ```

2. **Start Docker Desktop**
   - Launch Docker Desktop from Start Menu
   - Wait for "Docker is running" status

3. **Verify Installation**
   ```powershell
   docker --version
   docker ps
   ```

#### Step 2: Download and Run Script

1. **Create Working Directory**
   ```powershell
   mkdir C:\WordPress-Setup
   cd C:\WordPress-Setup
   ```

2. **Place Script File**
   - Copy `WordPress-Docker-Setup-PRODUCTION-READY.ps1` to this directory

3. **Execute Script**
   ```powershell
   .\WordPress-Docker-Setup-PRODUCTION-READY.ps1
   ```

#### Step 3: Monitor Installation

Watch the console output for:
- ✅ Green "SUCCESS" messages
- ⚠️ Yellow "WARNING" messages (usually safe to ignore)
- ❌ Red "ERROR" messages (need attention)

#### Step 4: Verify Services

After installation completes, verify all services are running:

```powershell
cd wordpress-docker
docker-compose ps
```

Expected output:
```
NAME                 IMAGE                      STATUS
wordpress_mariadb    mariadb:11.5              Up (healthy)
wordpress_app        wordpress:6.8-php8.4-fpm  Up (healthy)
wordpress_nginx      nginx:1.28                Up
wordpress_redis      redis:7-alpine            Up (healthy)
```

---

## Accessing WordPress

### Initial Setup

1. **Open Browser**
   - Navigate to: `https://localhost/wp-admin/install.php`

2. **Accept SSL Warning**
   - Click "Advanced" → "Proceed to localhost (unsafe)"
   - This is normal for self-signed certificates

3. **WordPress Installation Form**
   - **Site Title**: Your site name
   - **Username**: (use the one you entered during setup)
   - **Password**: (use the one you entered during setup)
   - **Email**: (use the one you entered during setup)
   - Click "Install WordPress"

4. **Login**
   - Go to: `https://localhost/wp-login.php`
   - Enter your credentials
   - Access admin dashboard

### URLs

- **Frontend**: `http://localhost` or `https://localhost`
- **Admin Dashboard**: `https://localhost/wp-admin`
- **Login Page**: `https://localhost/wp-login.php`

---

## Management Commands

### Using the Deployment Script

All management is done via `deploy.ps1`:

```powershell
cd wordpress-docker\scripts
```

### Available Commands

#### Start Services
```powershell
.\deploy.ps1 -Start
```

#### Stop Services
```powershell
.\deploy.ps1 -Stop
```

#### Restart Services
```powershell
.\deploy.ps1 -Restart
```

#### View Status
```powershell
.\deploy.ps1 -Status
```
Shows running containers and resource usage.

#### View Logs
```powershell
.\deploy.ps1 -Logs
```
Shows real-time logs from all services.

#### Create Backup
```powershell
.\deploy.ps1 -Backup
```
Creates a timestamped backup of database and WordPress files.

---

## Manual Configuration

### Editing Configuration Files

All configuration files are in the `wordpress-docker` directory and can be edited with any text editor (Notepad++, VS Code, etc.)

#### NGINX Configuration

**Location**: `wordpress-docker\nginx\conf.d\wordpress.conf`

**Common Edits:**

1. **Change Server Name**
   ```nginx
   server_name localhost;  # Change to your domain
   ```

2. **Adjust Upload Limit**
   ```nginx
   client_max_body_size 256M;  # Change size
   ```

3. **Add Custom Redirects**
   ```nginx
   location /old-page {
       return 301 /new-page;
   }
   ```

After editing:
```powershell
docker-compose restart nginx
```

#### PHP Configuration

**Location**: `wordpress-docker\php\php-custom.ini`

**Common Edits:**

1. **Memory Limit**
   ```ini
   memory_limit = 512M  # Increase if needed
   ```

2. **Upload Limits**
   ```ini
   upload_max_filesize = 256M
   post_max_size = 256M
   ```

3. **Execution Time**
   ```ini
   max_execution_time = 300  # Increase for long-running tasks
   ```

After editing:
```powershell
docker-compose restart wordpress
```

#### MariaDB Configuration

**Location**: `wordpress-docker\mariadb\custom.cnf`

**Common Edits:**

1. **Buffer Pool Size** (adjust based on available RAM)
   ```ini
   innodb_buffer_pool_size = 3G  # Use ~50-70% of available RAM
   ```

2. **Max Connections**
   ```ini
   max_connections = 500  # Increase for high traffic
   ```

After editing:
```powershell
docker-compose restart mariadb
```

---

## Troubleshooting

### Common Issues and Fixes

#### 1. PHP Files Download Instead of Execute

**Symptom**: Visiting site downloads `.php` files instead of showing pages.

**Fix**: Check NGINX PHP handler configuration.

```nginx
# Must be in wordpress.conf
location ~ \.php$ {
    try_files $uri =404;
    fastcgi_pass php-fpm;
    # ... rest of config
}
```

Restart NGINX:
```powershell
docker-compose restart nginx
```

#### 2. MariaDB Won't Start

**Symptom**: MariaDB container keeps restarting.

**Fix**: Check logs for errors:
```powershell
docker-compose logs mariadb
```

Common causes:
- Corrupted data files → Delete `mariadb\data` folder and restart
- Invalid configuration → Check `mariadb\custom.cnf` syntax
- Insufficient memory → Reduce `innodb_buffer_pool_size`

#### 3. NGINX 502 Bad Gateway

**Symptom**: Site shows "502 Bad Gateway" error.

**Fix**: WordPress container is not running or not healthy.

```powershell
# Check WordPress status
docker-compose ps wordpress

# Restart if needed
docker-compose restart wordpress

# Check logs
docker-compose logs wordpress
```

#### 4. SSL Certificate Warnings

**Symptom**: Browser shows security warnings.

**Fix**: This is normal for self-signed certificates.

**For Production**: Use Let's Encrypt or purchase SSL certificate.

#### 5. Port Already in Use

**Symptom**: Error "port is already allocated"

**Fix**: Change ports in `docker-compose.yml`:

```yaml
nginx:
  ports:
    - "8080:80"    # Changed from 80
    - "8443:443"   # Changed from 443
```

Access via: `https://localhost:8443`

#### 6. WordPress Installation Loop

**Symptom**: Keeps redirecting to install page.

**Fix**: Database connection issue.

```powershell
# Check if MariaDB is healthy
docker-compose ps mariadb

# Verify environment variables
cat .env

# Restart all services
docker-compose down
docker-compose up -d
```

---

## Optional Optimizations

### 1. Enable FastCGI Caching

**What it does**: Caches entire PHP responses, drastically reducing load times.

**Edit**: `nginx\conf.d\wordpress.conf`

Add before `server` block:
```nginx
fastcgi_cache_path /tmp/nginx_cache levels=1:2 keys_zone=WORDPRESS:200m 
                   max_size=1g inactive=60m use_temp_path=off;
```

Inside PHP location block:
```nginx
location ~ \.php$ {
    # ... existing config ...

    # Cache settings
    set $skip_cache 0;
    if ($request_method = POST) { set $skip_cache 1; }
    if ($query_string != "") { set $skip_cache 1; }
    if ($request_uri ~* "/wp-admin/|wp-.*.php") { set $skip_cache 1; }
    if ($http_cookie ~* "wordpress_logged_in") { set $skip_cache 1; }

    fastcgi_cache_bypass $skip_cache;
    fastcgi_no_cache $skip_cache;
    fastcgi_cache WORDPRESS;
    fastcgi_cache_valid 200 60m;
    add_header X-FastCGI-Cache $upstream_cache_status;
}
```

**Impact**: 5-10x faster page loads for cached content.

### 2. Install WordPress Redis Object Cache Plugin

**What it does**: Stores WordPress database query results in Redis.

**Steps:**

1. Login to WordPress admin
2. Go to Plugins → Add New
3. Search for "Redis Object Cache"
4. Install and activate "Redis Object Cache" by Till Krüss
5. Go to Settings → Redis
6. Click "Enable Object Cache"

**Impact**: 50-80% reduction in database queries.

### 3. Enable HTTP/3 Support

**What it does**: Uses latest HTTP protocol for better performance.

**Edit**: `nginx\nginx.conf`

```nginx
http {
    # ... existing config ...

    # Enable HTTP/3
    quic_retry on;
    ssl_early_data on;
}
```

In `wordpress.conf`:
```nginx
server {
    listen 443 ssl;
    listen 443 quic reuseport;  # Add this
    http2 on;
    http3 on;  # Add this

    # ... rest of config
}
```

### 4. Add Brotli Compression

**What it does**: Better compression than gzip (20-30% better).

**Edit**: `nginx\nginx.conf`

```nginx
http {
    # ... existing gzip config ...

    # Brotli compression
    brotli on;
    brotli_comp_level 6;
    brotli_types text/plain text/css text/xml application/javascript 
                 application/json application/xml+rss;
}
```

**Note**: Requires nginx with brotli module. May need custom nginx image.

### 5. Increase Worker Processes

**What it does**: Better utilization of multi-core CPUs.

**Edit**: `nginx\nginx.conf`

```nginx
# Auto uses all CPU cores
worker_processes auto;

# Or set specific number
worker_processes 4;  # For 4-core CPU
```

### 6. Enable Connection Pooling

**What it does**: Reuses database connections for better performance.

**Edit**: `wp-config.php` (after WordPress installation)

Add:
```php
define('DB_PERSISTENT_CONNECTION', true);
```

### 7. Optimize WordPress Database

**Manual Method:**

```powershell
# Execute optimization
docker-compose exec mariadb mysql -u root -p[PASSWORD] -e "OPTIMIZE TABLE wordpress.*;" wordpress
```

**Automated Method:**

Install WP-Optimize plugin:
1. WordPress Admin → Plugins → Add New
2. Search "WP-Optimize"
3. Install and activate
4. Set up weekly auto-optimization

---

## Performance Tuning

### For High-Traffic Sites

#### 1. Increase Resource Limits

**Edit**: `docker-compose.yml`

```yaml
mariadb:
  deploy:
    resources:
      limits:
        cpus: '4.0'      # Increase from 2.0
        memory: 8G       # Increase from 4G
      reservations:
        cpus: '2.0'
        memory: 6G

wordpress:
  deploy:
    resources:
      limits:
        cpus: '4.0'      # Increase from 2.0
        memory: 4G       # Increase from 2G
```

#### 2. Tune MariaDB for Performance

**Edit**: `mariadb\custom.cnf`

For 16GB RAM system:
```ini
innodb_buffer_pool_size = 8G          # 50% of total RAM
innodb_buffer_pool_instances = 8
innodb_log_file_size = 1G              # Larger for write-heavy
innodb_io_capacity = 10000             # For SSD
innodb_io_capacity_max = 20000
```

#### 3. Optimize PHP-FPM

**Edit**: `php\www.conf`

For high concurrency:
```ini
pm = dynamic
pm.max_children = 300        # Increase
pm.start_servers = 50
pm.min_spare_servers = 25
pm.max_spare_servers = 100
pm.max_requests = 1000
```

#### 4. NGINX Worker Connections

**Edit**: `nginx\nginx.conf`

```nginx
events {
    worker_connections 16384;  # Increase from 8192
    use epoll;
    multi_accept on;
}
```

### For Memory-Constrained Systems

#### 1. Reduce Resource Allocation

**Edit**: `docker-compose.yml`

For 8GB RAM system:
```yaml
mariadb:
  command:
    - --innodb-buffer-pool-size=1G  # Reduce from 3G

redis:
  command: >
    redis-server
    --maxmemory 256mb  # Reduce from 1gb
```

#### 2. Limit PHP-FPM Workers

**Edit**: `php\www.conf`

```ini
pm.max_children = 50         # Reduce from 150
pm.start_servers = 10
pm.min_spare_servers = 5
pm.max_spare_servers = 20
```

---

## Security Hardening

### Additional Security Measures

#### 1. Change Default Ports

**Edit**: `docker-compose.yml`

```yaml
nginx:
  ports:
    - "8080:80"     # Non-standard ports
    - "8443:443"
```

#### 2. Restrict Admin Access by IP

**Edit**: `nginx\conf.d\wordpress.conf`

```nginx
location ~ ^/wp-admin/ {
    # Only allow specific IPs
    allow 192.168.1.0/24;
    deny all;

    # ... rest of config
}
```

#### 3. Add Two-Factor Authentication

Install plugin:
1. WordPress Admin → Plugins → Add New
2. Search "Two-Factor Authentication"
3. Install "Two Factor Authentication" by miniOrange

#### 4. Enable Fail2Ban Protection

**Create**: `fail2ban-wordpress.conf`

```ini
[wordpress-auth]
enabled = true
filter = wordpress-auth
logpath = /path/to/wordpress-docker/logs/nginx/access.log
maxretry = 3
bantime = 3600
```

#### 5. Hide WordPress Version

**Add to**: `wp-config.php`

```php
// Hide WordPress version
remove_action('wp_head', 'wp_generator');
```

#### 6. Disable XML-RPC (Already done in NGINX)

Verify in `wordpress.conf`:
```nginx
location = /xmlrpc.php {
    deny all;
    return 444;
}
```

#### 7. Security Headers

**Add to**: `nginx\conf.d\wordpress.conf`

```nginx
server {
    # ... existing config ...

    # Enhanced security headers
    add_header Content-Security-Policy "default-src 'self' https:; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline';" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    add_header Permissions-Policy "geolocation=(), microphone=(), camera=()" always;
}
```

---

## Backup and Maintenance

### Automated Backups

#### 1. Using Built-in Backup Command

```powershell
# Run backup
.\scripts\deploy.ps1 -Backup

# Backups are stored in: wordpress-docker\backups\[timestamp]
```

#### 2. Schedule Automated Backups (Windows Task Scheduler)

1. Open Task Scheduler
2. Create Basic Task
3. Trigger: Daily at 2:00 AM
4. Action: Start a program
   - Program: `powershell.exe`
   - Arguments: `-File C:\path\to\wordpress-docker\scripts\deploy.ps1 -Backup`

#### 3. Manual Database Backup

```powershell
# Export database
docker-compose exec mariadb mysqldump -u root -p[PASSWORD] --single-transaction wordpress > backup.sql

# Import database
docker-compose exec -T mariadb mysql -u root -p[PASSWORD] wordpress < backup.sql
```

### Maintenance Tasks

#### Weekly Tasks

1. **Update WordPress Core/Plugins**
   - Login to admin dashboard
   - Go to Dashboard → Updates
   - Update WordPress core, plugins, themes

2. **Optimize Database**
   ```powershell
   docker-compose exec mariadb mysqlcheck -u root -p[PASSWORD] --optimize --all-databases
   ```

3. **Review Logs**
   ```powershell
   # Check for errors
   .\scripts\deploy.ps1 -Logs
   ```

#### Monthly Tasks

1. **Full Backup**
   ```powershell
   .\scripts\deploy.ps1 -Backup
   ```

2. **Review Security**
   - Check failed login attempts
   - Review user accounts
   - Update passwords

3. **Performance Check**
   ```powershell
   .\scripts\deploy.ps1 -Status
   ```

#### Docker Image Updates

```powershell
# Pull latest images
docker-compose pull

# Recreate containers with new images
docker-compose up -d --force-recreate
```

---

## Advanced Configuration

### Custom Domain Setup

#### 1. Update WordPress URL

**Edit**: `.env` file (before first run)

```env
WORDPRESS_HOME=https://yourdomain.com
WORDPRESS_SITEURL=https://yourdomain.com
```

**Or after installation**, in database:
```sql
UPDATE wp_options SET option_value='https://yourdomain.com' WHERE option_name='siteurl';
UPDATE wp_options SET option_value='https://yourdomain.com' WHERE option_name='home';
```

#### 2. Update NGINX Configuration

**Edit**: `nginx\conf.d\wordpress.conf`

```nginx
server {
    listen 443 ssl;
    http2 on;
    server_name yourdomain.com www.yourdomain.com;  # Change this

    # ... rest of config
}
```

#### 3. SSL Certificate for Production

Replace self-signed certificates with real ones:

**Using Let's Encrypt:**

```powershell
# Install certbot
docker run -it --rm -v C:\wordpress-docker\nginx\ssl:/etc/letsencrypt certbot/certbot certonly --standalone -d yourdomain.com

# Update nginx config to point to new certificates
```

### Multi-Site (WordPress Multisite)

#### 1. Enable Multisite

**Edit**: `wp-config.php` (after installation)

```php
/* Multisite */
define('WP_ALLOW_MULTISITE', true);
```

#### 2. Install Network

1. Go to Tools → Network Setup
2. Choose subdomain or subdirectory
3. Follow instructions to update `wp-config.php` and `.htaccess`

#### 3. NGINX Configuration for Multisite

**Edit**: `nginx\conf.d\wordpress.conf`

Add multisite rewrite rules:
```nginx
# Multisite subdirectory
location / {
    try_files $uri $uri/ /index.php?$args;
}

# Or for subdomain multisite
server_name *.yourdomain.com;
```

### Email Configuration

#### 1. Using SMTP Plugin

Install WP Mail SMTP:
1. Plugins → Add New
2. Search "WP Mail SMTP"
3. Install and configure with your SMTP credentials

#### 2. Using External SMTP Service

**Recommended services:**
- SendGrid
- Mailgun
- Amazon SES
- Gmail SMTP

### CDN Integration

#### 1. Cloudflare Setup

1. Sign up at Cloudflare
2. Add your domain
3. Update nameservers
4. Install "Cloudflare" WordPress plugin
5. Configure caching rules

#### 2. WP Offload Media (AWS S3)

For serving media from S3:
1. Install "WP Offload Media Lite"
2. Configure AWS credentials
3. Choose S3 bucket
4. Sync existing media

### Monitoring and Analytics

#### 1. Health Check Endpoint

**Add to**: `nginx\conf.d\wordpress.conf`

```nginx
location /health {
    access_log off;
    return 200 "healthy\n";
    add_header Content-Type text/plain;
}
```

#### 2. NGINX Status Page

```nginx
location /nginx_status {
    stub_status on;
    access_log off;
    allow 127.0.0.1;
    deny all;
}
```

#### 3. PHP-FPM Status

Already configured at `/fpm-status`

Access via:
```powershell
docker-compose exec nginx curl http://wordpress:9000/fpm-status
```

---

## Appendix

### File Structure

```
wordpress-docker/
├── docker-compose.yml          # Container orchestration
├── .env                        # Environment variables
├── nginx/
│   ├── nginx.conf             # Main NGINX config
│   ├── conf.d/
│   │   └── wordpress.conf     # WordPress site config
│   └── ssl/
│       ├── cert.pem           # SSL certificate
│       └── key.pem            # SSL private key
├── php/
│   ├── php-custom.ini         # PHP performance settings
│   ├── php-security.ini       # PHP security settings
│   └── www.conf               # PHP-FPM pool config
├── mariadb/
│   ├── custom.cnf             # MariaDB configuration
│   ├── data/                  # Database files (auto-created)
│   └── logs/                  # Database logs
├── wordpress/                  # WordPress files (auto-created)
├── logs/
│   └── nginx/                 # NGINX logs
├── scripts/
│   └── deploy.ps1             # Management script
└── backups/                    # Backup storage
```

### Resource Requirements by Scale

| Site Size | RAM | CPU | Disk | Notes |
|-----------|-----|-----|------|-------|
| Small (<1K visits/day) | 4GB | 2 cores | 20GB | Default settings |
| Medium (1K-10K visits/day) | 8GB | 4 cores | 50GB | Increase buffer pools |
| Large (10K-100K visits/day) | 16GB | 8 cores | 100GB | Add caching layers |
| Enterprise (>100K visits/day) | 32GB+ | 16+ cores | 500GB+ | Multiple servers needed |

### Performance Benchmarks

**Default Configuration:**
- Page Load Time: 200-500ms (uncached)
- Page Load Time: 50-100ms (cached)
- Concurrent Users: 200-500
- Database Queries: 20-50 per page (without Redis)
- Database Queries: 5-10 per page (with Redis)

**With All Optimizations:**
- Page Load Time: 100-200ms (uncached)
- Page Load Time: 20-50ms (cached)
- Concurrent Users: 1000+
- Database Queries: 2-5 per page

### Common WordPress Plugins Recommended

**Performance:**
- WP Super Cache or W3 Total Cache
- Autoptimize (CSS/JS minification)
- Smush (image optimization)
- Redis Object Cache

**Security:**
- Wordfence Security
- Sucuri Security
- Two-Factor Authentication

**SEO:**
- Yoast SEO or Rank Math
- Google Site Kit

**Backups:**
- UpdraftPlus
- BackWPup

---

## Support and Resources

### Documentation Links

- [WordPress Codex](https://codex.wordpress.org/)
- [NGINX Documentation](https://nginx.org/en/docs/)
- [MariaDB Knowledge Base](https://mariadb.com/kb/en/)
- [PHP Documentation](https://www.php.net/docs.php)
- [Docker Documentation](https://docs.docker.com/)

### Useful Commands Reference

```powershell
# View container stats
docker stats

# View specific container logs
docker logs wordpress_nginx
docker logs wordpress_app
docker logs wordpress_mariadb
docker logs wordpress_redis

# Access container shell
docker exec -it wordpress_nginx sh
docker exec -it wordpress_app bash
docker exec -it wordpress_mariadb bash
docker exec -it wordpress_redis sh

# Clear all data and restart fresh
docker-compose down -v
docker-compose up -d

# Export/Import database
docker-compose exec mariadb mysqldump -u root -p[PASSWORD] wordpress > backup.sql
docker-compose exec -T mariadb mysql -u root -p[PASSWORD] wordpress < backup.sql
```

---

**Document Version**: 1.0  
**Last Updated**: November 2025  
**Compatibility**: Windows 11, Docker Desktop 4.x+

---

*This guide covers the complete setup, configuration, and optimization of a production-ready WordPress environment using Docker. For questions or issues, review the Troubleshooting section or consult the official documentation links.*
