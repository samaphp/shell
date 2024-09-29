#!/bin/bash
# This script will check if this list of domains has valid SSL certificate or not.
# Input file containing the list of domains
input_file="domains.txt"

# Check if input file exists
if [ ! -f "$input_file" ]; then
  echo "File $input_file does not exist!"
  exit 1
fi

# Loop through each domain in the file
while IFS= read -r domain; do
  if [ -n "$domain" ]; then
    # Use curl to check SSL certificate for the domain
    result=$(curl --head --connect-timeout 10 "https://$domain" 2>&1)
    
    # Check for SSL error in the curl output
    if echo "$result" | grep -q "SSL certificate problem"; then
      echo "[FAIL] $domain"
    else
      echo "[OK] $domain"
    fi
  fi
done < "$input_file"
