#!/bin/bash
# Setup VSCode

# Dev tools
code --install-extension eamodio.gitlens
code --install-extension mikestead.dotenv

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

# Extra
#code --install-extension ms-azuretools.vscode-docker
#code --install-extension humao.rest-client
