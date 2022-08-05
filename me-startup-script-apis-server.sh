#!/bin/bash
# Startup script for my local static api server on a PROXMOX node
# Run this as root

# Static network config:
# - Subnet: 192.168.0.0/24
# - Static Address: 192.168.0.000
# - Gateway: 192.168.0.1
# - Name servers: leave ti as an empty

apt update

# install PROXMOX guest agent, you will need to shutdown and turn-on the machine after this and enable it from PROXMOX UI in Options tab
apt install qemu-guest-agent

# This assume the user is already added, if not please adduser it
USERNAME="username"

adduser "$USERNAME" sudo >/dev/null
adduser "$USERNAME" www-data >/dev/null
adduser www-data "$USERNAME" >/dev/null
################
# Webserver
# You can clone from the project repo here, if you want to automate app installation
mkdir -p /var/www/main
chown -R ${USERNAME}:www-data /var/www/main
apt-get install nginx libssl-dev -y
# domain conf
cat <<END >/etc/nginx/sites-enabled/main.conf
server {
    listen 80;
    server_name main
    server_tokens off;
    client_max_body_size 80m;
    gzip_http_version 1.0;
    index index.html index.php;
    root /var/www/main;
    location = /favicon.ico {
        log_not_found off;
        access_log off;
    }
    location = /robots.txt {
        allow all;
        log_not_found off;
        access_log off;
    }
    location ~ \..*/.*\.php\$ {
        return 403;
    }
    # Allow "Well-Known URIs" as per RFC 5785
    location ~* ^/.well-known/ {
        allow all;
    }
    # Block access to "hidden" files and directories whose names begin with a
    # period. This includes directories used by version control systems such
    # as Subversion or Git to store control files.
    location ~ (^|/)\. {
        return 403;
    }
    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }
    # Don't allow direct access to PHP files in the vendor directory.
    location ~ /vendor/.*\.php\$ {
        deny all;
        return 404;
    }
    location ~ /\.ht {
            deny all;
    }
    location ~ '\.php\$' {
        fastcgi_split_path_info ^(.+?\.php)(|/.*)\$;
        include fastcgi_params;
        fastcgi_read_timeout 300;
        # Block httpoxy attacks. See https://httpoxy.org/.
        fastcgi_param HTTP_PROXY "";
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param PATH_INFO \$fastcgi_path_info;
        fastcgi_param QUERY_STRING \$query_string;
        fastcgi_intercept_errors on;
        fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
    }
}
END
ln -s /etc/nginx/sites-enabled/main.conf /etc/nginx/sites-available/
rm -rf /etc/nginx/sites-enabled/default
systemctl restart nginx.service
mkdir -p /var/www/main
echo "<?php phpinfo(); " > /var/www/main/index.php
chgrp -R www-data /var/www
chmod -R g+w /var/www
find /var/www -type d -exec chmod 2775 {} \;
find /var/www -type f -exec chmod ug+rw {} \;
################
# PHP
# Install php8
sudo apt install lsb-release ca-certificates apt-transport-https software-properties-common -y
sudo add-apt-repository ppa:ondrej/php
apt install php8.1-{cli,fpm,mysqlnd,pdo,xml,curl,dom,exif,fileinfo,gd,iconv,mbstring,phar,xml} -y
sed -i -e 's/pm.max_children = 5$/pm.max_children = 50/g' /etc/php/8.1/fpm/pool.d/www.conf
sed -i -e 's/pm.max_spare_servers = 3$/pm.max_spare_servers = 30/g' /etc/php/8.1/fpm/pool.d/www.conf
sed -i -e 's/upload_max_filesize = 2M$/upload_max_filesize = 80M/g' /etc/php/8.1/fpm/php.ini
sed -i -e 's/post_max_size = 8M$/post_max_size = 80M/g' /etc/php/8.1/fpm/php.ini
sed -i -e 's/;max_input_vars = 1000$/max_input_vars = 10000/g' /etc/php/8.1/fpm/php.ini
systemctl restart php8.1-fpm.service

php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
php -r "if (hash_file('sha384', 'composer-setup.php') === '906a84df04cea2aa72f40b5f787e49f22d4c2f19492ac310e8cba5b96ac8b64115ac402c8cd292b8a03482574915d1a8') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
php composer-setup.php
php -r "unlink('composer-setup.php');"
mv composer.phar /usr/local/bin/composer
