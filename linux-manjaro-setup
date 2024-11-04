#!/bin/bash
# Manjaro Arch setup

sudo pacman -Syu --noconfirm
# sudo pacman -S --noconfirm base-devel git curl wget vim

# Install zsh and Oh My Zsh
sudo pacman -S --noconfirm zsh
chsh -s $(which zsh)
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Install AUR helper (yay) https://github.com/Jguer/yay
if ! command -v yay &> /dev/null
then
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm
    cd ..
    rm -rf yay
fi

# Install Visual Studio Code (via AUR) and setup required plugins
yay -S --noconfirm visual-studio-code-bin

# Install Google Chrome (via AUR)
yay -S --noconfirm google-chrome

# Install Docker
sudo pacman -S --noconfirm docker
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER

# Install other essential packages
sudo pacman -S --noconfirm htop neofetch

# Clean up
sudo pacman -Rns $(pacman -Qdtq) --noconfirm

echo "\nSetup complete! You may need to log out or restart for some changes to take effect."
