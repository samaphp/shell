#!/bin/bash

# Script to check if Github Copilot working fine or having network issue
# https://docs.github.com/en/copilot/managing-copilot/managing-github-copilot-in-your-organization/configuring-your-proxy-server-or-firewall-for-copilot
domains=(
  "github.com"
  "api.github.com"
  "copilot-telemetry.githubusercontent.com"
  "default.exp-tas.com"
  "origin-tracker.githubusercontent.com"
  "githubcopilot.com"
  "copilot-proxy.githubusercontent.com"
)

# Function to check domain status
check_domain() {
  curl --max-time 5 -o /dev/null --silent --head --write-out "%{http_code}" "$1"
}

# Loop through the domains and check status
for domain in "${domains[@]}"; do
  status=$(check_domain "$domain")
  if [ "$status" -ne 000 ]; then
    echo "[OK] $domain is working fine."
  else
    echo "[FAIL] $domain failed (timeout). You can route the ip manually, check here: https://dnschecker.org/domain-ip-lookup.php?query=$domain&dns=google"
  fi
done