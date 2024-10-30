#!/bin/bash
# To extract all domains from Apache vhosts

SITES_ENABLED_DIR="/etc/apache2/sites-enabled"

for config_file in "$SITES_ENABLED_DIR"/*.conf; do
    grep -E 'ServerName|ServerAlias' "$config_file" | awk '{print $2}' | sort -u
done
