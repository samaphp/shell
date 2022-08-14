#!/bin/bash
# Author: Saud bin Mohammed
# Script to clone and run a new website for local environment from a git repository.
# The script will prompt a two questions (1. type of the installation) (2. the git repo URL)

# Todo
# - handle exceptions in the installation process in case of any errors like minimum-stability issues
# - require all module dependencies

_print_type_name () {
  _typeName='unknown'
  if [[ "$_installationType" == 1 ]] ;
    then
    _typeName='the repo contains Drupal website with vendor'
  fi
  if [[ "$_installationType" == 2 ]] ;
    then
    _typeName='the repo is just a Drupal custom module'
  fi

  echo 'You choosed:'
  echo $_typeName
}

_type_composer_create_drupal () {
    lando composer create drupal/recommended-project -n
    mv recommended-project/* ./
    mv recommended-project/.* ./
    rm -rf recommended-project
}

if [[ "$1" == '' ]] ;
  then
    echo 'Please choose the installation type:'
    echo '1 = the repo contains Drupal website with vendor'
    echo '2 = the repo is just a Drupal custom module'
    read _installationType
  else
    _installationType=$1
fi

_print_type_name

if [[ "$2" == '' ]] ;
  then
    echo 'Please enter remote url (preferred ssh):'
    read _projectUrl
  else
    _projectUrl=$2
    echo "Project URL is: $_projectUrl"
fi

# Generating a project name from the repo URL
_projectName=$(basename "$_projectUrl");
_projectName=$(echo $_projectName | sed "s/.git//")
_projectShortName=${_projectName:0:20}
_projectShortName=$(echo $_projectShortName | tr '[:upper:]' '[:lower:]')

# we will create a new folder so we can run Lando to use composer from lando
# create new directory for this project
mkdir $_projectShortName
cd $_projectShortName

_create_lando_file () {
cat <<END >.lando.yml
name: abracadabra-$_projectShortName
recipe: drupal9
config:
  webroot: web
  php: 8.1
END
}

_create_lando_file

lando start

if [[ "$_installationType" == 1 ]] ;
  then
    git clone $_projectUrl project
    mv project/* ./
    mv project/.* ./
    rm -rf project
    # If the repo contains Lando it will override our Lando file so we will re-create it again
    _create_lando_file
  else
    _type_composer_create_drupal
    # NOTE: We will not support Legacy projects. only recommended project where ./web folder exists.
    cd web/modules
    mkdir custom
    cd custom
    git clone $_projectUrl
    cd ..
    cd ..
    cd ..
fi

sed -i "/\"minimum-stability\"/c\    \"minimum-stability\"\: \"dev\"\," composer.json

# requiring some recommended packages
lando composer require drupal/admin_toolbar drupal/devel drush/drush drupal/masquerade:2.x-dev -n
echo 'the recommended packages has been downloaded'

# start installing Drupal website
lando drush si standard --db-url=mysql://drupal9:drupal9@database:3306/drupal9 --site-name=automated -y --account-pass=admin -y
echo 'Drupal website has been installed successfully'

lando drush en admin_toolbar_tools devel masquerade -y
lando drush pmu update -y
chmod -R 0777 web/sites/default

# disable caching
sh -c "echo '\$config['\''system.logging'\'']['\''error_level'\''] = '\''verbose'\'';' >> web/sites/default/settings.php"
sh -c "echo '\$config['\''system.performance'\'']['\''css'\'']['\''preprocess'\''] = FALSE;' >> web/sites/default/settings.php"
sh -c "echo '\$config['\''system.performance'\'']['\''js'\'']['\''preprocess'\''] = FALSE;' >> web/sites/default/settings.php"
lando drush cset devel.settings devel_dumper var_dumper -y
lando drush theme:enable bartik -y
lando drush config-set system.theme default bartik -y
lando drush cr

# create demo users
lando drush user-create demo --password="demo"
lando drush user-create demo2 --password="demo2"
lando drush user-create demo3 --password="demo3"

echo 'user one login URL:'
lando drush uli | sed "s/http:\/\/default/https:\/\/abracadabra-$_projectShortName.lndo.site/"
echo ''
echo 'demo login URL:'
lando drush uli 2 | sed "s/http:\/\/default/https:\/\/abracadabra-$_projectShortName.lndo.site/"
echo ''
echo 'demo2 login URL:'
lando drush uli 3 | sed "s/http:\/\/default/https:\/\/abracadabra-$_projectShortName.lndo.site/"
$SHELL
