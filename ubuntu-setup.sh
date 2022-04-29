#/bin/sh
# My Ubuntu setup script
sudo apt install git
sudo snap install slack --classic
sudo snap install spotify
sudo snap install phpstorm --classic
sudo snap install code --classic
sudo apt install docker.io -y
wget https://files.lando.dev/installer/lando-x64-stable.deb
sudo dpkg -i --ignore-depends=docker-ce lando-x64-stable.deb
sudo rm -rf lando-x64-stable.deb

# Albert
curl https://build.opensuse.org/projects/home:manuelschneid3r/public_key | sudo apt-key add -
#echo 'deb https://download.opensuse.org/repositories/home:/manuelschneid3r/xUbuntu_22.04/ /' | sudo tee /etc/apt/sources.list.d/home:manuelschneid3r.list
#sudo wget -nv https://download.opensuse.org/repositories/home:/manuelschneid3r/xUbuntu_22.04/Release.key -O "/etc/apt/trusted.gpg.d/home:manuelschneid3r.asc"
sudo apt update
sudo apt install albert
