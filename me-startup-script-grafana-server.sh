#!/bin/bash
# Startup script for my local static api server on a PROXMOX node
# Run this as root
# Install Grafana

# common packages
apt install net-tools

apt-get install -y apt-transport-https
apt-get install -y software-properties-common wget
wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -
echo "deb https://packages.grafana.com/oss/deb stable main" | sudo tee -a /etc/apt/sources.list.d/grafana.list
apt-get update
apt-get install grafana -y

# start the server with systemd
systemctl daemon-reload
systemctl start grafana-server
#systemctl status grafana-server

# configure the Grafana server to start at boot:
sudo systemctl enable grafana-server.service

# .... still working on next configuration
