#!/bin/bash
# Install gitpod

mkdir -p ~/.local/bin
curl -L https://github.com/gitpod-io/run-gp/releases/download/v0.1.7/run-gp_0.1.7_Linux_amd64 -o ~/.local/bin/run-gp
chmod +x ~/.local/bin/run-gp

# depend on your system this might be not needed
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
