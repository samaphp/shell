#/bin/sh
#####
# Create new Apache virtual host for non-production Drupal website.
#
# Usage:
# $ ./vhost.sh SHORT_NAME DOMAIN_NAME HTML_FOLDER_PATH
# $ ./vhost.sh PROJECT_ENV DOMAIN_HERE PROJECT/ENV
#####

sudo sh -c "echo '<IfModule mod_ssl.c>' >> /etc/apache2/sites-available/$1.conf"
sudo sh -c "echo '<VirtualHost *:443>' >> /etc/apache2/sites-available/$1.conf"
sudo sh -c "echo '  ServerName $2' >> /etc/apache2/sites-available/$1.conf"
sudo sh -c "echo '  ServerAdmin admin@$2' >> /etc/apache2/sites-available/$1.conf"
sudo sh -c "echo '  DocumentRoot /var/www/html/$3/web' >> /etc/apache2/sites-available/$1.conf"
sudo sh -c "echo '  CustomLog ${APACHE_LOG_DIR}/access.log combined' >> /etc/apache2/sites-available/$1.conf"
sudo sh -c "echo '  ErrorLog ${APACHE_LOG_DIR}/error.log' >> /etc/apache2/sites-available/$1.conf"
sudo sh -c "echo '  <Directory /var/www/html/$3/web/>' >> /etc/apache2/sites-available/$1.conf"
sudo sh -c "echo '    Options Indexes FollowSymLinks' >> /etc/apache2/sites-available/$1.conf"
sudo sh -c "echo '    AllowOverride All' >> /etc/apache2/sites-available/$1.conf"
sudo sh -c "echo '    Require all granted' >> /etc/apache2/sites-available/$1.conf"
sudo sh -c "echo '    RewriteEngine on' >> /etc/apache2/sites-available/$1.conf"
sudo sh -c "echo '    RewriteBase /' >> /etc/apache2/sites-available/$1.conf"
sudo sh -c "echo '    RewriteCond %{REQUEST_FILENAME} !-f' >> /etc/apache2/sites-available/$1.conf"
sudo sh -c "echo '    RewriteCond %{REQUEST_FILENAME} !-d' >> /etc/apache2/sites-available/$1.conf"
sudo sh -c "echo '    RewriteRule ^(.*)$ index.php?q=\$1 [L,QSA]' >> /etc/apache2/sites-available/$1.conf"
sudo sh -c "echo '  </Directory>' >> /etc/apache2/sites-available/$1.conf"
sudo sh -c "echo '  SSLCertificateFile /ssl-certs/FILE.crt' >> /etc/apache2/sites-available/$1.conf"
sudo sh -c "echo '  SSLCertificateKeyFile /ssl-certs/FILE.key' >> /etc/apache2/sites-available/$1.conf"
sudo sh -c "echo '</VirtualHost>' >> /etc/apache2/sites-available/$1.conf"
sudo sh -c "echo '</IfModule>' >> /etc/apache2/sites-available/$1.conf"

# @TODO: Custom log file.

a2ensite $1
systemctl reload apache2
