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
