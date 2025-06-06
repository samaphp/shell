#!/bin/bash
# Script to install PHP for Laravel app.

sudo apt update
sudo apt install -y software-properties-common
sudo add-apt-repository ppa:ondrej/php
sudo apt update
sudo apt install php8.2-{cli,fpm,mysql,common,xml,curl,gd,mbstring} -y
sudo phpenmod mbstring curl XML
#systemctl status php8.2-fpm.service
#mkdir /var/www/app
#sudo chown -R www-data:www-data /var/www/app
