#!/bin/bash
# This script will trust a specific certificate of a website (local certificates created from Lando for example)
# Author: ChatGPT
# Instructed by: Saud Alfadhli

# Check if certutil is installed (for Firefox use)
check_certutil() {
    if ! command -v certutil &> /dev/null
    then
        echo "Error: certutil command not found. Please install it before running this script."
        echo "You can install it by running:"
        echo "  - On Debian/Ubuntu: sudo apt install libnss3-tools"
        echo "  - On Fedora: sudo dnf install nss-tools"
        exit 1
    fi
}

# Check if a certificate path was provided as an argument
if [ -z "$1" ]; then
    echo "Usage: $0 /path/to/certificate.crt"
    exit 1
fi

CERT_PATH=$1

# Check if the certificate file exists
if [ ! -f "$CERT_PATH" ]; then
    echo "Error: Certificate file $CERT_PATH not found!"
    exit 1
fi

# Prompt the user to choose Chrome or Firefox
echo "Where do you want to trust this certificate?"
echo "1) Google Chrome (System-wide)"
echo "2) Firefox (Firefox only)"
read -p "Enter the number corresponding to your choice: " choice

case $choice in
    1)
        # For Google Chrome (System-wide)
        echo "You chose Google Chrome (System-wide)"
        echo "Copying $CERT_PATH to /usr/local/share/ca-certificates/"
        sudo cp "$CERT_PATH" /usr/local/share/ca-certificates/

        # Update the system certificate store
        echo "Updating the certificate store..."
        sudo update-ca-certificates

        if [ $? -eq 0 ]; then
            echo "Certificate successfully trusted system-wide!"
        else
            echo "Error occurred while updating the system certificate store."
            exit 1
        fi

        echo "Please restart Google Chrome for the changes to take effect."
        ;;
    2)
        # For Firefox
        echo "You chose Firefox (Firefox only)"
        
        # Check if certutil is installed
        check_certutil

        # Locate Firefox's certificate store for the current user
        FIREFOX_PROFILE_DIR=$(find ~/.mozilla/firefox -name "*.default*" | head -n 1)

        if [ -z "$FIREFOX_PROFILE_DIR" ]; then
            echo "Firefox profile directory not found!"
            exit 1
        fi

        # Use certutil to add the certificate to Firefox's certificate store
        echo "Importing the certificate to Firefox's certificate store..."

        certutil -A -n "Trusted Certificate" -t "TC,C,C" -i "$CERT_PATH" -d sql:"$FIREFOX_PROFILE_DIR"

        if [ $? -eq 0 ]; then
            echo "Certificate successfully imported to Firefox!"
        else
            echo "Error occurred while importing the certificate to Firefox."
            exit 1
        fi

        echo "Please restart Firefox for the changes to take effect."
        ;;
    *)
        echo "Invalid choice! Please run the script again and select a valid option."
        exit 1
        ;;
esac
