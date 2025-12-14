#!/usr/bin/env bash

# SSL Certificate Expiration Checker
# Reads domains from a file and reports SSL certificate expiration dates

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Configuration
TIMEOUT=5
CHECK_MODE=false
CERT_FILE=""

# Parse arguments
if [[ $# -eq 0 ]]; then
    echo "Usage: $0 <domains_file> [-c|--check]"
    echo ""
    echo "Options:"
    echo "  -c, --check    Check mode: outputs 'OK' or list of expired domains"
    exit 1
fi

CERT_FILE="$1"
if [[ "${2:-}" == "-c" ]] || [[ "${2:-}" == "--check" ]]; then
    CHECK_MODE=true
fi

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

# Initialize counters
TOTAL=0
VALID=0
WARNING=0
EXPIRED=0
INVALID=0
EXPIRED_DOMAINS=()

# Function to get SSL expiration date
get_cert_expiry() {
    local domain="$1"
    local port="${2:-443}"
    
    timeout "$TIMEOUT" openssl s_client -connect "$domain:$port" -servername "$domain" </dev/null 2>/dev/null | \
    openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2 || echo "ERROR"
}

# Function to calculate days until expiration
days_until_expiry() {
    local expiry_date="$1"
    
    local expiry_timestamp
    expiry_timestamp=$(date -d "$expiry_date" +%s 2>/dev/null || date -jf "%b %d %T %Z %Y" "$expiry_date" +%s 2>/dev/null || echo "0")
    
    if [[ "$expiry_timestamp" == "0" ]]; then
        echo "0"
        return
    fi
    
    local now_timestamp
    now_timestamp=$(date +%s)
    
    local days_diff=$(( (expiry_timestamp - now_timestamp) / 86400 ))
    echo "$days_diff"
}

# Print header (only in normal mode)
if [[ "$CHECK_MODE" != "true" ]]; then
    echo ""
    printf "%-40s %-25s %-15s %-10s\n" "Domain" "Expiration Date" "Days Left" "Status"
    printf "%-40s %-25s %-15s %-10s\n" "$(printf '=%.0s' {1..40})" "$(printf '=%.0s' {1..25})" "$(printf '=%.0s' {1..15})" "$(printf '=%.0s' {1..10})"
fi

# Read domains from file and check certificates
while IFS= read -r line; do
    # Skip empty lines and comments
    [[ -z "$line" ]] && continue
    [[ "$line" =~ ^# ]] && continue
    
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
    
    ((TOTAL++))
    
    # Get certificate expiration date
    expiry_date=$(get_cert_expiry "$host" "$port")
    
    if [[ "$expiry_date" == "ERROR" ]] || [[ -z "$expiry_date" ]]; then
        ((INVALID++))
        EXPIRED_DOMAINS+=("$domain")
        
        if [[ "$CHECK_MODE" != "true" ]]; then
            printf "%-40s %-25s %-15s ${RED}%-10s${NC}\n" "$domain" "Could not retrieve" "N/A" "ERROR"
        fi
    else
        days_left=$(days_until_expiry "$expiry_date")
        
        if [[ "$days_left" == "0" ]]; then
            # Date parsing failed
            ((INVALID++))
            EXPIRED_DOMAINS+=("$domain")
            if [[ "$CHECK_MODE" != "true" ]]; then
                printf "%-40s %-25s %-15s ${RED}%-10s${NC}\n" "$domain" "$expiry_date" "N/A" "ERROR"
            fi
        elif [[ $days_left -lt 0 ]]; then
            ((EXPIRED++))
            EXPIRED_DOMAINS+=("$domain")
            if [[ "$CHECK_MODE" != "true" ]]; then
                printf "%-40s %-25s %-15s ${RED}%-10s${NC}\n" "$domain" "$expiry_date" "$days_left" "EXPIRED"
            fi
        elif [[ $days_left -lt 30 ]]; then
            ((WARNING++))
            if [[ "$CHECK_MODE" != "true" ]]; then
                printf "%-40s %-25s %-15s ${YELLOW}%-10s${NC}\n" "$domain" "$expiry_date" "$days_left" "WARNING"
            fi
        else
            ((VALID++))
            if [[ "$CHECK_MODE" != "true" ]]; then
                printf "%-40s %-25s %-15s ${GREEN}%-10s${NC}\n" "$domain" "$expiry_date" "$days_left" "VALID"
            fi
        fi
    fi
    
done < "$CERT_FILE"

# Output based on mode
if [[ "$CHECK_MODE" == "true" ]]; then
    # Check mode: output OK or list of expired domains
    if [[ $EXPIRED -eq 0 ]] && [[ $INVALID -eq 0 ]]; then
        echo "OK"
        exit 0
    else
        for domain in "${EXPIRED_DOMAINS[@]}"; do
            echo "$domain"
        done
        exit 1
    fi
else
    # Normal mode: show summary
    echo ""
    echo "========================================="
    echo "Summary:"
    echo "========================================="
    echo "Total domains checked: $TOTAL"
    echo -e "${GREEN}Valid: $VALID${NC}"
    echo -e "${YELLOW}Warning (< 30 days): $WARNING${NC}"
    echo -e "${RED}Expired: $EXPIRED${NC}"
    echo -e "${RED}Error/Invalid: $INVALID${NC}"
    echo "========================================="
    echo ""
fi
