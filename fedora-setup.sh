#/bin/sh
# My Fedora setup script

# Basic apps
sudo dnf update
sudo dnf install git -y
sudo dnf install snapd -y
sudo dnf install google-chrome -y
sudo snap install slack --classic
sudo snap install spotify
sudo snap install phpstorm --classic
sudo snap install code --classic
sudo snap install evernote-web-client
sudo snap install notion-snap

# Docker installation
sudo dnf -y install dnf-plugins-core
sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
sudo dnf install docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Lando
wget https://files.lando.dev/installer/lando-x64-stable.rpm
sudo dnf install lando-x64-stable.rpm -y
sudo rm -rf lando-x64-stable.rpm
sudo usermod -a -G docker $USER $ exit
lando --channel stable

# Albert
sudo dnf config-manager --add-repo https://download.opensuse.org/repositories/home:manuelschneid3r/Fedora_Rawhide/home:manuelschneid3r.repo
sudo dnf install albert -y

# NVIDIA Drivers
# sudo dnf install akmod-nvidia
## Get card model name: ` lspci | grep VGA `
## Download NVIDIA: https://www.nvidia.com/Download/driverResults.aspx/187526/en-us
## Install the Nvidia driver compilation dependencies with
# sudo dnf install kernel-devel kernel-headers gcc make dkms acpid libglvnd-glx libglvnd-opengl libglvnd-devel pkgconfig
# sudo bash NVIDIA-Linux-x86_64-510.68.02.run
