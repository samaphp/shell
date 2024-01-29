#/bin/sh
# My Ubuntu setup script

# Basic apps
sudo apt install git -y
sudo apt install snapd -y
sudo snap install slack --classic
sudo snap install spotify
sudo snap install phpstorm --classic
sudo snap install code --classic
sudo snap install evernote-web-client
sudo snap install notion-snap
sudo snap install termius-app
sudo snap install postman

# Install docker
sudo apt install apt-transport-https ca-certificates curl software-properties-common -y
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
apt-cache policy docker-ce
sudo apt install docker-ce -y
#sudo systemctl status docker
wget https://files.lando.dev/installer/lando-x64-stable.deb
sudo dpkg -i lando-x64-stable.deb
sudo rm -rf lando-x64-stable.deb
sudo usermod -a -G docker $USER $ exit
lando --channel stable

sudo apt install docker-compose

# Install Google Chrome
sudo apt-get install libxss1 libappindicator1 libindicator7
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo apt install ./google-chrome*.deb
rm -rf google-chrome*.deb

# Albert
curl https://build.opensuse.org/projects/home:manuelschneid3r/public_key | sudo apt-key add -
#echo 'deb https://download.opensuse.org/repositories/home:/manuelschneid3r/xUbuntu_22.04/ /' | sudo tee /etc/apt/sources.list.d/home:manuelschneid3r.list
#sudo wget -nv https://download.opensuse.org/repositories/home:/manuelschneid3r/xUbuntu_22.04/Release.key -O "/etc/apt/trusted.gpg.d/home:manuelschneid3r.asc"
sudo apt update
sudo apt install albert -y

# ulauncher (alternative of Albert)
# sudo add-apt-repository ppa:agornostal/ulauncher && sudo apt update && sudo apt install ulauncher -y

# Install some useful cli tools
sudo apt install btop
sudo apt install netdiscover # USAGE: # sudo netdiscover -r 192.168.0.1/16
sudo apt install net-tools # ifconfig command
sudo apt install tree # tree command
sudo apt install guake # hot window terminal

# install nala
#echo "deb https://deb.volian.org/volian/ scar main" | sudo tee /etc/apt/sources.list.d/volian-archive-scar-unstable.list
#wget -qO - https://deb.volian.org/volian/scar.key | sudo tee /etc/apt/trusted.gpg.d/volian-archive-scar-unstable.gpg > /dev/null

# Install NVIDIA driver.
sudo apt install gcc make
wget https://us.download.nvidia.com/XFree86/Linux-x86_64/510.68.02/NVIDIA-Linux-x86_64-510.68.02.run
sudo bash NVIDIA-Linux-x86_64-510.68.02.run 

# Remove sudo password
sudo sh -c 'echo "$USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers'

# Install and configure zsh
#sudo apt install zsh -y
#git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k
#echo 'source ~/powerlevel10k/powerlevel10k.zsh-theme' >> ~/.zshrc
#git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
#echo 'source ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions/zsh-autosuggestions.plugin.zsh' >> ~/.zshrc
#echo 'alias ll="ls -lha"' >>~/.zshrc
#sudo chsh -s $(which zsh)

# PHPStorm plugins
#mkdir /home/config/phpstorm -p
#cd /home/config/phpstorm
#wget -q -O copilot.zip - https://plugins.jetbrains.com/files/17718/233164/github-copilot-intellij-1.1.33.1980.zip?updateId=233164&pluginId=17718&family=INTELLIJ
# drupal symfony bridge
# drupal 8 namespace detector
# php annotations
# symfony support

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

## If you ran into Ctrl+Arrow issue in terminal you may need to add these two lines into ~/.bashrc
## https://unix.stackexchange.com/questions/58870/ctrl-left-right-arrow-keys-issue
#bindkey "^[[1;5D" backward-word
#bindkey "^[[1;5C" forward-word
# Check all available bindings in: `bindkey | grep backward-kill-line`

# Alt+h : when you already wrote the command it will show the help
# Alt+d : will delete the next word only

# Add Arabic keyboard
# Super key shortcut, to search for all applications

# Keyboard shortcuts changes
# change (Move to workspace below to: Ctrl+Alt+Down)
# change (Move window to lower workspace to: Ctrl+Alt+Shift+Down)
# change (Move window to leftward monitor to: Ctrl+Shift+left)

# disable avahi-daemon
#sudo systemctl disable avahi-daemon

echo "██████ You may need to reboot your machine to make Lando work properly ██████"
