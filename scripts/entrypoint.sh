#!/bin/bash
set -eo pipefail

echo "[IB-GATEWAY] Starting IB Gateway container..."

# 1. Resolve credentials from /run/ibkr-secrets or environment variables
SECRETS_DIR="/run/ibkr-secrets"
USERNAME="${IBKR_USERNAME:-}"
PASSWORD="${IBKR_PASSWORD:-}"

if [[ -z "$USERNAME" && -f "$SECRETS_DIR/username" ]]; then
    USERNAME=$(cat "$SECRETS_DIR/username" | tr -d '\r\n')
fi
if [[ -z "$PASSWORD" && -f "$SECRETS_DIR/password" ]]; then
    PASSWORD=$(cat "$SECRETS_DIR/password" | tr -d '\r\n')
fi
if [[ -z "$USERNAME" && -f "$SECRETS_DIR/credentials.json" ]]; then
    USERNAME=$(grep -o '"username": *"[^"]*"' "$SECRETS_DIR/credentials.json" | cut -d'"' -f4 || true)
    PASSWORD=$(grep -o '"password": *"[^"]*"' "$SECRETS_DIR/credentials.json" | cut -d'"' -f4 || true)
fi

if [[ -z "$USERNAME" || -z "$PASSWORD" ]]; then
    echo "[IB-GATEWAY] ERROR: IBKR credentials (username/password) not found in /run/ibkr-secrets or environment." >&2
    exit 1
fi

TRADING_MODE="${TRADING_MODE:-live}"
READ_ONLY_API="${READ_ONLY_API:-yes}"
API_PORT="${TWS_API_PORT:-4001}"
if [[ "$TRADING_MODE" == "paper" && -z "$TWS_API_PORT" ]]; then
    API_PORT=4002
fi

echo "[IB-GATEWAY] Configuration: trading_mode=${TRADING_MODE}, read_only=${READ_ONLY_API}, api_port=${API_PORT}"

# 2. Generate dynamic IBC config.ini
CONFIG_DIR="/home/gateway/ibc"
mkdir -p "$CONFIG_DIR"
CONFIG_FILE="$CONFIG_DIR/config.ini"

cat <<EOF > "$CONFIG_FILE"
# IBC Configuration for Goldmachine
IbLoginId=${USERNAME}
IbPassword=${PASSWORD}
TradingMode=${TRADING_MODE}
IbDir=/home/gateway/Jts
StoreSettingsOnServer=yes
MinimizeMainWindow=yes
ExistingSessionDetectedAction=primary
AcceptIncomingConnectionAction=accept
ShowAllTrades=yes
ReadOnlyApi=${READ_ONLY_API}
ClosedEndStatus=exit
AllowBlindTrading=no
OverrideTwsApiPort=${API_PORT}
EOF
chmod 600 "$CONFIG_FILE"

# 3. Start virtual X11 display (Xvfb)
echo "[IB-GATEWAY] Starting Xvfb on display ${DISPLAY:-:1}..."
Xvfb "${DISPLAY:-:1}" -screen 0 1024x768x16 -nolisten tcp &
XVFB_PID=$!

cleanup() {
    echo "[IB-GATEWAY] Shutting down..."
    kill -TERM "$XVFB_PID" 2>/dev/null || true
    rm -f "$CONFIG_FILE"
    exit 0
}
trap cleanup SIGTERM SIGINT

echo "[IB-GATEWAY] IBC environment ready. Starting IBC Controller..."
# Wipe in-memory password variables
USERNAME=""
PASSWORD=""

# Run IBC Gateway startup script
if [[ -f "/opt/ibc/gatewaystart.sh" ]]; then
    /opt/ibc/gatewaystart.sh -inline "$CONFIG_FILE" || true
else
    echo "[IB-GATEWAY] Waiting on background gateway process..."
    wait "$XVFB_PID"
fi
