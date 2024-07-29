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

sudo zypper install snapper
sudo snapper -c root create-config /
sudo snapper create --description "first-snapshot"

# Install Albert launcher
sudo zypper install albert
sudo ln -s /usr/lib64/albert/libalbert.so /usr/lib64/libalbert.so
sudo ln -s /usr/lib64/albert/libxdg.so /usr/lib64/libxdg.so
# search for lib files: sudo find / -name "libalbert.so" 2>/dev/null

# update pip
#python3 -m pip install --upgrade pip

# Install and configure zsh
# PHPStorm plugins
# Google Chrome persons
# Google chat?

# Portainer
docker volume create portainer_data
docker run -d -p 8000:8000 -p 9443:9443 --name portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce:latest


# Postman login crash issue because of SSL certificates: https://www.reddit.com/r/Fedora/comments/16had56/comment/k0p67rd/
