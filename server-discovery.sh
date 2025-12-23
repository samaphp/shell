#!/bin/bash

#===============================================================================
# Server Discovery Script
# Purpose: Gather comprehensive server state information for migration planning
# Output: JSON report with all server details
# Author: Claude Code as per my request
#===============================================================================

set -e

# Configuration
OUTPUT_DIR="${1:-/tmp/server_discovery_$(date +%Y%m%d_%H%M%S)}"
REPORT_FILE="$OUTPUT_DIR/discovery_report.json"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Create output directory
mkdir -p "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR/raw_configs"
mkdir -p "$OUTPUT_DIR/process_analysis"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Server Discovery Script${NC}"
echo -e "${GREEN}Output Directory: $OUTPUT_DIR${NC}"
echo -e "${GREEN}========================================${NC}"

#-------------------------------------------------------------------------------
# Helper Functions
#-------------------------------------------------------------------------------

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to safely get command output or return empty
safe_cmd() {
    $@ 2>/dev/null || echo ""
}

# Function to check if command exists
cmd_exists() {
    command -v "$1" &> /dev/null
}

# JSON escape function
json_escape() {
    python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))' 2>/dev/null || \
    sed 's/\\/\\\\/g; s/"/\\"/g; s/\t/\\t/g' | sed ':a;N;$!ba;s/\n/\\n/g'
}

#-------------------------------------------------------------------------------
# System Information
#-------------------------------------------------------------------------------

log_info "Gathering system information..."

# OS Information
OS_NAME=$(safe_cmd cat /etc/os-release | grep "^NAME=" | cut -d'"' -f2)
OS_VERSION=$(safe_cmd cat /etc/os-release | grep "^VERSION=" | cut -d'"' -f2)
OS_ID=$(safe_cmd cat /etc/os-release | grep "^ID=" | cut -d'=' -f2)
OS_PRETTY=$(safe_cmd cat /etc/os-release | grep "^PRETTY_NAME=" | cut -d'"' -f2)
KERNEL_VERSION=$(uname -r)
ARCHITECTURE=$(uname -m)
HOSTNAME_INFO=$(hostname -f 2>/dev/null || hostname)

# Hardware Information
CPU_MODEL=$(safe_cmd cat /proc/cpuinfo | grep "model name" | head -1 | cut -d':' -f2 | xargs)
CPU_CORES=$(nproc 2>/dev/null || echo "unknown")
TOTAL_RAM=$(free -h 2>/dev/null | grep "Mem:" | awk '{print $2}')
TOTAL_RAM_MB=$(free -m 2>/dev/null | grep "Mem:" | awk '{print $2}')

# Current Resource Usage
CPU_USAGE=$(top -bn1 2>/dev/null | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1 || echo "0")
RAM_USED=$(free -m 2>/dev/null | grep "Mem:" | awk '{print $3}')
RAM_FREE=$(free -m 2>/dev/null | grep "Mem:" | awk '{print $4}')
LOAD_AVG=$(cat /proc/loadavg | awk '{print $1", "$2", "$3}')

# Uptime
UPTIME_INFO=$(uptime -p 2>/dev/null || uptime)
UPTIME_SINCE=$(uptime -s 2>/dev/null || echo "unknown")

# Save raw system info
cat /etc/os-release > "$OUTPUT_DIR/raw_configs/os-release.txt" 2>/dev/null || true
uname -a > "$OUTPUT_DIR/raw_configs/uname.txt" 2>/dev/null || true
cat /proc/cpuinfo > "$OUTPUT_DIR/raw_configs/cpuinfo.txt" 2>/dev/null || true
cat /proc/meminfo > "$OUTPUT_DIR/raw_configs/meminfo.txt" 2>/dev/null || true
free -h > "$OUTPUT_DIR/raw_configs/memory.txt" 2>/dev/null || true

#-------------------------------------------------------------------------------
# Disk Information
#-------------------------------------------------------------------------------

log_info "Gathering disk information..."

# Disk usage
df -h > "$OUTPUT_DIR/raw_configs/disk_usage.txt" 2>/dev/null || true
lsblk -o NAME,SIZE,TYPE,MOUNTPOINT,FSTYPE > "$OUTPUT_DIR/raw_configs/block_devices.txt" 2>/dev/null || true

