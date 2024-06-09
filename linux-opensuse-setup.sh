#/bin/sh
# My OpenSUSE setup script

sudo flatpak install flathub com.google.Chrome -y
sudo flatpak install flathub com.visualstudio.code -y
sudo flatpak install flathub com.slack.Slack -y
sudo flatpak install flathub io.github.brunofin.Cohesion -y
sudo flatpak install flathub com.jetbrains.PhpStorm -y
sudo flatpak install flathub com.getpostman.Postman -y
sudo flatpak install flathub org.kde.kteatime -y
#sudo flatpak install flathub com.github.devalien.workspaces -y

# docker
zypper install -y docker docker-compose docker-compose-switch
sudo systemctl enable docker
sudo usermod -G docker -a $USER
newgrp docker
sudo systemctl restart docker

# Lando
wget https://files.lando.dev/installer/lando-x64-stable.rpm
sudo zypper --non-interactive install --allow-unsigned-rpm lando-x64-stable.rpm
sudo rm -rf lando-x64-stable.rpm
sudo usermod -a -G docker $USER
lando --channel stable

sudo sh -c 'echo "$USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers'

# Install and configure zsh
# PHPStorm plugins
# Google Chrome persons
