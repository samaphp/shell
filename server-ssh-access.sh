#!/usr/bin/env bash

# SSH Access Report (tabular, deduplicated)
# Optional: --include-noise
# Optional time filter: --last <Nh|Nd> like --last 24h | 7d | 2h

LAST="24h"
SHOW_NOISE=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --last)
      LAST="$2"
      shift 2
      ;;
    --include-noise)
      SHOW_NOISE=1
      shift
      ;;
    *)
      echo "Unknown option: $1"
      echo "Usage: $0 [--last <Nh|Nd>] [--include-noise]"
      exit 1
      ;;
  esac
done

# Convert shorthand time
if [[ "$LAST" =~ ^([0-9]+)h$ ]]; then
  SINCE="${BASH_REMATCH[1]} hours ago"
elif [[ "$LAST" =~ ^([0-9]+)d$ ]]; then
  SINCE="${BASH_REMATCH[1]} days ago"
else
  echo "Invalid --last value (use 24h, 7d, 18d)"
  exit 1
fi

printf "%-25s  %-8s  %-6s  %-8s  %-9s  %-12s\n" \
  "TIMESTAMP" "USER" "PORT" "ACTIVITY" "STATUS" "SIGNATURE"
printf "%-19s  %-8s  %-6s  %-8s  %-9s  %-12s\n" \
  "-------------------------" "--------" "------" "--------" "---------" "------------"

journalctl -u ssh --since "$SINCE" --no-pager -o short-iso | awk -v show_noise="$SHOW_NOISE" '
{
  # --- Timestamp cleanup ---
  ts = $1
  sub(/\..*/, "", ts)
  gsub("T", " ", ts)

  # --- Successful LOGIN (real only) ---
  if ($0 ~ /sshd.*Accepted (publickey|password) for /) {

    user=""; port=""; sig=""; ip=""

    for (i=1; i<=NF; i++) {
      if ($i == "for") user=$(i+1)
      if ($i == "from") ip=$(i+1)
      if ($i == "port") port=$(i+1)
      if ($i == "publickey" || $i == "password") sig=$i
    }

    # Exclude localhost activity
    if (user != "" && port != "" && ip != "127.0.0.1" && ip != "::1") {
      printf "%-19s  %-8s  %-11s  %-8s  %-9s  %-16s\n",
        ts, user, port, "LOGIN", "ACCEPTED", sig
    }
  }

  # --- Failed LOGIN (real only) ---
  else if ($0 ~ /sshd.*Failed (password|publickey) for /) {

    user=""; port=""; ip=""

    for (i=1; i<=NF; i++) {
      if ($i == "for") user=$(i+1)
      if ($i == "from") ip=$(i+1)
      if ($i == "port") port=$(i+1)
    }

    if (user != "" && port != "" && ip != "127.0.0.1" && ip != "::1") {
      printf "%-19s  %-8s  %-11s  %-8s  %-9s  %-16s\n",
        ts, user, port, "LOGIN", "FAILED", "password"
    }
  }

  # --- LOGOUT ---
  else if ($0 ~ /sshd.*session closed for user /) {
    user=$(NF)
    printf "%-19s  %-8s  %-11s  %-8s  %-9s  %-16s\n",
      ts, user, "-", "LOGOUT", "CLOSED", "session"
  }

  # --- Protocol NOISE (optional) ---
  else if (show_noise && $0 ~ /(banner exchange|invalid protocol identifier|kex_exchange_identification)/) {

    port="-"
    for (i=1; i<=NF; i++) {
      if ($i == "port") port=$(i+1)
    }

    sig="protocol-error"
    if ($0 ~ /GET \/ HTTP/) sig="http-on-ssh"
    if ($0 ~ /banner exchange/) sig="banner-error"

    printf "%-19s  %-8s  %-11s  %-8s  %-9s  %-16s\n",
      ts, "-", port, "NOISE", "REJECTED", sig
  }
}'
