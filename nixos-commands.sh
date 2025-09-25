#!/bin/bash
# just a commands for NixOS quick fixes

# to use `npm install -g`
npm config set prefix ~/.npm-packages
export PATH=~/.npm-packages/bin:$PATH
# Optionally add export NODE_PATH=~/.npm-packages/lib/node_modules to the same file.
