#!/bin/bash
# zsh ubuntu install
# this script will install the zsh from source regardless if the linux distribution

#Requirements for ubuntu:
#sudo apt-get install libpcre3-dev
#sudo apt-get install libreadline-dev
#sudo apt-get install build-essential
#sudo apt-get install libncurses5-dev libncursesw5-dev
#sudo apt-get install autoconf

# Variables
ZSH_VERSION="5.9"  # Update this to the latest version if needed
ZSH_TAR="zsh-$ZSH_VERSION.tar.xz"
ZSH_URL="https://sourceforge.net/projects/zsh/files/zsh/$ZSH_VERSION/$ZSH_TAR/download"
BUILD_DIR="/tmp/zsh-build"

# Function to check for required commands
function check_command() {
    command -v "$1" >/dev/null 2>&1 || {
        echo >&2 "Error: '$1' is not installed. Please install it before running this script."
        MISSING_DEPS=true
    }
}

# Function to check for ncurses library
function check_ncurses() {
    echo "Checking for ncurses development library..."
    # Try to find ncurses.h in standard include paths
    if ! find /usr/include /usr/local/include -name "ncurses.h" -print -quit | grep -q 'ncurses.h'; then
        echo "Error: 'ncurses' development library not found."
        echo "Please install the 'ncurses-devel' or 'libncurses5-dev' package on your system."
        MISSING_DEPS=true
    else
        echo "ncurses development library found."
    fi
}

# Check for required commands
echo "Checking for required tools..."
MISSING_DEPS=false
REQUIRED_CMDS=("make" "gcc" "curl" "tar" "sudo" "autoconf")
for cmd in "${REQUIRED_CMDS[@]}"; do
    check_command "$cmd"
done

# Check for ncurses development library
check_ncurses

if [ "$MISSING_DEPS" = true ]; then
    echo "One or more required tools or libraries are missing. Please install them and rerun the script."
    exit 1
fi

# Create a build directory
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR" || exit

# Download Zsh source code
echo "Downloading Zsh $ZSH_VERSION..."
curl -L "$ZSH_URL" -o "$ZSH_TAR"

# Verify download (optional but recommended)
# You can add checksum verification here if needed

# Extract the source code
echo "Extracting Zsh..."
tar -xf "$ZSH_TAR"

# Navigate to the source directory
cd "zsh-$ZSH_VERSION" || exit

# Configure the build
echo "Configuring the build..."
./configure --prefix=/usr/local

# Compile the source code
echo "Compiling Zsh..."
make -j"$(nproc)"

# Install Zsh
echo "Installing Zsh..."
sudo make install

# Clean up
echo "Cleaning up..."
cd ~ || exit
rm -rf "$BUILD_DIR"

echo "Zsh $ZSH_VERSION has been installed successfully!"

# Automate Zsh configuration
echo "Automating Zsh configuration..."

# Define default Zsh configuration content
ZSHRC_CONTENT='
# Lines configured by install script

# Set prompt
#PROMPT="%n@%m %1~ %# "
PROMPT="%F{blue}%~%f %F{green}❯%f "    # Current directory in blue, followed by a green arrow
RPROMPT="%F{yellow}%n@%m%f"            # Right prompt with username and hostname in yellow

# Enable command correction
setopt CORRECT

# Enable command auto-completion
autoload -Uz compinit
compinit

# Set history options
HISTSIZE=10000000
SAVEHIST=10000000
HISTFILE=~/.zsh_history

# Enable history sharing
setopt SHARE_HISTORY

# Load all plugins (if any)
# Add your plugins below
alias ll="ls -laht"

# Configure WORDCHARS to exclude "/"
WORDCHARS="*?_-.[]~=&;!#$%^(){}<>"

# Key bindings for word navigation and line control
bindkey "^[[1;5D" backward-word       # Ctrl+Left for moving one word back
bindkey "^[[1;5C" forward-word        # Ctrl+Right for moving one word forward
bindkey "^[[H" beginning-of-line      # Home key moves to the beginning of the line
bindkey "^[[F" end-of-line            # End key moves to the end of the line
bindkey "^[[1~" beginning-of-line     # Alternative Home key
bindkey "^[[4~" end-of-line           # Alternative End key
'

# Create default Zsh configuration files if they don't exist
if [ ! -f "$HOME/.zshrc" ]; then
    echo "Creating default .zshrc..."
    echo "$ZSHRC_CONTENT" > "$HOME/.zshrc"
fi

# Create other startup files as empty if they don't exist
for file in .zshenv .zprofile .zlogin .zlogout; do
    if [ ! -f "$HOME/$file" ]; then
        echo "Creating $file..."
        touch "$HOME/$file"
    fi
done

# Install zsh-autosuggestions plugin
echo "Installing zsh-autosuggestions plugin..."
if [ ! -d "$ZSH_AUTOSUGGESTIONS_DIR" ]; then
    mkdir -p "${ZSH_AUTOSUGGESTIONS_DIR%/*}"
    git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_AUTOSUGGESTIONS_DIR"
else
    echo "zsh-autosuggestions already installed."
fi

echo "Zsh $ZSH_VERSION and zsh-autosuggestions have been installed and configured successfully!"

# Ensure Zsh is listed in /etc/shells
if ! grep -Fxq "$ZSH_PATH" /etc/shells; then
    echo "Adding $ZSH_PATH to /etc/shells..."
    echo "$ZSH_PATH" | sudo tee -a /etc/shells
else
    echo "$ZSH_PATH is already listed in /etc/shells."
fi

# Set Zsh as the default shell
echo "Setting Zsh as the default shell..."
chsh -s /usr/local/bin/zsh

echo "Please log out and log back in for the changes to take effect."
