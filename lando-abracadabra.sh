#!/bin/bash
# Author: Saud bin Mohammed
# Script to clone and run a new website for local environment using lando abracadabra custom command.
# 1. Clone project (parameter 1)
# 1. Create a new branch (parameter 2)
# 1. Change Lando machine name
# 1. Change proxy domain name
# 1. Add new domain to your /etc/hosts file
# 1. Start Lando
# 1. Run Lando abracadabra (please refer to: https://github.com/samaphp/lando/blob/e13088238054b40c58bbb2d45e6ec937f0f5587c/.lando.yml#L16 )
# 1. Print site URL with a one time login URL at the end

if [[ "$1" == '' ]] ;
  then
    echo 'Please enter the project name:'
    read _projectName
  else
    _projectName=$1
    echo "Project name is: $_projectName"
fi

if [[ "$2" == '' ]] ;
  then
    echo 'Please enter the branch name (no-spaces-please) short as much as you can:'
    read _branchName
  else
    _branchName=$2
    echo "Branch name is: $_branchName"
fi

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
