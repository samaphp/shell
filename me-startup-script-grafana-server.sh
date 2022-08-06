#!/bin/bash
# Startup script for my local static api server on a PROXMOX node
# Run this as root
# Install Grafana
# Install Prometheus
# Install Alertmanager

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

############################################################
# Installing Prometheus
############################################################
# Source: https://github.com/petarnikolovski/prometheus-install/blob/master/prometheus.sh
# Source: https://computingforgeeks.com/install-prometheus-server-on-debian-ubuntu-linux/
sudo adduser --no-create-home --disabled-login --shell /bin/false --gecos "Prometheus Monitoring User" prometheus

# Make directories and dummy files necessary for prometheus
sudo mkdir /etc/prometheus
sudo mkdir /var/lib/prometheus
sudo touch /etc/prometheus/prometheus.yml
sudo touch /etc/prometheus/prometheus.rules.yml

# Assign ownership of the files above to prometheus user
sudo chown -R prometheus:prometheus /etc/prometheus
sudo chown prometheus:prometheus /var/lib/prometheus

# Download prometheus and copy utilities to where they should be in the filesystem
VERSION=2.37.0
wget https://github.com/prometheus/prometheus/releases/download/v${VERSION}/prometheus-${VERSION}.linux-amd64.tar.gz
tar xvzf prometheus-${VERSION}.linux-amd64.tar.gz
sudo cp prometheus-${VERSION}.linux-amd64/prometheus /usr/local/bin/
sudo cp prometheus-${VERSION}.linux-amd64/promtool /usr/local/bin/
sudo cp -r prometheus-${VERSION}.linux-amd64/consoles /etc/prometheus
sudo cp -r prometheus-${VERSION}.linux-amd64/console_libraries /etc/prometheus

# Assign the ownership of the tools above to prometheus user
sudo chown -R prometheus:prometheus /etc/prometheus/consoles
sudo chown -R prometheus:prometheus /etc/prometheus/console_libraries
sudo chown prometheus:prometheus /usr/local/bin/prometheus
sudo chown prometheus:prometheus /usr/local/bin/promtool

# Populate configuration files
cat ./prometheus-${VERSION}.linux-amd64/prometheus.yml | sudo tee /etc/prometheus/prometheus.yml
#cat ./prometheus-${VERSION}.linux-amd64/prometheus.rules.yml | sudo tee /etc/prometheus/prometheus.rules.yml
#cat ./prometheus-${VERSION}.linux-amd64/prometheus.service | sudo tee /etc/systemd/system/prometheus.service
sudo tee /etc/systemd/system/prometheus.service<<EOF
[Unit]
Description=Prometheus
Documentation=https://prometheus.io/docs/introduction/overview/
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
User=prometheus
Group=prometheus
ExecReload=/bin/kill -HUP \$MAINPID
ExecStart=/usr/local/bin/prometheus \
  --config.file=/etc/prometheus/prometheus.yml \
  --storage.tsdb.path=/var/lib/prometheus \
  --web.console.templates=/etc/prometheus/consoles \
  --web.console.libraries=/etc/prometheus/console_libraries \
  --web.listen-address=0.0.0.0:9090 \
  --web.external-url=

SyslogIdentifier=prometheus
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# systemd
sudo systemctl daemon-reload
sudo systemctl enable prometheus
sudo systemctl start prometheus

#sudo ufw allow 9090/tcp

# Prometheus installation cleanup
rm prometheus-${VERSION}.linux-amd64.tar.gz
rm -rf prometheus-${VERSION}.linux-amd64


############################################################
# Installing Alertmanager
############################################################
# Source: https://github.com/petarnikolovski/prometheus-install/blob/master/alertmanager.sh
# Source: https://linuxhint.com/install-configure-prometheus-alert-manager-ubuntu/

# Make alertmanager user
sudo adduser --no-create-home --disabled-login --shell /bin/false --gecos "Alertmanager User" alertmanager

# Make directories and dummy files necessary for alertmanager
sudo mkdir /etc/alertmanager
sudo mkdir /etc/alertmanager/template
sudo mkdir -p /var/lib/alertmanager/data
sudo touch /etc/alertmanager/alertmanager.yml
sudo chown -R alertmanager:alertmanager /etc/alertmanager
sudo chown -R alertmanager:alertmanager /var/lib/alertmanager

# Download alertmanager and copy utilities to where they should be in the filesystem
# https://github.com/prometheus/alertmanager/releases checkout available releases
VERSION=0.24.0
wget https://github.com/prometheus/alertmanager/releases/download/v${VERSION}/alertmanager-${VERSION}.linux-amd64.tar.gz
tar xvzf alertmanager-${VERSION}.linux-amd64.tar.gz
sudo cp alertmanager-${VERSION}.linux-amd64/alertmanager /usr/local/bin/
sudo cp alertmanager-${VERSION}.linux-amd64/amtool /usr/local/bin/
sudo chown alertmanager:alertmanager /usr/local/bin/alertmanager
sudo chown alertmanager:alertmanager /usr/local/bin/amtool

# Populate configuration files
cat ./alertmanager-${VERSION}.linux-amd64/alertmanager.yml | sudo tee /etc/alertmanager/alertmanager.yml
#cat ./alertmanager-${VERSION}.linux-amd64/alertmanager.service | sudo tee /etc/systemd/system/alertmanager.service
sudo tee /etc/systemd/system/alertmanager.service<<EOF
[Unit]
Description=Alertmanager for prometheus

[Service]
Restart=always
User=prometheus
ExecStart=/opt/alertmanager/alertmanager --config.file=/opt/alertmanager/alertmanager.yml --storage.path=/opt/alertmanager/data            
ExecReload=/bin/kill -HUP $MAINPID
TimeoutStopSec=20s
SendSIGKILL=no

[Install]
WantedBy=multi-user.target
EOF

# systemd
sudo systemctl daemon-reload
sudo systemctl enable alertmanager
sudo systemctl start alertmanager

# Alertmanager installation cleanup
rm alertmanager-${VERSION}.linux-amd64.tar.gz
rm -rf alertmanager-${VERSION}.linux-amd64
