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

# starters
# https://github.com/nvim-lua/kickstart.nvim # build everything, full control (Very easy to customize)
# https://www.lazyvim.org/ # clean, dev-friendly. Effortless to customize and maintain (Very easy to customize)
# https://astronvim.com/ # opinionated, full-featured. feels like VSCode (Moderate to customize)
# https://www.lunarvim.org/ # Heavy, but everything’s already wired. feels like VSCode (Moderate to customize)
# https://nvchad.com/ # fast, and visually slick (Moderate to customize)
