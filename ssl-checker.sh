#!/usr/bin/env bash

# SSL Certificate Expiration Checker
# Reads domains from a .txt file and reports SSL certificate expiration dates
# Also checks if the certificate chain is complete (important for API integrations)
#
# File Format (domains.txt):
#   One domain per line
#   Optionally specify port with domain:port format (default is 443)
#   Lines starting with # are comments and will be skipped
#   Empty lines are ignored
#
# Chain Validation:
#   - OK        = Full certificate chain present (works for browsers and APIs)
#   - MISSING   = No intermediate certificates (works in browsers, fails in APIs)
#   - INCOMPLETE = Partial chain (may cause compatibility issues)
#
# Examples:
#   example.com
#   google.com:443
#   api.example.com:8443
#   # This is a comment

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
    echo "Arguments:"
    echo "  <domains_file>  A .txt file containing one domain per line"
    echo ""
    echo "Options:"
    echo "  -c, --check     Check mode: outputs 'OK' or list of domains with SSL/chain issues"
    echo ""
    echo "File Format Example (domains.txt):"
    echo "  example.com"
    echo "  google.com"
    echo "  github.com:8443"
    echo "  # This is a comment and will be skipped"
    echo ""
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
CHAIN_OK=0
CHAIN_ISSUES=0
EXPIRED_DOMAINS=()
CHAIN_FAILED_DOMAINS=()

# Function to get SSL expiration date
get_cert_expiry() {
    local domain="$1"
    local port="${2:-443}"
    
    timeout "$TIMEOUT" openssl s_client -connect "$domain:$port" -servername "$domain" </dev/null 2>/dev/null | \
    openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2 || echo "ERROR"
}

# Function to check if certificate chain is complete
check_cert_chain() {
    local domain="$1"
    local port="${2:-443}"
    local cert_file="$3"
    
    # Get the full certificate chain from the server and capture verification result
    timeout "$TIMEOUT" openssl s_client -connect "$domain:$port" -servername "$domain" </dev/null 2>/dev/null > "$cert_file" || return 1
    
    # Extract the verify return code from openssl output
    local verify_code=$(grep "Verify return code" "$cert_file" 2>/dev/null | grep -oP '(?<=code: )\d+' || echo "1")
    
    case "$verify_code" in
        0)
            # Code 0 = Chain is valid and complete
            echo "OK"
            return 0
            ;;
        20)
            # Code 20 = Unable to get local issuer certificate (missing chain)
            echo "MISSING"
            return 1
            ;;
        *)
            # Other codes = Various chain issues
            local cert_count=$(grep -c "^-----BEGIN CERTIFICATE-----$" "$cert_file" 2>/dev/null || echo "0")
            if [[ "$cert_count" -lt 2 ]]; then
                echo "MISSING"
            else
                echo "INCOMPLETE"
            fi
            return 1
            ;;
    esac
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

# Track if we need to print header for check mode with failures
PRINT_HEADER=false

# Print header (for normal mode or check mode with failures)
print_table_header() {
    echo ""
    printf "%-40s %-25s %-15s %-10s %-12s\n" "Domain" "Expiration Date" "Days Left" "Status" "Chain"
    printf "%-40s %-25s %-15s %-10s %-12s\n" "$(printf '=%.0s' {1..40})" "$(printf '=%.0s' {1..25})" "$(printf '=%.0s' {1..15})" "$(printf '=%.0s' {1..10})" "$(printf '=%.0s' {1..12})"
    PRINT_HEADER=true
}

