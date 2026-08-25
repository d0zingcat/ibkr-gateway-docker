# syntax=docker/dockerfile:1
FROM ghcr.io/gnzsnz/ib-gateway:latest

# Defaults for Goldmachine deployment
ENV READ_ONLY_API=yes \
    TWS_API_PORT=4001 \
    TRADING_MODE=live \
    TWOFA_TIMEOUT_ACTION=restart \
    RELOGIN_AFTER_TWOFA_TIMEOUT=yes \
    EXISTING_SESSION_DETECTED_ACTION=primary
