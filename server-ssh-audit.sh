#!/usr/bin/env bash

# Accurate, read-only SSH security report
# Includes concise proof for ALL decisions with PASS/WARN/FAIL prefixes

PASS=0
WARN=0
FAIL=0

# Store proof lines in order
declare -a PROOFS

result() {
  local label="$1"
  local value="$2"
  local status="$3"
  local proof="$4"

  printf "%-30s : %-22s %s\n" "$label" "$value" "$status"

  case "$status" in
    PASS) ((PASS++)) ;;
    WARN) ((WARN++)) ;;
    FAIL) ((FAIL++)) ;;
  esac

  PROOFS+=("[$status] $proof")
}

get_cfg() {
  grep -Ei "^\s*$1\s+" /etc/ssh/sshd_config 2>/dev/null | tail -n1 | awk '{print $2}'
}

echo
echo "SSH SECURITY CHECK"
echo "=================="

# ---- Read SSH config ----
PORT="$(get_cfg Port)"
ROOT="$(get_cfg PermitRootLogin)"
PASSAUTH="$(get_cfg PasswordAuthentication)"
PUBKEY="$(get_cfg PubkeyAuthentication)"

PORT="${PORT:-22}"
ROOT="${ROOT:-default}"
PASSAUTH="${PASSAUTH:-default}"
PUBKEY="${PUBKEY:-default}"

# ---- SSH Port ----
if [[ "$PORT" != "22" ]]; then
  result "SSH Port" "$PORT" PASS "Port $PORT configured (non-default)"
else
  result "SSH Port" "$PORT" WARN "Default SSH port 22 in use"
fi

# ---- Root Login ----
if [[ "$ROOT" == "no" ]]; then
  result "Root Login" "DISABLED" PASS "PermitRootLogin set to no"
else
  result "Root Login" "ENABLED" FAIL "PermitRootLogin is $ROOT"
fi

# ---- Password Authentication ----
if [[ "$PASSAUTH" == "no" ]]; then
  result "Password Authentication" "DISABLED" PASS "PasswordAuthentication no"
else
  result "Password Authentication" "ENABLED" FAIL "PasswordAuthentication is $PASSAUTH"
fi

# ---- Public Key Authentication ----
if [[ "$PUBKEY" == "yes" ]]; then
  result "Public Key Auth" "ENABLED" PASS "PubkeyAuthentication yes"
else
  result "Public Key Auth" "NOT ENFORCED" WARN "PubkeyAuthentication not explicitly enabled"
fi

# ---- Fail2Ban ----
if systemctl is-active --quiet fail2ban 2>/dev/null; then
  result "Fail2Ban" "ACTIVE" PASS "fail2ban service is running"
else
  result "Fail2Ban" "INACTIVE" FAIL "fail2ban service not active"
fi

# ---- Firewall presence (informational) ----
if command -v ufw >/dev/null && ufw status | grep -q "Status: active"; then
  FIREWALL_PRESENT="YES"
  result "Firewall Detected" "YES" WARN "ufw is active (rules not evaluated)"
else
  FIREWALL_PRESENT="NO"
  result "Firewall Detected" "NO" WARN "no active ufw firewall detected"
fi

# ---- SSH exposure analysis ----
LISTEN_ADDR="$(ss -ltnp 2>/dev/null | grep sshd | grep ":$PORT" | awk '{print $4}' | head -n1)"

PUBLIC_LISTEN="NO"
echo "$LISTEN_ADDR" | grep -qE "0.0.0.0|::" && PUBLIC_LISTEN="YES"

ACCESS_RESTRICTED="NO"
grep -Eq "^(AllowUsers|AllowGroups)" /etc/ssh/sshd_config 2>/dev/null && ACCESS_RESTRICTED="YES"

if [[ "$PUBLIC_LISTEN" == "YES" && "$ACCESS_RESTRICTED" == "NO" ]]; then
  result "SSH Exposure Level" "PUBLIC & UNRESTRICTED" WARN \
    "sshd listens on $LISTEN_ADDR with no AllowUsers/AllowGroups"
elif [[ "$PUBLIC_LISTEN" == "YES" && "$ACCESS_RESTRICTED" == "YES" ]]; then
  result "SSH Exposure Level" "PUBLIC (RESTRICTED)" WARN \
    "sshd listens on $LISTEN_ADDR with user/group restrictions"
else
  result "SSH Exposure Level" "NOT PUBLIC" PASS \
    "sshd not listening on public interfaces"
fi

# ---- Crypto Hardening ----
if grep -Eq "^(Ciphers|MACs|KexAlgorithms)" /etc/ssh/sshd_config 2>/dev/null; then
  result "Crypto Hardening" "SET" PASS \
    "Ciphers/MACs/KexAlgorithms defined in sshd_config"
else
  result "Crypto Hardening" "NOT SET" WARN \
    "No explicit Ciphers/MACs/KexAlgorithms configured"
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
  ! grep -Eq "^(Ciphers|MACs|KexAlgorithms)" /etc/ssh/sshd_config && \
    echo "- Add modern SSH crypto settings"
fi

# ---- Evidence ----
echo
echo "EVIDENCE (PROOFS)"
echo "-----------------"
for proof in "${PROOFS[@]}"; do
  echo "- $proof"
done

echo
