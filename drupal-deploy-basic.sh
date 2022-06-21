#/bin/sh
###
# Basic deploy script.
#
# Script usage:
# $ ./drupal-deploy-basic.sh FOLDERNAME
#
# Suggested usage for non-production environments:
# $ ./drupal-deploy-basic.sh PROJECT/ENVIRONMENT
###

echo "██████ DEPLOY"
cd /var/www/html/$1

#git checkout composer.json
echo "Pulling changes from git repo .."
git pull
echo "Installing composer .."
composer install --no-interaction --no-dev
./vendor/bin/drush cim -y
./vendor/bin/drush cim -y # duplicated to fix configuration sequence issue if.
./vendor/bin/drush updb -y
./vendor/bin/drush locale-check
./vendor/bin/drush locale-update
./vendor/bin/drush cr
chown www-data:www-data -R /var/www/html/$1
