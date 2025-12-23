#!/usr/bin/env bash

# SSH Access Report (tabular, deduplicated)
# Supports: --last 24h | 7d | 2h

LAST="24h"

if [[ "$1" == "--last" && -n "$2" ]]; then
  LAST="$2"
fi

# Convert shorthand to journalctl format
if [[ "$LAST" =~ ^([0-9]+)h$ ]]; then
  SINCE="${BASH_REMATCH[1]} hours ago"
elif [[ "$LAST" =~ ^([0-9]+)d$ ]]; then
  SINCE="${BASH_REMATCH[1]} days ago"
else
  echo "Invalid --last value. Use formats like: 24h, 7d, 2h"
  exit 1
fi

printf "%-25s  %-8s  %-6s  %-8s  %-9s  %-12s\n" \
  "TIMESTAMP" "USER" "PORT" "ACTIVITY" "STATUS" "SIGNATURE"
printf "%-19s  %-8s  %-6s  %-8s  %-9s  %-12s\n" \
  "-------------------------" "--------" "------" "--------" "---------" "------------"

journalctl -u ssh --since "$SINCE" --no-pager -o short-iso | awk '
{
  # Clean timestamp from $1 only
  ts_raw = $1
  sub(/\..*/, "", ts_raw)     # remove fractional seconds + timezone
  gsub("T", " ", ts_raw)      # ISO → human
  ts = ts_raw

  # LOGIN SUCCESS
  if ($0 ~ /Accepted/) {
    user=""; port=""; sig=""
    for (i=1; i<=NF; i++) {
      if ($i == "for") user=$(i+1)
      if ($i == "port") port=$(i+1)
      if ($i == "publickey" || $i == "password") sig=$i
    }
    printf "%-19s  %-8s  %-6s  %-8s  %-9s  %-12s\n",
      ts, user, port, "LOGIN", "ACCEPTED", sig
  }

  # LOGIN FAILED
  else if ($0 ~ /Failed/) {
    user=""; port=""; sig="password"
    for (i=1; i<=NF; i++) {
      if ($i == "for") user=$(i+1)
      if ($i == "port") port=$(i+1)
    }
    printf "%-19s  %-8s  %-6s  %-8s  %-9s  %-12s\n",
      ts, user, port, "LOGIN", "FAILED", sig
  }

  # LOGOUT
  else if ($0 ~ /session closed/) {
    user=$(NF)
    printf "%-19s  %-8s  %-6s  %-8s  %-9s  %-12s\n",
      ts, user, "-", "LOGOUT", "CLOSED", "session"
  }
}'
