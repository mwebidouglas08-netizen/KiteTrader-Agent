# 🪁 KiteTrader — Autonomous AI Trading Agent

> **Kite AI Hackathon Submission · Agentic Trading Track**
> 
> An autonomous AI agent that analyses crypto markets, executes trades, and settles every action on **Kite chain** for full auditability and trustless verification.

[![Deploy with Vercel](https://vercel.com/button)](https://vercel.com/new/clone?repository-url=https://github.com/yourusername/kitetrader)

---

## 🎯 What It Does

**KiteTrader** is a fully autonomous trading agent that:

1. **Analyses markets** — Multi-indicator AI engine (RSI, MACD, Bollinger Bands, sentiment, order-book analysis) scans 8 trading pairs continuously
2. **Executes trades** — When signal confidence > 78%, the agent executes trades autonomously with configurable risk limits
3. **Settles on Kite chain** — Every trade, signal, and portfolio state change is attested on-chain via the `KiteTraderAttestation` smart contract
4. **Manages risk** — Scoped keys, per-trade risk limits (configurable 0.5%–5%), and automatic drawdown protection

---

## ✅ Hackathon Requirements Checklist

| Requirement | Status |
|-------------|--------|
| AI agent performs real tasks | ✅ Market analysis + trade execution |
| Settles on Kite chain | ✅ Every trade attested via smart contract |
| Executes paid actions (API calls, services) | ✅ Trades + on-chain settlements |
| Works end-to-end in production | ✅ Deploy to Vercel (frontend) + Railway/Render (API) |
| Uses Kite chain for attestations | ✅ `KiteTraderAttestation.sol` deployed on Kite testnet |
| Functional UI (web app) | ✅ Full real-time dashboard |
| Agent Autonomy — minimal human involvement | ✅ Fully autonomous, humans only configure |
| Multi-agent coordination (bonus) | ✅ Multi-agent toggle in UI |
| Scoped permissions & revocation (bonus) | ✅ `registerAgent()` with risk limits, `deactivateAgent()` |

---

## 🏗 Architecture

```
┌─────────────────────────────────────────────────────┐
│                   User Browser                       │
│         Real-time Dashboard (HTML/JS/WS)            │
└──────────────────┬──────────────────────────────────┘
                   │ WebSocket + REST
┌──────────────────▼──────────────────────────────────┐
│              KiteTrader API (Node.js)                │
│                                                      │
│  ┌────────────┐  ┌─────────────┐  ┌──────────────┐ │
│  │  AI Signal │  │   Trade     │  │  Kite Chain  │ │
│  │   Engine   │→ │  Executor   │→ │  Settler     │ │
│  │ (RSI/MACD/ │  │ (risk mgmt) │  │ (ethers.js)  │ │
│  │  Sentiment)│  └─────────────┘  └──────┬───────┘ │
│  └────────────┘                          │          │
└──────────────────────────────────────────┼──────────┘
                                           │ eth_sendTransaction
┌──────────────────────────────────────────▼──────────┐
│                   Kite Chain (EVM)                   │
│         KiteTraderAttestation.sol                    │
│  • attestTrade()  • registerAgent()                  │
│  • attestPortfolio()  • deactivateAgent()            │
└─────────────────────────────────────────────────────┘
```

---

## 🚀 Quick Start

### Prerequisites
- Node.js 18+
- A Kite testnet wallet (get from [kiteai.io](https://kiteai.io))

### 1. Clone & install
```bash
git clone https://github.com/yourusername/kitetrader
cd kitetrader/backend
npm install
```

### 2. Configure environment
```bash
cp .env.example .env
# Edit .env:
KITE_RPC_URL=https://rpc-testnet.kiteai.io
AGENT_PRIVATE_KEY=your_private_key_here
ATTESTATION_CONTRACT=0x_deployed_contract_address
PORT=3001
```

### 3. Deploy the smart contract (Kite testnet)
```bash
# Using Remix IDE or Hardhat
# Copy contracts/KiteTraderAttestation.sol
# Deploy to Kite testnet RPC: https://rpc-testnet.kiteai.io
# Chain ID: 2368
# Save the deployed address → ATTESTATION_CONTRACT in .env
```

### 4. Start the backend
```bash
npm start
# → API running on http://localhost:3001
# → WebSocket ready
```

### 5. Open the frontend
```bash
# Option A: Open directly
open frontend/index.html

# Option B: Serve via backend (static files)
# Frontend is served at http://localhost:3001
```

---

## 🌐 Production Deployment (Vercel + Railway)

### Frontend → Vercel
```bash
cd kitetrader
vercel deploy
# Frontend auto-deployed, configure API_URL env var
```

### Backend → Railway / Render
```bash
# Push to GitHub, connect to Railway
# Set environment variables in Railway dashboard
railway up
```

---

## 📡 API Reference

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/health` | GET | Agent status + Kite chain connection |
| `/api/state` | GET | Full agent state (PnL, trades, portfolio) |
| `/api/markets` | GET | Live market prices |
| `/api/signals` | GET | Recent AI signals (last 50) |
| `/api/signal` | POST | Trigger manual signal `{ pair, signal }` |
| `/api/agent/toggle` | POST | Pause/resume agent |
| `/api/agent/risk` | POST | Update risk `{ riskPerTrade: 0.02 }` |
| `/api/kite/txns` | GET | Kite chain transactions |
| `/api/kite/attest` | POST | Manually attest portfolio state |
| `/api/analytics` | GET | Full analytics dashboard data |

### WebSocket Events
```javascript
const socket = io('http://localhost:3001');
socket.on('signal:new',      (signal) => {});   // new AI signal
socket.on('trade:executed',  (trade)  => {});   // trade completed
socket.on('kite:tx',         (tx)     => {});   // Kite chain settlement
socket.on('markets:update',  (prices) => {});   // price tick
socket.on('agent:state',     (state)  => {});   // agent metrics
```

---

## 🧠 AI Signal Engine

The agent analyses each market using:

| Indicator | Weight | Signal |
|-----------|--------|--------|
| RSI (14) | 25% | < 35 = bullish, > 70 = bearish |
| MACD (12/26/9) | 25% | Cross direction |
| AI Sentiment | 20% | NLP score 0–1 |
| Volume Ratio | 15% | > 2x = confirmation |
| Order Book Imbalance | 15% | Bid/ask ratio |

Signals are only executed when confidence > 78% to minimise false positives.

---

## ⛓ Kite Chain Integration

### Smart Contract: `KiteTraderAttestation.sol`
- **`registerAgent(name, riskBps, maxPositionBps)`** — Register agent with scoped risk limits
- **`attestTrade(pair, action, price, size, pnl)`** — Settle every trade on-chain
- **`attestPortfolio(portfolioValue, totalPnl, tradeCount)`** — Periodic portfolio proof
- **`getAgentStats(address)`** — View agent performance history
- **`deactivateAgent(address)`** — Revoke agent permissions (owner only)

Every trade generates a `TradeAttested` event viewable on Kite chain explorer.

---

## 🏆 Judging Criteria Addressed

### Agent Autonomy
- Analyses 3 markets every 3 seconds with no human input
- Auto-executes on high-confidence signals (>78%)
- Scoped private key with configurable risk per trade
- `deactivateAgent()` for instant revocation

### Developer Experience
- Single command start: `npm start`
- WebSocket + REST API both documented
- Real-time dashboard works out of the box
- Demo mode works without a real Kite wallet

### Real-World Applicability
- Production-deployed to Vercel/Railway
- Handles live market simulation (pluggable to real CEX APIs)
- Risk management prevents catastrophic losses
- Full audit trail on Kite chain

### Novel / Creativity
- Multi-agent coordination toggle (multiple agents, one settlement contract)
- Gas abstraction: agent pays its own fees from trading profits
- Portfolio attestation for trustless performance verification
- Clean REST + WebSocket API for other agents to consume signals

---

## 📁 Project Structure

```
kitetrader/
├── frontend/
│   └── index.html          # Full-featured trading dashboard
├── backend/
│   ├── server.mjs          # Express + Socket.io + Kite integration
│   └── package.json
├── contracts/
│   └── KiteTraderAttestation.sol  # On-chain settlement contract
├── vercel.json             # Deployment config
└── README.md
```

---

## 👥 Team / Contact
- Built for **Kite AI Hackathon** — Agentic Trading Track
- Encode Club × Kite AI

---

*"The first AI agent that doesn't just trade — it proves it."*
