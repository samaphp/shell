#!/usr/bin/env bash
# bash ssh-port.sh 23
# where 23 are the new SSH port
# this script are not tested on edge cases, please make sure you do not run this unless you know what to do
# CAUTION this script might lock your server
set -euo pipefail

# ---------------------------------------------
# 1. Validate input
# ---------------------------------------------
if [[ $# -ne 1 ]]; then
    echo "Usage: sudo $0 <new-ssh-port>"
    exit 1
fi

NEW_PORT="$1"

# Validate port number
if ! [[ "$NEW_PORT" =~ ^[0-9]+$ ]] || (( NEW_PORT < 1 || NEW_PORT > 65535 )); then
    echo "❌ Invalid port: $NEW_PORT"
    exit 1
fi

# ---------------------------------------------
# 2. Detect socket activation
# ---------------------------------------------
SOCKET_ACTIVE="no"
if systemctl is-enabled ssh.socket &>/dev/null; then
    SOCKET_ACTIVE="yes"
elif systemctl is-active ssh.socket &>/dev/null; then
    SOCKET_ACTIVE="yes"
fi

echo "✔ Socket Activation: $SOCKET_ACTIVE"

# Backup socket config
SOCKET_OVERRIDE_DIR="/etc/systemd/system/ssh.socket.d"
SOCKET_OVERRIDE_FILE="$SOCKET_OVERRIDE_DIR/override.conf"

if [[ "$SOCKET_ACTIVE" == "yes" ]]; then
    mkdir -p "$SOCKET_OVERRIDE_DIR"

    # Backup old override if exists
    if [[ -f "$SOCKET_OVERRIDE_FILE" ]]; then
        cp "$SOCKET_OVERRIDE_FILE" "${SOCKET_OVERRIDE_FILE}.bak.$(date +%s)"
    fi

    # ---------------------------------------------
    # 3. Create a SAFE override for ssh.socket
    # ---------------------------------------------
    echo "✔ Using systemd socket activation — applying override"
    echo "[Socket]
ListenStream=
ListenStream=22
ListenStream=0.0.0.0:22
ListenStream=${NEW_PORT}
ListenStream=0.0.0.0:${NEW_PORT}
" > "$SOCKET_OVERRIDE_FILE"

    echo "✔ Socket override created at $SOCKET_OVERRIDE_FILE"

    # Reload + restart socket
    echo "✔ Reloading systemd..."
    systemctl daemon-reload

    echo "✔ Restarting ssh.socket..."
    if ! systemctl restart ssh.socket; then
        echo "❌ Failed to restart ssh.socket — restoring backup."
        [[ -f "${SOCKET_OVERRIDE_FILE}.bak" ]] && cp "${SOCKET_OVERRIDE_FILE}.bak" "$SOCKET_OVERRIDE_FILE"
        systemctl daemon-reload
        systemctl restart ssh.socket || true
        exit 1
    fi

    echo "✔ Restarting ssh service..."
    systemctl restart ssh || true
fi

# ---------------------------------------------
# 4. Verify that sshd is listening on the new port
# ---------------------------------------------
echo "✔ Checking listeners..."
if ss -tulpn | grep -q ":${NEW_PORT} "; then
    echo "🎉 SUCCESS: SSH is now listening on port $NEW_PORT"
else
    echo "❌ ERROR: sshd is NOT listening on port $NEW_PORT"
    echo "Check: ss -tulpn | grep sshd"
    exit 1
fi

exit 0