# Only print header immediately in normal mode
if [[ "$CHECK_MODE" != "true" ]]; then
    print_table_header
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
    
    # Create temporary certificate file
    CERT_CHAIN_TMP=$(mktemp)
    
    # Get certificate expiration date
    expiry_date=$(get_cert_expiry "$host" "$port")
    
    # Check certificate chain
    chain_status=$(check_cert_chain "$host" "$port" "$CERT_CHAIN_TMP")
    
    if [[ "$expiry_date" == "ERROR" ]] || [[ -z "$expiry_date" ]]; then
        ((INVALID++))
        EXPIRED_DOMAINS+=("$domain|Could not retrieve|N/A|ERROR|N/A")
        
        if [[ "$CHECK_MODE" != "true" ]]; then
            printf "%-40s %-25s %-15s ${RED}%-10s${NC} %-12s\n" "$domain" "Could not retrieve" "N/A" "ERROR" "N/A"
        fi
    else
        days_left=$(days_until_expiry "$expiry_date")
        
        if [[ "$days_left" == "0" ]]; then
            # Date parsing failed
            ((INVALID++))
            EXPIRED_DOMAINS+=("$domain|$expiry_date|N/A|ERROR|$chain_status")
            if [[ "$CHECK_MODE" != "true" ]]; then
                printf "%-40s %-25s %-15s ${RED}%-10s${NC} %-12s\n" "$domain" "$expiry_date" "N/A" "ERROR" "$chain_status"
            fi
        elif [[ $days_left -lt 0 ]]; then
            ((EXPIRED++))
            EXPIRED_DOMAINS+=("$domain|$expiry_date|$days_left|EXPIRED|$chain_status")
            if [[ "$CHECK_MODE" != "true" ]]; then
                if [[ "$chain_status" == "OK" ]]; then
                    printf "%-40s %-25s %-15s ${RED}%-10s${NC} ${GREEN}%-12s${NC}\n" "$domain" "$expiry_date" "$days_left" "EXPIRED" "$chain_status"
                else
                    printf "%-40s %-25s %-15s ${RED}%-10s${NC} ${RED}%-12s${NC}\n" "$domain" "$expiry_date" "$days_left" "EXPIRED" "$chain_status"
                fi
            fi
        elif [[ $days_left -lt 30 ]]; then
            ((WARNING++))
            if [[ "$chain_status" != "OK" ]]; then
                CHAIN_FAILED_DOMAINS+=("$domain|$expiry_date|$days_left|WARNING|$chain_status")
            fi
            if [[ "$CHECK_MODE" != "true" ]]; then
                if [[ "$chain_status" == "OK" ]]; then
                    printf "%-40s %-25s %-15s ${YELLOW}%-10s${NC} ${GREEN}%-12s${NC}\n" "$domain" "$expiry_date" "$days_left" "WARNING" "$chain_status"
                else
                    printf "%-40s %-25s %-15s ${YELLOW}%-10s${NC} ${RED}%-12s${NC}\n" "$domain" "$expiry_date" "$days_left" "WARNING" "$chain_status"
                fi
            fi
        else
            ((VALID++))
            if [[ "$chain_status" != "OK" ]]; then
                CHAIN_FAILED_DOMAINS+=("$domain|$expiry_date|$days_left|VALID|$chain_status")
            fi
            if [[ "$CHECK_MODE" != "true" ]]; then
                if [[ "$chain_status" == "OK" ]]; then
                    printf "%-40s %-25s %-15s ${GREEN}%-10s${NC} ${GREEN}%-12s${NC}\n" "$domain" "$expiry_date" "$days_left" "VALID" "$chain_status"
                else
                    printf "%-40s %-25s %-15s ${GREEN}%-10s${NC} ${RED}%-12s${NC}\n" "$domain" "$expiry_date" "$days_left" "VALID" "$chain_status"
                fi
            fi
        fi
    fi
    
    # Clean up temp file
    rm -f "$CERT_CHAIN_TMP"
    
done < "$CERT_FILE"

# Output based on mode
if [[ "$CHECK_MODE" == "true" ]]; then
    # Check mode: output OK or table with failures
    if [[ $EXPIRED -eq 0 ]] && [[ $INVALID -eq 0 ]] && [[ ${#CHAIN_FAILED_DOMAINS[@]} -eq 0 ]]; then
        echo "OK"
        exit 0
    else
        # Print header and failed domains
        print_table_header
        
        # Print expired domains
        for item in "${EXPIRED_DOMAINS[@]}"; do
            IFS='|' read -r domain expiry_date days_left status chain_status <<< "$item"
            if [[ "$chain_status" == "OK" ]]; then
                printf "%-40s %-25s %-15s ${RED}%-10s${NC} ${GREEN}%-12s${NC}\n" "$domain" "$expiry_date" "$days_left" "$status" "$chain_status"
            else
                printf "%-40s %-25s %-15s ${RED}%-10s${NC} ${RED}%-12s${NC}\n" "$domain" "$expiry_date" "$days_left" "$status" "$chain_status"
            fi
        done
        
        # Print domains with chain issues
        for item in "${CHAIN_FAILED_DOMAINS[@]}"; do
            IFS='|' read -r domain expiry_date days_left status chain_status <<< "$item"
            if [[ "$status" == "WARNING" ]]; then
                printf "%-40s %-25s %-15s ${YELLOW}%-10s${NC} ${RED}%-12s${NC}\n" "$domain" "$expiry_date" "$days_left" "$status" "$chain_status"
            else
                printf "%-40s %-25s %-15s ${GREEN}%-10s${NC} ${RED}%-12s${NC}\n" "$domain" "$expiry_date" "$days_left" "$status" "$chain_status"
            fi
        done
        echo ""
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
    echo ""
    echo "Note: The 'Chain' column shows if the SSL certificate chain is complete:"
    echo -e "  ${GREEN}OK${NC}        - Full certificate chain present (works for APIs/integrations)"
    echo -e "  ${RED}MISSING${NC}    - No intermediate certificates (browser only, API will fail)"
    echo -e "  ${RED}INCOMPLETE${NC} - Partial chain (may have compatibility issues)"
    echo "========================================="
    echo ""
fi
