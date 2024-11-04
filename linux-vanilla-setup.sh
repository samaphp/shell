#/bin/sh
# Vanilla OS orchid setup

sudo apt update
#sudo apt install snapd
sudo apt install libfuse2

# Install Postman
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install flathub com.getpostman.Postman
