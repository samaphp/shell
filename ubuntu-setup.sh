#/bin/sh
# My Ubuntu setup script
sudo apt install git
sudo snap install slack --classic
sudo snap install spotify
sudo snap install phpstorm --classic
sudo snap install code --classic

# Install docker
sudo apt install apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
apt-cache policy docker-ce
sudo apt install docker-ce
sudo systemctl status docker
wget https://files.lando.dev/installer/lando-x64-stable.deb
sudo dpkg -i lando-x64-stable.deb
sudo rm -rf lando-x64-stable.deb

# Albert
curl https://build.opensuse.org/projects/home:manuelschneid3r/public_key | sudo apt-key add -
#echo 'deb https://download.opensuse.org/repositories/home:/manuelschneid3r/xUbuntu_22.04/ /' | sudo tee /etc/apt/sources.list.d/home:manuelschneid3r.list
#sudo wget -nv https://download.opensuse.org/repositories/home:/manuelschneid3r/xUbuntu_22.04/Release.key -O "/etc/apt/trusted.gpg.d/home:manuelschneid3r.asc"
sudo apt update
sudo apt install albert

## Remove docker
# sudo apt-get purge -y docker docker.io
# sudo apt-get autoremove -y --purge docker docker.io
# sudo rm -rf /var/run/docker.sock

## Quick re-install docker (data loss)
# sudo apt-get purge -y docker-engine docker docker.io docker-ce docker-ce-cli
# sudo apt-get autoremove -y --purge docker-engine docker docker.io docker-ce  
# sudo rm -rf /var/lib/docker/volumes && sudo rm -rf /var/lib/docker/trust && sudo rm -rf /var/lib/docker/tmp && sudo rm -rf /var/lib/docker/swarm && sudo rm -rf /var/lib/docker/runtimes && sudo rm -rf /var/lib/docker/plugins && sudo rm -rf /var/lib/docker/network && sudo rm -rf /var/lib/docker/image && sudo rm -rf /var/lib/docker/containers && sudo rm -rf /var/lib/docker/buildkit
# sudo apt install docker-ce && sudo systemctl status docker
# wget https://files.lando.dev/installer/lando-x64-stable.deb && sudo dpkg -i lando-x64-stable.deb && sudo rm -rf lando-x64-stable.deb
