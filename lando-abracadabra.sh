#!/bin/bash
# Script to clone and run a new website for local environment using land abracadabra custom command.
# Author: Saud

echo 'Please enter the project name:'
read _projectName

echo 'Please enter the branch name (no-spaces-please):'
read _branchName

echo "██████ STARTING installation process ██████"
git clone git@git.saud.lab:drupal/$_projectName/project.git $_branchName
echo "... project has been cloned successfully"
cd $_branchName
git checkout -b $_branchName

sed -i '/name:/d' .lando.yml
sed -i "1s/^/name: saud_$_projectName\_$_branchName\n/" .lando.yml
sed -i "/- local./c\    - $_branchName.$_projectName.saud.lab" .lando.yml
sudo sh -c "echo '127.0.0.1 $_branchName.$_projectName.saud.lab' >> /etc/hosts"

lando start
lando abracadabra

echo "Just for special ones like you!"
echo "https://$_branchName.$_projectName.saud.lab"
lando drush uli | sed "s/http:\/\/default/https:\/\/$_branchName.$_projectName.saud.lab/"
echo "ONE_RULE: Don't miss to destroy it after finish!"
$SHELL
