#!/bin/bash
set -e
mkdir -p ~/.local/share/fonts
tmp=$(mktemp -d)
curl -L -o "$tmp/font.zip" https://github.com/ryanoasis/nerd-fonts/releases/latest/download/0xProto.zip
unzip -q "$tmp/font.zip" -d "$tmp/fonts"
mv "$tmp/fonts/"* ~/.local/share/fonts
fc-cache -fv
rm -rf "$tmp"
