#!/usr/bin/env bash

# Accurate, read-only SSH security report
# Focused on clarity, correctness, and zero ambiguity

PASS=0
WARN=0
FAIL=0

result() {
  local label="$1"
  local value="$2"
  local status="$3"

  printf "%-30s : %-22s %s\n" "$label" "$value" "$status"

  case "$status" in
    PASS) ((PASS++)) ;;
    WARN) ((WARN++)) ;;
    FAIL) ((FAIL++)) ;;
  esac
}

get_cfg() {
  grep -Ei "^\s*$1\s+" /etc/ssh/sshd_config 2>/dev/null | tail -n1 | awk '{print $2}'
}

echo
echo "SSH SECURITY CHECK"
echo "=================="

# ---- Read SSH config safely ----
PORT="$(get_cfg Port)"
ROOT="$(get_cfg PermitRootLogin)"
PASSAUTH="$(get_cfg PasswordAuthentication)"
PUBKEY="$(get_cfg PubkeyAuthentication)"

PORT="${PORT:-22}"
ROOT="${ROOT:-default}"
PASSAUTH="${PASSAUTH:-default}"
PUBKEY="${PUBKEY:-default}"

# ---- SSH basics ----
result "SSH Port" "$PORT" $([[ "$PORT" != "22" ]] && echo PASS || echo WARN)

if [[ "$ROOT" == "no" ]]; then
  result "Root Login" "DISABLED" PASS
else
  result "Root Login" "ENABLED" FAIL
fi

if [[ "$PASSAUTH" == "no" ]]; then
  result "Password Authentication" "DISABLED" PASS
else
  result "Password Authentication" "ENABLED" FAIL
fi

if [[ "$PUBKEY" == "yes" ]]; then
  result "Public Key Auth" "ENABLED" PASS
else
  result "Public Key Auth" "NOT ENFORCED" WARN
fi

# ---- Protections ----
systemctl is-active --quiet fail2ban 2>/dev/null \
  && result "Fail2Ban" "ACTIVE" PASS \
  || result "Fail2Ban" "INACTIVE" FAIL

if command -v ufw >/dev/null && ufw status | grep -q "Status: active"; then
  result "Firewall Detected" "YES" WARN
else
  result "Firewall Detected" "NO" WARN
fi

# ---- Exposure analysis (derived, authoritative) ----
PUBLIC_LISTEN="NO"
ss -ltnp 2>/dev/null | grep -qE "(0.0.0.0|::):$PORT.*sshd" && PUBLIC_LISTEN="YES"

ACCESS_RESTRICTED="NO"
grep -Eq "^(AllowUsers|AllowGroups)" /etc/ssh/sshd_config 2>/dev/null && ACCESS_RESTRICTED="YES"

if [[ "$PUBLIC_LISTEN" == "YES" && "$ACCESS_RESTRICTED" == "NO" ]]; then
  result "SSH Exposure Level" "PUBLIC & UNRESTRICTED" WARN
elif [[ "$PUBLIC_LISTEN" == "YES" && "$ACCESS_RESTRICTED" == "YES" ]]; then
  result "SSH Exposure Level" "PUBLIC (RESTRICTED)" WARN
else
  result "SSH Exposure Level" "NOT PUBLIC" PASS
fi

# ---- Crypto hygiene ----
grep -Eq "^(Ciphers|MACs|KexAlgorithms)" /etc/ssh/sshd_config 2>/dev/null \
  && result "Crypto Hardening" "SET" PASS \
  || result "Crypto Hardening" "NOT SET" WARN

# ---- Summary ----
echo
echo "SUMMARY"
echo "-------"
echo "FAIL : $FAIL"
echo "WARN : $WARN"
echo "PASS : $PASS"

# ---- Actions ----
if (( FAIL > 0 )); then
  echo
  echo "CRITICAL ACTIONS"
  echo "----------------"
  [[ "$ROOT" != "no" ]] && echo "- Disable root SSH login"
  [[ "$PASSAUTH" != "no" ]] && echo "- Disable password authentication"
fi

if (( WARN > 0 )); then
  echo
  echo "RECOMMENDED IMPROVEMENTS"
  echo "-----------------------"
  [[ "$PORT" == "22" ]] && echo "- Move SSH off port 22"
  [[ "$ACCESS_RESTRICTED" == "NO" ]] && echo "- Restrict SSH by IP or VPN"
  ! grep -Eq "^(Ciphers|MACs|KexAlgorithms)" /etc/ssh/sshd_config && echo "- Add modern SSH crypto settings"
fi

echo
