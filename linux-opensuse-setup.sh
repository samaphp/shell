#/bin/sh
# My OpenSUSE setup script

sudo flatpak install flathub com.google.Chrome -y
sudo flatpak install flathub com.visualstudio.code -y
sudo flatpak install flathub com.slack.Slack -y
sudo flatpak install flathub io.github.brunofin.Cohesion -y
sudo flatpak install flathub com.jetbrains.PhpStorm -y
sudo flatpak install flathub com.getpostman.Postman -y
sudo flatpak install flathub org.kde.kteatime -y
flatpak install flathub org.standardnotes.standardnotes -y
#sudo flatpak install flathub com.github.devalien.workspaces -y

# set google chrome as default browser
xdg-settings set default-web-browser com.google.Chrome.desktop

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

# Postman login crash issue because of SSL certificates: https://www.reddit.com/r/Fedora/comments/16had56/comment/k0p67rd/
