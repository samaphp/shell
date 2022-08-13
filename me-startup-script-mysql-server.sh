#!/bin/bash
# Startup script for my local mariadb server on a PROXMOX node
# Run this as root

# common packages
apt install net-tools

# start installing mariadb
apt update
apt install mariadb-server
mysql_secure_installation
systemctl start mariadb.service

# open port for all local machines
sed -i "s/127.0.0.1/0.0.0.0/" /etc/mysql/mariadb.conf.d/50-server.cnf
systemctl restart mariadb.service

# netstat -ant | grep 3306

# since root is not allowed from remote source, you may want to create a new user.
#CREATE USER 'SOME_USER'@'%' IDENTIFIED BY 'SOME_PASSWORD';
#GRANT ALL PRIVILEGES ON *.* TO 'SOME_USER'@'%';
