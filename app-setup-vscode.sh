#!/bin/bash
# Setup VSCode

# Dev tools
code --install-extension eamodio.gitlens
code --install-extension mikestead.dotenv
code --install-extension hookyqr.beautify # for actively maintained alternative to with `meezilla.json`
code --install-extension mcright.auto-save

# SQL connector
code --install-extension mtxr.sqltools
code --install-extension mtxr.sqltools-driver-mysql

# PHP
code --install-extension ikappas.composer
code --install-extension bmewburn.vscode-intelephense-client
#code --install-extension xdebug.php-debug
#code --install-extension junstyle.php-cs-fixer
#code --install-extension ikappas.phpcs

# Laravel
code --install-extension ryannaddy.laravel-artisan
code --install-extension amiralizadeh9480.laravel-extra-intellisense

# Premium extensions
code --install-extension DEVSENSE.phptools-vscode # can replace `bmewburn.vscode-intelephense-client`

# AI assistant
code --install-extension github.copilot
code --install-extension github.copilot-chat
code --install-extension saoudrizwan.claude-dev

# Themes
code --install-extension zhuangtongfa.Material-theme # PHPStorm-like

# Extra
#code --install-extension ms-azuretools.vscode-docker
#code --install-extension humao.rest-client
#code --install-extension Shan.code-settings-sync # Workspace Configuration Sync

# Vim experience
#code --install-extension vscodevim.vim
#code --install-extension VSpaceCode.whichkey
#code --install-extension vspacecode.vspacecode
#code --install-extension asvetliakov.vscode-neovim
