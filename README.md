# IBKR Gateway Docker

Apache-2.0 licensed, read-only Docker container for Interactive Brokers (IBKR) Gateway and IBC controller.

Provides a lightweight, headless environment with virtual X11 display (Xvfb) to run IB Gateway continuously on private Docker networks.

---

## 🌟 Why IB Gateway + IBC?

* **Real-time Streaming**: Connect via native binary socket protocol (TWS API) on port `4001` (Live) or `4002` (Paper) for millisecond-level account and portfolio updates.
* **Weekly 2FA Only**: Requires mobile push approval on IBKR Mobile only **once per week** (on Monday or initial startup). IBC maintains the connection all week long without daily logins.
* **Strict Read-Only Enforcement**: Defaults to `READ_ONLY_API=yes` to physically disable all order placement / cancellation commands at the gateway level.
* **Non-root Security**: Runs under unprivileged user (`UID 10001`).

---

## 🚀 Quick Start

### 1. Environment Configuration

| Variable | Description | Default |
| :--- | :--- | :--- |
| `IBKR_USERNAME` | IBKR Account Username | *(Required)* |
| `IBKR_PASSWORD` | IBKR Account Password | *(Required)* |
| `TRADING_MODE` | `live` or `paper` | `live` |
| `TWS_API_PORT` | TWS Socket API Port | `4001` (Live) / `4002` (Paper) |
| `READ_ONLY_API` | Disable trading orders (`yes`/`no`) | `yes` |

Credentials can also be loaded securely from files in `/run/ibkr-secrets` (`username`, `password`, or `credentials.json`).

### 2. Local Run

```bash
docker compose -f docker-compose.example.yml up -d
```

### 3. Connect with Python (`ib_async`)

```python
from ib_async import IB

ib = IB()
await ib.connectAsync('127.0.0.1', 4001, clientId=1, readonly=True)

# Fetch accounts and live portfolio
print("Accounts:", ib.managedAccounts())
portfolio = await ib.portfolioAsync()
for item in portfolio:
    print(item.contract.symbol, item.position, item.marketPrice, item.marketValue)
```
