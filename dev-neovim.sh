#/bin/sh
# setup neovim
sudo zypper install cmake

git clone https://github.com/neovim/neovim.git
cd neovim
make CMAKE_BUILD_TYPE=RelWithDebInfo
sudo make install
mkdir ~/.config/nvim
cd ~/.config/nvim
wget https://raw.githubusercontent.com/nvim-lua/kickstart.nvim/refs/heads/master/init.lua


# :Mason
# Ctrl+F
# php
# Theme https://github.com/morhetz/gruvbox
