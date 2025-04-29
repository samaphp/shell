#!/bin/bash
# Display system summary and check selected service statuses once log into server
# echo '~/server-status-check-on-login.sh' >> ~/.bash_profile

# List of services to check
SERVICES=(
  php-fpm-82.service
  nginx.service
  mysqld.service
  cron.service
)

# Colors
GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[33m"
NC="\e[0m"  # No Color

echo ""
echo -e "${YELLOW}🖥️  System Summary${NC}"
echo "Hostname: $(hostname)"
echo "Uptime  : $(uptime -p)"
echo "CPU Load: $(cut -d ' ' -f1-3 /proc/loadavg)"
echo "Memory  : $(free -h | awk '/Mem:/ {printf "%s used / %s total (%.1f%%)\n", $3, $2, $3/$2 * 100}')"

echo ""
echo -e "${YELLOW}🔧 Service Status${NC}"
for svc in "${SERVICES[@]}"; do
  status=$(systemctl is-active "$svc")
  case "$status" in
    active)  color="$GREEN" ;;
    failed)  color="$RED" ;;
    *)       color="$YELLOW" ;;
  esac
  printf "  * %-20s [%b%s%b]\n" "$svc" "$color" "$status" "$NC"
done
echo ""
