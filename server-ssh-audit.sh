#!/usr/bin/env bash

# Accurate, read-only SSH security report
# Includes concise proof for key decisions

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
  FIREWALL_PRESENT="YES"
  result "Firewall Detected" "YES" WARN
else
  FIREWALL_PRESENT="NO"
  result "Firewall Detected" "NO" WARN
fi

# ---- Exposure analysis (derived) ----
PUBLIC_LISTEN="NO"
LISTEN_ADDR="$(ss -ltnp 2>/dev/null | grep sshd | grep ":$PORT" | awk '{print $4}' | head -n1)"

if echo "$LISTEN_ADDR" | grep -qE "0.0.0.0|::"; then
  PUBLIC_LISTEN="YES"
fi

ACCESS_RESTRICTED="NO"
grep -Eq "^(AllowUsers|AllowGroups)" /etc/ssh/sshd_config 2>/dev/null && ACCESS_RESTRICTED="YES"

if [[ "$PUBLIC_LISTEN" == "YES" && "$ACCESS_RESTRICTED" == "NO" ]]; then
  EXPOSURE="PUBLIC & UNRESTRICTED"
  result "SSH Exposure Level" "$EXPOSURE" WARN
elif [[ "$PUBLIC_LISTEN" == "YES" && "$ACCESS_RESTRICTED" == "YES" ]]; then
  EXPOSURE="PUBLIC (RESTRICTED)"
  result "SSH Exposure Level" "$EXPOSURE" WARN
else
  EXPOSURE="NOT PUBLIC"
  result "SSH Exposure Level" "$EXPOSURE" PASS
fi

# ---- Crypto hygiene ----
if grep -Eq "^(Ciphers|MACs|KexAlgorithms)" /etc/ssh/sshd_config 2>/dev/null; then
  CRYPTO="SET"
  result "Crypto Hardening" "SET" PASS
else
  CRYPTO="NOT SET"
  result "Crypto Hardening" "NOT SET" WARN
fi

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
  [[ "$ACCESS_RESTRICTED" == "NO" ]] && echo "- Restrict SSH by IP or VPN"
  [[ "$CRYPTO" == "NOT SET" ]] && echo "- Add modern SSH crypto settings"
fi

# ---- Proofs ----
echo
echo "EVIDENCE (PROOFS)"
echo "-----------------"

echo "- SSH listens on: ${LISTEN_ADDR:-unknown}"
echo "- PermitRootLogin: $ROOT"
[[ "$FIREWALL_PRESENT" == "YES" ]] && echo "- Firewall status: ufw active" || echo "- Firewall status: not detected"
[[ "$CRYPTO" == "NOT SET" ]] && echo "- No Ciphers/MACs/KexAlgorithms in sshd_config"

echo
