#!/usr/bin/env bash

# SSL Certificate Expiration Checker
# Reads domains from a file and reports SSL certificate expiration dates

set -euo pipefail

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Configuration
TIMEOUT=5
CERT_FILE="${1:?Usage: $0 <domains_file>}"

# Check if file exists
if [[ ! -f "$CERT_FILE" ]]; then
    echo "Error: File '$CERT_FILE' not found"
    exit 1
fi

# Check if openssl is available
if ! command -v openssl &> /dev/null; then
    echo "Error: openssl is not installed"
    exit 1
fi

# Function to get SSL expiration date
get_cert_expiry() {
    local domain="$1"
    local port="${2:-443}"
    
    # Use openssl s_client to get the certificate
    timeout "$TIMEOUT" openssl s_client -connect "$domain:$port" -servername "$domain" </dev/null 2>/dev/null | \
    openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2
}

# Function to calculate days until expiration
days_until_expiry() {
    local expiry_date="$1"
    
    # Convert to timestamp
    local expiry_timestamp
    expiry_timestamp=$(date -d "$expiry_date" +%s 2>/dev/null || date -jf "%b %d %T %Z %Y" "$expiry_date" +%s 2>/dev/null)
    
    local now_timestamp
    now_timestamp=$(date +%s)
    
    local days_diff=$(( (expiry_timestamp - now_timestamp) / 86400 ))
    echo "$days_diff"
}

# Function to color status based on days remaining
color_status() {
    local days="$1"
    
    if [[ $days -lt 0 ]]; then
        echo -e "${RED}EXPIRED${NC}"
    elif [[ $days -lt 30 ]]; then
        echo -e "${YELLOW}WARNING${NC}"
    else
        echo -e "${GREEN}VALID${NC}"
    fi
}

# Print header
printf "\n%-40s %-25s %-15s %-10s\n" "Domain" "Expiration Date" "Days Left" "Status"
printf "%-40s %-25s %-15s %-10s\n" "$(printf '=%.0s' {1..40})" "$(printf '=%.0s' {1..25})" "$(printf '=%.0s' {1..15})" "$(printf '=%.0s' {1..10})"

# Read domains from file and check certificates
while IFS= read -r line; do
    # Skip empty lines and comments
    [[ -z "$line" || "$line" =~ ^# ]] && continue
    
    # Remove leading/trailing whitespace
    domain=$(echo "$line" | xargs)
    
    # Check if domain contains port
    if [[ "$domain" == *":"* ]]; then
        host="${domain%:*}"
        port="${domain#*:}"
    else
        host="$domain"
        port=443
    fi
    
    # Get certificate expiration date
    expiry_date=$(get_cert_expiry "$host" "$port" 2>/dev/null || echo "ERROR")
    
    if [[ "$expiry_date" == "ERROR" || -z "$expiry_date" ]]; then
        printf "%-40s %-25s %-15s %-10s\n" "$domain" "Could not retrieve" "N/A" "$(echo -e "${RED}ERROR${NC}")"
    else
        days_left=$(days_until_expiry "$expiry_date")
        status=$(color_status "$days_left")
        printf "%-40s %-25s %-15s %-10s\n" "$domain" "$expiry_date" "$days_left" "$status"
    fi
    
done < "$CERT_FILE"

echo ""
