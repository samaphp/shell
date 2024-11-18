#!/bin/bash
# Manjaro Arch setup

sudo pacman -Syu --noconfirm
# sudo pacman -S --noconfirm base-devel git curl wget vim

# Install zsh and Oh My Zsh
sudo pacman -S --noconfirm zsh
chsh -s $(which zsh)
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

sudo pacman -S --needed base-devel

# Install AUR helper (yay) https://github.com/Jguer/yay
if ! command -v yay &> /dev/null
then
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm
    cd ..
    rm -rf yay
fi

yay -S postman-bin --noconfirm
yay -S albert --noconfirm
#yay -S slack --noconfirm
yay -S slack-desktop --noconfirm
# Install Visual Studio Code (via AUR) and setup required plugins (cline?)
yay -S visual-studio-code-bin --noconfirm
code --install-extension saoudrizwan.claude-dev
code --install-extension mcright.auto-save
code --install-extension DEVSENSE.phptools-vscode
echo '[{"key":"ctrl+shift+t","command":"-workbench.action.reopenClosedEditor"},{"key":"ctrl+shift+t","command":"workbench.action.terminal.toggleTerminal"}]' > ~/.config/Code/User/keybindings.json
yay -S phpstorm --noconfirm
yay -S phpstorm-jre --noconfirm # phpstorm own JRE bundle, required as Java runtime
yay -S albert --noconfirm

# Install Google Chrome (via AUR)
yay -S --noconfirm google-chrome

sudo pacman -S gnome-tweaks

# Run albert on startup
ln -s /usr/share/applications/albert.desktop ~/.config/autostart/

# Install Docker
sudo pacman -S --noconfirm docker
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER

# Install Lando
/bin/bash -c "$(curl -fsSL https://get.lando.dev/setup-lando.sh)" -- --yes
# run: `lando setup --debug` to continue setup if it fails

# Install other essential packages
sudo pacman -S --noconfirm htop neofetch btop

# install fonts
sudo pacman -S noto-fonts

# Desktime installation
## install some libraries
sudo pacman -S libappindicator-gtk3 libnotify
sudo pacman -S strace
## install fuse2
wget https://archive.archlinux.org/packages/f/fuse2/fuse2-2.9.9-5-x86_64.pkg.tar.zst
sudo pacman -U ./fuse2-2.9.9-5-x86_64.pkg.tar.zst
## install AppImage launcher
yay -S appimagelauncher
## chmod +x ./DeskTime-x86_64.AppImage
# Now run ./DeskTime-x86_64.AppImage --appimage-extract-and-run

#- add Google chrome person (elc)
#- login into Gitlab
#- Set system Arabic font
#- Get my Note backup
#- enable night light

# Install java maven
#sudo pacman -S jdk-openjdk maven
#echo 'export JAVA_HOME=/usr/lib/jvm/java-22-openjdk' >> ~/.bashrc

# Clean up
sudo pacman -Rns $(pacman -Qdtq) --noconfirm

echo "\nSetup complete! You may need to log out or restart for some changes to take effect."
