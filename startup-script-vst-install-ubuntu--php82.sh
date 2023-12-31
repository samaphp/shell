#!/bin/bash
# 1. Install VestaCP
# 1. Adding multiple PHP versions: php8.2 and php7.4
# 1. Create VestaCP templates for multiple php versions with /web as a docroot

add-apt-repository ppa:ondrej/php
apt update
# Install VestaCP
curl -O https://raw.githubusercontent.com/samaphp/shell/main/startup-script-vst-install-ubuntu.sh
groupdel admin
# REPLACE THE OPTION VALUES IN THE NEXT LINE
bash startup-script-vst-install-ubuntu.sh --email 'MY@EMAIL.HERE' --port 8083 --hostname 'MY.HOSTNAME' --password 'PASSWORD' --vsftpd no --spamassassin no --softaculous no --clamav no --exim no --dovecot no --interactive no

apt install software-properties-common
apt install php8.2 libapache2-mod-php8.2 php7.4 libapache2-mod-php7.4
a2enmod proxy_fcgi setenvif
apt install php8.2-fpm php7.4-fpm libapache2-mod-fcgid
a2enconf php8.2-fpm  php7.4-fpm
systemctl restart apache2
#systemctl status php8.2-fpm

# Create php8.2 templates (docroot /web)
awk '/\/VirtualHost/{print "<IfModule !mod_php8.c>\n<IfModule proxy_fcgi_module>\n    <IfModule setenvif_module>\n        SetEnvIfNoCase ^Authorization$ \"(.+)\" HTTP_AUTHORIZATION=$1\n    </IfModule>\n\n    <FilesMatch \".+\\.ph(ar|p|tml)$\">\n        SetHandler \"proxy:unix:/run/php/php8.2-fpm.sock|fcgi://php82.localhost\"\n    </FilesMatch>\n    <FilesMatch \"^\\.ph(ar|p|ps|tml)$\">\n        Require all denied\n    </FilesMatch>\n</IfModule>\n</IfModule>"}1' /usr/local/vesta/data/templates/web/apache2/default.stpl | sed '/DocumentRoot/c\    DocumentRoot %sdocroot%/web' >> /usr/local/vesta/data/templates/web/apache2/php82.stpl
awk '/\/VirtualHost/{print "<IfModule !mod_php8.c>\n<IfModule proxy_fcgi_module>\n    <IfModule setenvif_module>\n        SetEnvIfNoCase ^Authorization$ \"(.+)\" HTTP_AUTHORIZATION=$1\n    </IfModule>\n\n    <FilesMatch \".+\\.ph(ar|p|tml)$\">\n        SetHandler \"proxy:unix:/run/php/php8.2-fpm.sock|fcgi://php82.localhost\"\n    </FilesMatch>\n    <FilesMatch \"^\\.ph(ar|p|ps|tml)$\">\n        Require all denied\n    </FilesMatch>\n</IfModule>\n</IfModule>"}1' /usr/local/vesta/data/templates/web/apache2/default.tpl | sed '/DocumentRoot/c\    DocumentRoot %sdocroot%/web' >> /usr/local/vesta/data/templates/web/apache2/php82.tpl

# Create php7.4 templates (docroot /web)
awk '/\/VirtualHost/{print "<IfModule !mod_php7.c>\n<IfModule proxy_fcgi_module>\n    <IfModule setenvif_module>\n        SetEnvIfNoCase ^Authorization$ \"(.+)\" HTTP_AUTHORIZATION=$1\n    </IfModule>\n\n    <FilesMatch \".+\\.ph(ar|p|tml)$\">\n        SetHandler \"proxy:unix:/run/php/php7.4-fpm.sock|fcgi://php74.localhost\"\n    </FilesMatch>\n    <FilesMatch \"^\\.ph(ar|p|ps|tml)$\">\n        Require all denied\n    </FilesMatch>\n</IfModule>\n</IfModule>"}1' /usr/local/vesta/data/templates/web/apache2/default.stpl | sed '/DocumentRoot/c\    DocumentRoot %sdocroot%/web' >> /usr/local/vesta/data/templates/web/apache2/php74.stpl
awk '/\/VirtualHost/{print "<IfModule !mod_php7.c>\n<IfModule proxy_fcgi_module>\n    <IfModule setenvif_module>\n        SetEnvIfNoCase ^Authorization$ \"(.+)\" HTTP_AUTHORIZATION=$1\n    </IfModule>\n\n    <FilesMatch \".+\\.ph(ar|p|tml)$\">\n        SetHandler \"proxy:unix:/run/php/php7.4-fpm.sock|fcgi://php74.localhost\"\n    </FilesMatch>\n    <FilesMatch \"^\\.ph(ar|p|ps|tml)$\">\n        Require all denied\n    </FilesMatch>\n</IfModule>\n</IfModule>"}1' /usr/local/vesta/data/templates/web/apache2/default.tpl | sed '/DocumentRoot/c\    DocumentRoot %sdocroot%/web' >> /usr/local/vesta/data/templates/web/apache2/php74.tpl

# VestaCP user backup
#/usr/local/vesta/bin/v-backup-user USERNAME
# VestaCP user restore
# You need to be inside /backup to restore a user, otherwise you will get error: Error: invalid backup format
#/usr/local/vesta/bin/v-restore-user USERNAME USERNAME.2023-05-20_02-31-31.tar

#TROUBLESHOOTING
# # N: Updating from such a repository can't be done securely, and is therefore disabled by default.
# # N: See apt-secure(8) manpage for repository creation and user configuration details.
# # Reading package lists... Done
# # Building dependency tree... Done
# # Reading state information... Done
# # Note, selecting 'libext2fs2' instead of 'e2fslibs'
# .... still working on it.