# Get disk info as structured data
DISK_INFO=$(df -BM --output=source,fstype,size,used,avail,pcent,target 2>/dev/null | tail -n +2 | \
    awk 'BEGIN{printf "["} 
    NR>1{printf ","} 
    {gsub(/M/,"",$3); gsub(/M/,"",$4); gsub(/M/,"",$5); gsub(/%/,"",$6);
     printf "{\"device\":\"%s\",\"fstype\":\"%s\",\"size_mb\":%s,\"used_mb\":%s,\"avail_mb\":%s,\"use_percent\":%s,\"mount\":\"%s\"}", 
     $1,$2,$3,$4,$5,$6,$7} 
    END{printf "]"}')

# Inodes usage
df -i > "$OUTPUT_DIR/raw_configs/inode_usage.txt" 2>/dev/null || true

#-------------------------------------------------------------------------------
# Network Configuration
#-------------------------------------------------------------------------------

log_info "Gathering network configuration..."

# IP addresses
ip addr > "$OUTPUT_DIR/raw_configs/ip_addresses.txt" 2>/dev/null || ifconfig > "$OUTPUT_DIR/raw_configs/ip_addresses.txt" 2>/dev/null || true

# Routing table
ip route > "$OUTPUT_DIR/raw_configs/routing_table.txt" 2>/dev/null || route -n > "$OUTPUT_DIR/raw_configs/routing_table.txt" 2>/dev/null || true

# DNS configuration
cat /etc/resolv.conf > "$OUTPUT_DIR/raw_configs/resolv.conf" 2>/dev/null || true
cat /etc/hosts > "$OUTPUT_DIR/raw_configs/hosts.txt" 2>/dev/null || true

# Get primary IP
PRIMARY_IP=$(ip route get 1 2>/dev/null | awk '{print $7;exit}' || hostname -I 2>/dev/null | awk '{print $1}')

# Get all IPs
ALL_IPS=$(hostname -I 2>/dev/null || ip addr | grep 'inet ' | awk '{print $2}' | cut -d'/' -f1 | tr '\n' ' ')

#-------------------------------------------------------------------------------
# Open Ports
#-------------------------------------------------------------------------------

log_info "Scanning open ports..."

# Listening ports with process info
if cmd_exists ss; then
    ss -tlnp > "$OUTPUT_DIR/raw_configs/listening_ports_tcp.txt" 2>/dev/null || true
    ss -ulnp > "$OUTPUT_DIR/raw_configs/listening_ports_udp.txt" 2>/dev/null || true
    
    # Structured port data
    LISTENING_PORTS=$(ss -tlnp 2>/dev/null | tail -n +2 | awk '
    BEGIN{printf "["}
    NR>1{printf ","}
    {
        port=$4; sub(/.*:/,"",port);
        process=$6; gsub(/"/,"",process);
        printf "{\"protocol\":\"tcp\",\"address\":\"%s\",\"port\":\"%s\",\"process\":\"%s\"}", $4, port, process
    }
    END{printf "]"}')
elif cmd_exists netstat; then
    netstat -tlnp > "$OUTPUT_DIR/raw_configs/listening_ports_tcp.txt" 2>/dev/null || true
    netstat -ulnp > "$OUTPUT_DIR/raw_configs/listening_ports_udp.txt" 2>/dev/null || true
    LISTENING_PORTS="[]"
else
    LISTENING_PORTS="[]"
fi

#-------------------------------------------------------------------------------
# Firewall Configuration
#-------------------------------------------------------------------------------

log_info "Gathering firewall configuration..."

FIREWALL_TYPE="none"
FIREWALL_ACTIVE="false"
FIREWALL_RULES=""

# Check iptables
if cmd_exists iptables; then
    iptables -L -n -v > "$OUTPUT_DIR/raw_configs/iptables_filter.txt" 2>/dev/null || true
    iptables -t nat -L -n -v > "$OUTPUT_DIR/raw_configs/iptables_nat.txt" 2>/dev/null || true
    iptables-save > "$OUTPUT_DIR/raw_configs/iptables_save.txt" 2>/dev/null || true
    
    IPTABLES_RULES=$(iptables -L -n 2>/dev/null | grep -c -v "^Chain\|^target\|^$" || echo "0")
    if [ "$IPTABLES_RULES" -gt 0 ]; then
        FIREWALL_TYPE="iptables"
        FIREWALL_ACTIVE="true"
    fi
fi

# Check nftables
if cmd_exists nft; then
    nft list ruleset > "$OUTPUT_DIR/raw_configs/nftables.txt" 2>/dev/null || true
    if [ -s "$OUTPUT_DIR/raw_configs/nftables.txt" ]; then
        FIREWALL_TYPE="nftables"
        FIREWALL_ACTIVE="true"
    fi
fi

# Check UFW
if cmd_exists ufw; then
    ufw status verbose > "$OUTPUT_DIR/raw_configs/ufw_status.txt" 2>/dev/null || true
    UFW_STATUS=$(ufw status 2>/dev/null | head -1)
    if echo "$UFW_STATUS" | grep -q "active"; then
        FIREWALL_TYPE="ufw"
        FIREWALL_ACTIVE="true"
    fi
fi

# Check firewalld
if cmd_exists firewall-cmd; then
    firewall-cmd --list-all > "$OUTPUT_DIR/raw_configs/firewalld.txt" 2>/dev/null || true
    firewall-cmd --list-all-zones > "$OUTPUT_DIR/raw_configs/firewalld_zones.txt" 2>/dev/null || true
    if firewall-cmd --state 2>/dev/null | grep -q "running"; then
        FIREWALL_TYPE="firewalld"
        FIREWALL_ACTIVE="true"
    fi
fi

#-------------------------------------------------------------------------------
# Web Servers Detection
#-------------------------------------------------------------------------------

log_info "Detecting web servers..."

# NGINX
NGINX_INSTALLED="false"
NGINX_RUNNING="false"
NGINX_VERSION=""
NGINX_VHOSTS="[]"
NGINX_VHOST_COUNT=0

if cmd_exists nginx; then
    NGINX_INSTALLED="true"
    NGINX_VERSION=$(nginx -v 2>&1 | cut -d'/' -f2)
    
    if pgrep -x nginx > /dev/null 2>&1; then
        NGINX_RUNNING="true"
    fi
    
    # Get nginx configuration path
    NGINX_CONF_PATH=$(nginx -V 2>&1 | grep -o '\-\-conf-path=[^ ]*' | cut -d'=' -f2 || echo "/etc/nginx/nginx.conf")
    NGINX_PREFIX=$(dirname $(dirname "$NGINX_CONF_PATH"))
    
    # Copy nginx configs
    mkdir -p "$OUTPUT_DIR/raw_configs/nginx"
    cp -r /etc/nginx/* "$OUTPUT_DIR/raw_configs/nginx/" 2>/dev/null || true
    
    # Parse vhosts from sites-enabled
    if [ -d "/etc/nginx/sites-enabled" ]; then
        NGINX_VHOST_COUNT=$(ls -1 /etc/nginx/sites-enabled/ 2>/dev/null | wc -l)
        
        NGINX_VHOSTS="["
        first=true
        for vhost in /etc/nginx/sites-enabled/*; do
            if [ -f "$vhost" ]; then
                vhost_name=$(basename "$vhost")
                server_names=$(grep -h "server_name" "$vhost" 2>/dev/null | sed 's/server_name//g; s/;//g' | xargs | head -1)
                root_dir=$(grep -h "root" "$vhost" 2>/dev/null | head -1 | awk '{print $2}' | tr -d ';')
                listen_port=$(grep -h "listen" "$vhost" 2>/dev/null | head -1 | awk '{print $2}' | tr -d ';')
                ssl_enabled="false"
                if grep -q "ssl" "$vhost" 2>/dev/null; then
                    ssl_enabled="true"
                fi
                
                if [ "$first" = true ]; then
                    first=false
                else
                    NGINX_VHOSTS="$NGINX_VHOSTS,"
                fi
                NGINX_VHOSTS="$NGINX_VHOSTS{\"config_file\":\"$vhost_name\",\"server_names\":\"$server_names\",\"root\":\"$root_dir\",\"listen\":\"$listen_port\",\"ssl\":$ssl_enabled}"
            fi
        done
        NGINX_VHOSTS="$NGINX_VHOSTS]"
    fi
    
    # Also check conf.d
    if [ -d "/etc/nginx/conf.d" ]; then
        NGINX_CONFD_COUNT=$(ls -1 /etc/nginx/conf.d/*.conf 2>/dev/null | wc -l)
        NGINX_VHOST_COUNT=$((NGINX_VHOST_COUNT + NGINX_CONFD_COUNT))
    fi
    
    # Test nginx configuration
    nginx -t > "$OUTPUT_DIR/raw_configs/nginx/config_test.txt" 2>&1 || true
fi

# APACHE
APACHE_INSTALLED="false"
APACHE_RUNNING="false"
APACHE_VERSION=""
APACHE_VHOSTS="[]"
APACHE_VHOST_COUNT=0
APACHE_CMD=""

# Detect apache command (apache2 or httpd)
if cmd_exists apache2; then
    APACHE_CMD="apache2"
elif cmd_exists httpd; then
    APACHE_CMD="httpd"
fi

if [ -n "$APACHE_CMD" ]; then
    APACHE_INSTALLED="true"
    APACHE_VERSION=$($APACHE_CMD -v 2>/dev/null | head -1 | awk '{print $3}' | cut -d'/' -f2)
    
    if pgrep -x "$APACHE_CMD" > /dev/null 2>&1 || pgrep -x "apache2" > /dev/null 2>&1 || pgrep -x "httpd" > /dev/null 2>&1; then
        APACHE_RUNNING="true"
    fi
    
    # Copy apache configs
    mkdir -p "$OUTPUT_DIR/raw_configs/apache"
    if [ -d "/etc/apache2" ]; then
        cp -r /etc/apache2/* "$OUTPUT_DIR/raw_configs/apache/" 2>/dev/null || true
        APACHE_CONF_DIR="/etc/apache2"
    elif [ -d "/etc/httpd" ]; then
        cp -r /etc/httpd/* "$OUTPUT_DIR/raw_configs/apache/" 2>/dev/null || true
        APACHE_CONF_DIR="/etc/httpd"
    fi
    
    # Parse vhosts
    if [ -d "$APACHE_CONF_DIR/sites-enabled" ]; then
        APACHE_VHOST_COUNT=$(ls -1 $APACHE_CONF_DIR/sites-enabled/*.conf 2>/dev/null | wc -l)
        
        APACHE_VHOSTS="["
        first=true
        for vhost in $APACHE_CONF_DIR/sites-enabled/*.conf; do
            if [ -f "$vhost" ]; then
                vhost_name=$(basename "$vhost")
                server_name=$(grep -h "ServerName" "$vhost" 2>/dev/null | head -1 | awk '{print $2}')
                doc_root=$(grep -h "DocumentRoot" "$vhost" 2>/dev/null | head -1 | awk '{print $2}' | tr -d '"')
                server_aliases=$(grep -h "ServerAlias" "$vhost" 2>/dev/null | sed 's/ServerAlias//g' | xargs)
                ssl_enabled="false"
                if grep -qE "SSLEngine|:443" "$vhost" 2>/dev/null; then
                    ssl_enabled="true"
                fi
                
                if [ "$first" = true ]; then
                    first=false
                else
                    APACHE_VHOSTS="$APACHE_VHOSTS,"
                fi
                APACHE_VHOSTS="$APACHE_VHOSTS{\"config_file\":\"$vhost_name\",\"server_name\":\"$server_name\",\"document_root\":\"$doc_root\",\"server_aliases\":\"$server_aliases\",\"ssl\":$ssl_enabled}"
            fi
        done
        APACHE_VHOSTS="$APACHE_VHOSTS]"
    elif [ -d "$APACHE_CONF_DIR/conf.d" ]; then
        APACHE_VHOST_COUNT=$(ls -1 $APACHE_CONF_DIR/conf.d/*.conf 2>/dev/null | wc -l)
    fi
    
    # List enabled modules
    if cmd_exists apache2ctl; then
        apache2ctl -M > "$OUTPUT_DIR/raw_configs/apache/modules.txt" 2>/dev/null || true
    elif cmd_exists apachectl; then
        apachectl -M > "$OUTPUT_DIR/raw_configs/apache/modules.txt" 2>/dev/null || true
    fi
fi

#-------------------------------------------------------------------------------
# PHP Detection
#-------------------------------------------------------------------------------

log_info "Detecting PHP..."

PHP_INSTALLED="false"
PHP_VERSION=""
PHP_VERSIONS="[]"
PHP_FPM_RUNNING="false"

if cmd_exists php; then
    PHP_INSTALLED="true"
    PHP_VERSION=$(php -v 2>/dev/null | head -1 | awk '{print $2}')
    
    # Copy PHP configuration
    mkdir -p "$OUTPUT_DIR/raw_configs/php"
    php -i > "$OUTPUT_DIR/raw_configs/php/phpinfo.txt" 2>/dev/null || true
    php -m > "$OUTPUT_DIR/raw_configs/php/modules.txt" 2>/dev/null || true
    
    # Find php.ini
    PHP_INI=$(php -i 2>/dev/null | grep "Loaded Configuration File" | awk '{print $5}')
    if [ -f "$PHP_INI" ]; then
        cp "$PHP_INI" "$OUTPUT_DIR/raw_configs/php/" 2>/dev/null || true
    fi
    
    # Check for multiple PHP versions
    PHP_VERSIONS="["
    first=true
    for php_bin in /usr/bin/php*; do
        if [[ "$php_bin" =~ php[0-9] ]]; then
            ver=$($php_bin -v 2>/dev/null | head -1 | awk '{print $2}')
            if [ -n "$ver" ]; then
                if [ "$first" = true ]; then
                    first=false
                else
                    PHP_VERSIONS="$PHP_VERSIONS,"
                fi
                PHP_VERSIONS="$PHP_VERSIONS\"$ver\""
            fi
        fi
    done
    PHP_VERSIONS="$PHP_VERSIONS]"
fi

# Check PHP-FPM
if pgrep -x "php-fpm" > /dev/null 2>&1 || pgrep -f "php-fpm" > /dev/null 2>&1; then
    PHP_FPM_RUNNING="true"
    
    # Copy PHP-FPM configs
    for fpm_conf_dir in /etc/php/*/fpm /etc/php-fpm.d; do
        if [ -d "$fpm_conf_dir" ]; then
            cp -r "$fpm_conf_dir" "$OUTPUT_DIR/raw_configs/php/" 2>/dev/null || true
        fi
    done
fi

#-------------------------------------------------------------------------------
# Database Detection
#-------------------------------------------------------------------------------

log_info "Detecting databases..."

# MySQL/MariaDB
MYSQL_INSTALLED="false"
MYSQL_RUNNING="false"
MYSQL_VERSION=""
MYSQL_DATABASES="[]"
MYSQL_DB_COUNT=0

if cmd_exists mysql; then
    MYSQL_INSTALLED="true"
    MYSQL_VERSION=$(mysql --version 2>/dev/null | awk '{print $3}')
    
    if pgrep -x "mysqld" > /dev/null 2>&1 || pgrep -x "mariadbd" > /dev/null 2>&1; then
        MYSQL_RUNNING="true"
    fi
    
    # Copy MySQL configuration
    mkdir -p "$OUTPUT_DIR/raw_configs/mysql"
    for mysql_conf in /etc/mysql/my.cnf /etc/my.cnf /etc/mysql/mysql.conf.d/mysqld.cnf; do
        if [ -f "$mysql_conf" ]; then
            cp "$mysql_conf" "$OUTPUT_DIR/raw_configs/mysql/" 2>/dev/null || true
        fi
    done
    
    if [ -d "/etc/mysql" ]; then
        cp -r /etc/mysql/* "$OUTPUT_DIR/raw_configs/mysql/" 2>/dev/null || true
    fi
    
    # Try to list databases (may require credentials)
    echo "NOTE: To list databases, run: mysql -e 'SHOW DATABASES;'" > "$OUTPUT_DIR/raw_configs/mysql/db_list_note.txt"
    
    # Check if we can access without password (socket auth)
    if mysql -e "SHOW DATABASES;" 2>/dev/null > "$OUTPUT_DIR/raw_configs/mysql/databases.txt"; then
        MYSQL_DB_COUNT=$(wc -l < "$OUTPUT_DIR/raw_configs/mysql/databases.txt")
        MYSQL_DB_COUNT=$((MYSQL_DB_COUNT - 1)) # Remove header
        
        MYSQL_DATABASES="["
        first=true
        while read -r db; do
            if [ "$db" != "Database" ]; then
                if [ "$first" = true ]; then
                    first=false
                else
                    MYSQL_DATABASES="$MYSQL_DATABASES,"
                fi
                MYSQL_DATABASES="$MYSQL_DATABASES\"$db\""
            fi
        done < "$OUTPUT_DIR/raw_configs/mysql/databases.txt"
        MYSQL_DATABASES="$MYSQL_DATABASES]"
    fi
fi

# PostgreSQL
POSTGRES_INSTALLED="false"
POSTGRES_RUNNING="false"
POSTGRES_VERSION=""
POSTGRES_DATABASES="[]"
POSTGRES_DB_COUNT=0

if cmd_exists psql; then
    POSTGRES_INSTALLED="true"
    POSTGRES_VERSION=$(psql --version 2>/dev/null | awk '{print $3}')
    
    if pgrep -x "postgres" > /dev/null 2>&1; then
        POSTGRES_RUNNING="true"
    fi
    
    # Copy PostgreSQL configuration
    mkdir -p "$OUTPUT_DIR/raw_configs/postgresql"
    for pg_conf_dir in /etc/postgresql /var/lib/pgsql/data; do
        if [ -d "$pg_conf_dir" ]; then
            find "$pg_conf_dir" -name "*.conf" -exec cp {} "$OUTPUT_DIR/raw_configs/postgresql/" \; 2>/dev/null || true
        fi
    done
    
    # Try to list databases
    if sudo -u postgres psql -c "\l" 2>/dev/null > "$OUTPUT_DIR/raw_configs/postgresql/databases.txt"; then
        POSTGRES_DB_COUNT=$(grep -c "^ " "$OUTPUT_DIR/raw_configs/postgresql/databases.txt" 2>/dev/null || echo "0")
    fi
fi

# MongoDB
MONGO_INSTALLED="false"
MONGO_RUNNING="false"
MONGO_VERSION=""

if cmd_exists mongod || cmd_exists mongo; then
    MONGO_INSTALLED="true"
    MONGO_VERSION=$(mongod --version 2>/dev/null | head -1 | awk '{print $3}' | tr -d 'v')
    
    if pgrep -x "mongod" > /dev/null 2>&1; then
        MONGO_RUNNING="true"
    fi
    
    mkdir -p "$OUTPUT_DIR/raw_configs/mongodb"
    cp /etc/mongod.conf "$OUTPUT_DIR/raw_configs/mongodb/" 2>/dev/null || true
fi

# Redis
REDIS_INSTALLED="false"
REDIS_RUNNING="false"
REDIS_VERSION=""

if cmd_exists redis-server; then
    REDIS_INSTALLED="true"
    REDIS_VERSION=$(redis-server --version 2>/dev/null | awk '{print $3}' | cut -d'=' -f2)
    
    if pgrep -x "redis-server" > /dev/null 2>&1; then
        REDIS_RUNNING="true"
    fi
    
    mkdir -p "$OUTPUT_DIR/raw_configs/redis"
    cp /etc/redis/redis.conf "$OUTPUT_DIR/raw_configs/redis/" 2>/dev/null || true
    cp /etc/redis.conf "$OUTPUT_DIR/raw_configs/redis/" 2>/dev/null || true
fi

#-------------------------------------------------------------------------------
# Application Runtimes
#-------------------------------------------------------------------------------

log_info "Detecting application runtimes..."

# Node.js
NODE_INSTALLED="false"
NODE_VERSION=""
NPM_VERSION=""

if cmd_exists node; then
    NODE_INSTALLED="true"
    NODE_VERSION=$(node --version 2>/dev/null | tr -d 'v')
    NPM_VERSION=$(npm --version 2>/dev/null)
fi

# Python
PYTHON_INSTALLED="false"
PYTHON_VERSION=""
PYTHON_VERSIONS="[]"

if cmd_exists python3; then
    PYTHON_INSTALLED="true"
    PYTHON_VERSION=$(python3 --version 2>/dev/null | awk '{print $2}')
fi

# List pip packages if available
if cmd_exists pip3; then
    pip3 list > "$OUTPUT_DIR/raw_configs/python_packages.txt" 2>/dev/null || true
fi

# Ruby
RUBY_INSTALLED="false"
RUBY_VERSION=""

if cmd_exists ruby; then
    RUBY_INSTALLED="true"
    RUBY_VERSION=$(ruby --version 2>/dev/null | awk '{print $2}')
fi

# Java
JAVA_INSTALLED="false"
JAVA_VERSION=""

if cmd_exists java; then
    JAVA_INSTALLED="true"
    JAVA_VERSION=$(java -version 2>&1 | head -1 | awk -F '"' '{print $2}')
fi

# Go
GO_INSTALLED="false"
GO_VERSION=""

if cmd_exists go; then
    GO_INSTALLED="true"
    GO_VERSION=$(go version 2>/dev/null | awk '{print $3}' | tr -d 'go')
fi

#-------------------------------------------------------------------------------
# Running Processes Analysis
#-------------------------------------------------------------------------------

log_info "Analyzing running processes..."

# Get all running processes with details
ps aux > "$OUTPUT_DIR/process_analysis/ps_aux.txt" 2>/dev/null || true
ps auxf > "$OUTPUT_DIR/process_analysis/ps_tree.txt" 2>/dev/null || true

# Top processes by memory
ps aux --sort=-%mem | head -20 > "$OUTPUT_DIR/process_analysis/top_memory.txt" 2>/dev/null || true

# Top processes by CPU
ps aux --sort=-%cpu | head -20 > "$OUTPUT_DIR/process_analysis/top_cpu.txt" 2>/dev/null || true

# Detect known application processes
DETECTED_APPS="["
first=true

# Check for common web apps
for app in "node" "python" "java" "ruby" "php-fpm" "gunicorn" "uwsgi" "pm2" "supervisord" "docker" "nginx" "apache2" "httpd" "mysql" "postgres" "redis" "mongodb" "memcached" "elasticsearch" "jenkins" "tomcat" "grafana" "prometheus"; do
    if pgrep -x "$app" > /dev/null 2>&1 || pgrep -f "$app" > /dev/null 2>&1; then
        count=$(pgrep -c -f "$app" 2>/dev/null || echo "1")
        if [ "$first" = true ]; then
            first=false
        else
            DETECTED_APPS="$DETECTED_APPS,"
        fi
        DETECTED_APPS="$DETECTED_APPS{\"name\":\"$app\",\"process_count\":$count}"
    fi
done
DETECTED_APPS="$DETECTED_APPS]"

#-------------------------------------------------------------------------------
# Services and Init System
#-------------------------------------------------------------------------------

log_info "Gathering service information..."

# Detect init system
INIT_SYSTEM="unknown"
if cmd_exists systemctl; then
    INIT_SYSTEM="systemd"
    systemctl list-units --type=service --state=running > "$OUTPUT_DIR/raw_configs/running_services.txt" 2>/dev/null || true
    systemctl list-unit-files --type=service > "$OUTPUT_DIR/raw_configs/all_services.txt" 2>/dev/null || true
elif [ -f /etc/init.d ]; then
    INIT_SYSTEM="sysvinit"
    service --status-all > "$OUTPUT_DIR/raw_configs/running_services.txt" 2>/dev/null || true
fi

#-------------------------------------------------------------------------------
# Cron Jobs
#-------------------------------------------------------------------------------

log_info "Gathering cron jobs..."

mkdir -p "$OUTPUT_DIR/raw_configs/cron"

# System crontabs
cp /etc/crontab "$OUTPUT_DIR/raw_configs/cron/" 2>/dev/null || true
cp -r /etc/cron.d "$OUTPUT_DIR/raw_configs/cron/" 2>/dev/null || true
cp -r /etc/cron.daily "$OUTPUT_DIR/raw_configs/cron/" 2>/dev/null || true
cp -r /etc/cron.hourly "$OUTPUT_DIR/raw_configs/cron/" 2>/dev/null || true
cp -r /etc/cron.weekly "$OUTPUT_DIR/raw_configs/cron/" 2>/dev/null || true
cp -r /etc/cron.monthly "$OUTPUT_DIR/raw_configs/cron/" 2>/dev/null || true

# User crontabs
for user in $(cut -f1 -d: /etc/passwd); do
    crontab -l -u "$user" > "$OUTPUT_DIR/raw_configs/cron/crontab_$user.txt" 2>/dev/null || true
done

#-------------------------------------------------------------------------------
# SSL Certificates
#-------------------------------------------------------------------------------

log_info "Gathering SSL certificate information..."

mkdir -p "$OUTPUT_DIR/raw_configs/ssl"

# Check Let's Encrypt
if [ -d "/etc/letsencrypt" ]; then
    ls -la /etc/letsencrypt/live/ > "$OUTPUT_DIR/raw_configs/ssl/letsencrypt_certs.txt" 2>/dev/null || true
    
    # Get certificate expiry info
    for cert_dir in /etc/letsencrypt/live/*/; do
        if [ -f "$cert_dir/cert.pem" ]; then
            domain=$(basename "$cert_dir")
            openssl x509 -in "$cert_dir/cert.pem" -noout -dates > "$OUTPUT_DIR/raw_configs/ssl/cert_${domain}_expiry.txt" 2>/dev/null || true
        fi
    done
fi

# Check custom SSL certs in common locations
for ssl_dir in /etc/ssl /etc/pki; do
    if [ -d "$ssl_dir" ]; then
        find "$ssl_dir" -name "*.pem" -o -name "*.crt" 2>/dev/null | head -50 > "$OUTPUT_DIR/raw_configs/ssl/found_certs.txt" 2>/dev/null || true
    fi
done

#-------------------------------------------------------------------------------
# Security & Hardening Detection
#-------------------------------------------------------------------------------

log_info "Detecting security configurations..."

SECURITY_FINDINGS="["
first=true

add_finding() {
    if [ "$first" = true ]; then
        first=false
    else
        SECURITY_FINDINGS="$SECURITY_FINDINGS,"
    fi
    SECURITY_FINDINGS="$SECURITY_FINDINGS{\"category\":\"$1\",\"item\":\"$2\",\"status\":\"$3\",\"details\":\"$4\"}"
}

# SSH Configuration
if [ -f /etc/ssh/sshd_config ]; then
    cp /etc/ssh/sshd_config "$OUTPUT_DIR/raw_configs/sshd_config" 2>/dev/null || true
    
    # Check root login
    if grep -q "^PermitRootLogin no" /etc/ssh/sshd_config 2>/dev/null; then
        add_finding "ssh" "root_login" "hardened" "Root login disabled"
    else
        add_finding "ssh" "root_login" "default" "Root login may be enabled"
    fi
    
    # Check password authentication
    if grep -q "^PasswordAuthentication no" /etc/ssh/sshd_config 2>/dev/null; then
        add_finding "ssh" "password_auth" "hardened" "Password authentication disabled"
    else
        add_finding "ssh" "password_auth" "default" "Password authentication may be enabled"
    fi
    
    # Check SSH port
    SSH_PORT=$(grep "^Port" /etc/ssh/sshd_config 2>/dev/null | awk '{print $2}' || echo "22")
    add_finding "ssh" "port" "info" "SSH port: $SSH_PORT"
fi

# Fail2ban
if cmd_exists fail2ban-client; then
    add_finding "intrusion_prevention" "fail2ban" "installed" "Fail2ban is installed"
    if systemctl is-active fail2ban > /dev/null 2>&1; then
        add_finding "intrusion_prevention" "fail2ban" "active" "Fail2ban is running"
        fail2ban-client status > "$OUTPUT_DIR/raw_configs/fail2ban_status.txt" 2>/dev/null || true
    fi
fi

# SELinux
if cmd_exists getenforce; then
    SELINUX_STATUS=$(getenforce 2>/dev/null || echo "Unknown")
    add_finding "mac" "selinux" "$SELINUX_STATUS" "SELinux status"
fi

# AppArmor
if cmd_exists aa-status; then
    add_finding "mac" "apparmor" "installed" "AppArmor is installed"
    aa-status > "$OUTPUT_DIR/raw_configs/apparmor_status.txt" 2>/dev/null || true
fi

# Check for automatic updates
if [ -f /etc/apt/apt.conf.d/20auto-upgrades ]; then
    if grep -q "1" /etc/apt/apt.conf.d/20auto-upgrades 2>/dev/null; then
        add_finding "updates" "auto_updates" "enabled" "Automatic updates are enabled"
    fi
fi

SECURITY_FINDINGS="$SECURITY_FINDINGS]"

#-------------------------------------------------------------------------------
# System Resource History (if available)
#-------------------------------------------------------------------------------

log_info "Checking for historical metrics..."

mkdir -p "$OUTPUT_DIR/raw_configs/metrics"

# Check for sar data
if cmd_exists sar; then
    sar -u > "$OUTPUT_DIR/raw_configs/metrics/cpu_history.txt" 2>/dev/null || true
    sar -r > "$OUTPUT_DIR/raw_configs/metrics/memory_history.txt" 2>/dev/null || true
    sar -d > "$OUTPUT_DIR/raw_configs/metrics/disk_history.txt" 2>/dev/null || true
fi

# Check for vmstat
vmstat 1 5 > "$OUTPUT_DIR/raw_configs/metrics/vmstat.txt" 2>/dev/null || true

# Check for iostat
if cmd_exists iostat; then
    iostat -x > "$OUTPUT_DIR/raw_configs/metrics/iostat.txt" 2>/dev/null || true
fi

#-------------------------------------------------------------------------------
# Package Management
#-------------------------------------------------------------------------------

log_info "Gathering installed packages..."

# APT (Debian/Ubuntu)
if cmd_exists apt; then
    dpkg --get-selections > "$OUTPUT_DIR/raw_configs/installed_packages_dpkg.txt" 2>/dev/null || true
    apt list --installed > "$OUTPUT_DIR/raw_configs/installed_packages_apt.txt" 2>/dev/null || true
fi

# YUM/DNF (RHEL/CentOS/Fedora)
if cmd_exists dnf; then
    dnf list installed > "$OUTPUT_DIR/raw_configs/installed_packages_dnf.txt" 2>/dev/null || true
elif cmd_exists yum; then
    yum list installed > "$OUTPUT_DIR/raw_configs/installed_packages_yum.txt" 2>/dev/null || true
fi

#-------------------------------------------------------------------------------
# Docker Detection
#-------------------------------------------------------------------------------

log_info "Detecting Docker/Containers..."

DOCKER_INSTALLED="false"
DOCKER_RUNNING="false"
DOCKER_VERSION=""
DOCKER_CONTAINERS="[]"
DOCKER_IMAGES="[]"

if cmd_exists docker; then
    DOCKER_INSTALLED="true"
    DOCKER_VERSION=$(docker --version 2>/dev/null | awk '{print $3}' | tr -d ',')
    
    if docker info > /dev/null 2>&1; then
        DOCKER_RUNNING="true"
        
        mkdir -p "$OUTPUT_DIR/raw_configs/docker"
        docker ps -a > "$OUTPUT_DIR/raw_configs/docker/containers.txt" 2>/dev/null || true
        docker images > "$OUTPUT_DIR/raw_configs/docker/images.txt" 2>/dev/null || true
        docker network ls > "$OUTPUT_DIR/raw_configs/docker/networks.txt" 2>/dev/null || true
        docker volume ls > "$OUTPUT_DIR/raw_configs/docker/volumes.txt" 2>/dev/null || true
        
        # Get container details as JSON
        docker ps -a --format '{"id":"{{.ID}}","name":"{{.Names}}","image":"{{.Image}}","status":"{{.Status}}","ports":"{{.Ports}}"}' > "$OUTPUT_DIR/raw_configs/docker/containers.json" 2>/dev/null || true
    fi
fi

# Check for docker-compose files
find /home /root /opt /var/www -name "docker-compose.yml" -o -name "docker-compose.yaml" 2>/dev/null | head -20 > "$OUTPUT_DIR/raw_configs/docker/compose_files.txt" 2>/dev/null || true

#-------------------------------------------------------------------------------
# Web Application Detection
#-------------------------------------------------------------------------------

log_info "Detecting web applications..."

mkdir -p "$OUTPUT_DIR/raw_configs/webapps"

# Find WordPress installations
find /var/www -name "wp-config.php" 2>/dev/null > "$OUTPUT_DIR/raw_configs/webapps/wordpress.txt" || true

# Find Laravel installations
find /var/www -name "artisan" -type f 2>/dev/null > "$OUTPUT_DIR/raw_configs/webapps/laravel.txt" || true

# Find Node.js applications
find /var/www /home -name "package.json" -type f 2>/dev/null | head -50 > "$OUTPUT_DIR/raw_configs/webapps/nodejs.txt" || true

# Find Python applications (Django, Flask)
find /var/www /home -name "manage.py" -o -name "wsgi.py" -o -name "requirements.txt" 2>/dev/null | head -50 > "$OUTPUT_DIR/raw_configs/webapps/python.txt" || true

#-------------------------------------------------------------------------------
# Generate JSON Report
#-------------------------------------------------------------------------------

log_info "Generating JSON report..."

cat > "$REPORT_FILE" << EOF
{
  "discovery_metadata": {
    "generated_at": "$(date -Iseconds)",
    "script_version": "1.0.0",
    "hostname": "$HOSTNAME_INFO"
  },
  "system": {
    "os": {
      "name": "$OS_NAME",
      "version": "$OS_VERSION",
      "id": "$OS_ID",
      "pretty_name": "$OS_PRETTY",
      "kernel": "$KERNEL_VERSION",
      "architecture": "$ARCHITECTURE"
    },
    "hardware": {
      "cpu_model": "$CPU_MODEL",
      "cpu_cores": $CPU_CORES,
      "total_ram_mb": $TOTAL_RAM_MB
    },
    "current_usage": {
      "cpu_percent": "$CPU_USAGE",
      "ram_used_mb": $RAM_USED,
      "ram_free_mb": $RAM_FREE,
      "load_average": "$LOAD_AVG"
    },
    "uptime": {
      "pretty": "$UPTIME_INFO",
      "since": "$UPTIME_SINCE"
    },
    "init_system": "$INIT_SYSTEM"
  },
  "network": {
    "hostname": "$HOSTNAME_INFO",
    "primary_ip": "$PRIMARY_IP",
    "all_ips": "$ALL_IPS",
    "listening_ports": $LISTENING_PORTS
  },
  "firewall": {
    "type": "$FIREWALL_TYPE",
    "active": $FIREWALL_ACTIVE
  },
  "disks": $DISK_INFO,
  "web_servers": {
    "nginx": {
      "installed": $NGINX_INSTALLED,
      "running": $NGINX_RUNNING,
      "version": "$NGINX_VERSION",
      "vhost_count": $NGINX_VHOST_COUNT,
      "vhosts": $NGINX_VHOSTS
    },
    "apache": {
      "installed": $APACHE_INSTALLED,
      "running": $APACHE_RUNNING,
      "version": "$APACHE_VERSION",
      "vhost_count": $APACHE_VHOST_COUNT,
      "vhosts": $APACHE_VHOSTS
    }
  },
  "php": {
    "installed": $PHP_INSTALLED,
    "version": "$PHP_VERSION",
    "fpm_running": $PHP_FPM_RUNNING,
    "versions_available": $PHP_VERSIONS
  },
  "databases": {
    "mysql": {
      "installed": $MYSQL_INSTALLED,
      "running": $MYSQL_RUNNING,
      "version": "$MYSQL_VERSION",
      "database_count": $MYSQL_DB_COUNT,
      "databases": $MYSQL_DATABASES
    },
    "postgresql": {
      "installed": $POSTGRES_INSTALLED,
      "running": $POSTGRES_RUNNING,
      "version": "$POSTGRES_VERSION",
      "database_count": $POSTGRES_DB_COUNT
    },
    "mongodb": {
      "installed": $MONGO_INSTALLED,
      "running": $MONGO_RUNNING,
      "version": "$MONGO_VERSION"
    },
    "redis": {
      "installed": $REDIS_INSTALLED,
      "running": $REDIS_RUNNING,
      "version": "$REDIS_VERSION"
    }
  },
  "runtimes": {
    "nodejs": {
      "installed": $NODE_INSTALLED,
      "version": "$NODE_VERSION",
      "npm_version": "$NPM_VERSION"
    },
    "python": {
      "installed": $PYTHON_INSTALLED,
      "version": "$PYTHON_VERSION"
    },
    "ruby": {
      "installed": $RUBY_INSTALLED,
      "version": "$RUBY_VERSION"
    },
    "java": {
      "installed": $JAVA_INSTALLED,
      "version": "$JAVA_VERSION"
    },
    "go": {
      "installed": $GO_INSTALLED,
      "version": "$GO_VERSION"
    }
  },
  "docker": {
    "installed": $DOCKER_INSTALLED,
    "running": $DOCKER_RUNNING,
    "version": "$DOCKER_VERSION"
  },
  "detected_applications": $DETECTED_APPS,
  "security": $SECURITY_FINDINGS,
  "raw_data_location": "$OUTPUT_DIR"
}
EOF

#-------------------------------------------------------------------------------
# Summary
#-------------------------------------------------------------------------------

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Discovery Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "JSON Report: ${YELLOW}$REPORT_FILE${NC}"
echo -e "Raw Configs: ${YELLOW}$OUTPUT_DIR/raw_configs/${NC}"
echo -e "Process Analysis: ${YELLOW}$OUTPUT_DIR/process_analysis/${NC}"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo "1. Review the JSON report for a summary"
echo "2. Package this directory for analysis:"
echo "   tar -czvf server_discovery.tar.gz $OUTPUT_DIR"
echo "3. Transfer to your laptop for Claude to analyze"
echo ""

# Create a quick summary for terminal output
echo -e "${GREEN}Quick Summary:${NC}"
echo "  OS: $OS_PRETTY"
echo "  Kernel: $KERNEL_VERSION"
echo "  CPU: $CPU_CORES cores | RAM: $TOTAL_RAM"
echo "  Primary IP: $PRIMARY_IP"
echo ""
echo "  Web Servers:"
[ "$NGINX_INSTALLED" = "true" ] && echo "    - Nginx $NGINX_VERSION (Running: $NGINX_RUNNING, VHosts: $NGINX_VHOST_COUNT)"
[ "$APACHE_INSTALLED" = "true" ] && echo "    - Apache $APACHE_VERSION (Running: $APACHE_RUNNING, VHosts: $APACHE_VHOST_COUNT)"
echo ""
echo "  Databases:"
[ "$MYSQL_INSTALLED" = "true" ] && echo "    - MySQL/MariaDB $MYSQL_VERSION (Running: $MYSQL_RUNNING, DBs: $MYSQL_DB_COUNT)"
[ "$POSTGRES_INSTALLED" = "true" ] && echo "    - PostgreSQL $POSTGRES_VERSION (Running: $POSTGRES_RUNNING)"
[ "$MONGO_INSTALLED" = "true" ] && echo "    - MongoDB $MONGO_VERSION (Running: $MONGO_RUNNING)"
[ "$REDIS_INSTALLED" = "true" ] && echo "    - Redis $REDIS_VERSION (Running: $REDIS_RUNNING)"
echo ""
echo "  Firewall: $FIREWALL_TYPE (Active: $FIREWALL_ACTIVE)"
echo ""
