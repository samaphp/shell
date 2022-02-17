#/bin/sh
#####
# This script is meant to be used to install a new Drupal site that is used to run on multiple stages.
# This will install the Drupal site and import the site structure from the configuration files.
# We are using same UUID to import same configurations.
#
# Script usage:
# $ ./drupal-install.sh DB_NAME
#
# Suggested usage:
# $ ./drupal-install.sh drupal_dev
# $ ./drupal-install.sh drupal_test
# $ ./drupal-install.sh PROJECTNAME_ENVIRONMENTNAME
#####

echo "██████ Salam! Please take a rest this process will take around 5-7 minutes ██████"
mkdir private -p
composer install
./vendor/bin/drush si minimal --db-url=mysql://USER:PASS@localhost:3306/$1 --site-name=automated -y --account-pass=admin -y
./vendor/bin/drush cset system.site uuid UUID_HERE -y
./vendor/bin/drush en form_mode_manager -y # optional
./vendor/bin/drush en menu_link_content -y # optional
./vendor/bin/drush en workflow -y # optional
./vendor/bin/drush config-import sync -y
./vendor/bin/drush config-import sync -y # duplicated to fix configuration sequence issue.
./vendor/bin/drush locale-check
./vendor/bin/drush locale-update
./vendor/bin/drush cr
echo "██████ Installation process has been finished successfully ██████"
echo "██████ Use these credentials admin/admin or the following URL ██████"
./vendor/bin/drush uli

# Change the folders owner to the needful user:group.
chown -R www-data:www-data ./*
