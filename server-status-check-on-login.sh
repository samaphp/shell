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
echo "Hostname      : $(hostname)"
echo "Uptime        : $(uptime -p)"
echo "Boot Time     : $(who -b | awk '{print $3, $4}')"
echo "CPU Load      : $(cut -d ' ' -f1-3 /proc/loadavg)"
echo "Memory        : $(free -h | awk '/Mem:/ {printf "%s used / %s total (%.1f%%)\n", $3, $2, $3/$2 * 100}')"
echo "Swap          : $(free -h | awk '/Swap:/ {printf "%s used / %s total\n", $3, $2}')"
echo "Disk (/)      : $(df -h / | awk 'NR==2 {print $3 " used / " $2 " total (" $5 " used)"}')"

# CPU temperature (requires lm_sensors)
if command -v sensors >/dev/null 2>&1; then
  temp=$(sensors | grep -m 1 'Package id 0:' | awk '{print $4}')
  [ -n "$temp" ] && echo "CPU Temp      : $temp"
fi

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

# Top 3 memory processes
echo ""
echo -e "${YELLOW}📈 Top Memory Processes${NC}"
ps -eo pid,comm,%mem --sort=-%mem | head -n 4

# Recently failed services
echo ""
echo -e "${YELLOW}❌ Failed Services (if any)${NC}"
systemctl --failed --no-legend || echo "  None"

echo ""
