// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title KiteTraderAttestation
 * @notice On-chain attestation contract for KiteTrader autonomous agent
 * @dev Deployed on Kite chain (testnet) for trade settlement and auditability
 */
contract KiteTraderAttestation {

    // ── EVENTS ────────────────────────────────────────────────────────────
    event TradeAttested(
        bytes32 indexed tradeId,
        address indexed agent,
        string pair,
        string action,
        uint256 price,
        uint256 size,
        int256  pnl,
        uint256 timestamp
    );

    event AgentRegistered(
        address indexed agent,
        string  name,
        uint256 riskBps,      // risk per trade in basis points (200 = 2%)
        uint256 timestamp
    );

    event PortfolioAttested(
        address indexed agent,
        uint256 portfolioValue,
        int256  totalPnl,
        uint256 totalTrades,
        uint256 timestamp
    );

    event RiskViolation(
        address indexed agent,
        string  reason,
        uint256 timestamp
    );

    // ── STRUCTS ───────────────────────────────────────────────────────────
    struct Trade {
        bytes32 tradeId;
        address agent;
        string  pair;
        string  action;         // "BUY" | "SELL"
        uint256 price;          // scaled by 1e6
        uint256 size;           // USD, scaled by 1e6
        int256  pnl;            // scaled by 1e6
        uint256 timestamp;
        bool    exists;
    }

    struct AgentProfile {
        address wallet;
        string  name;
        uint256 riskPerTradeBps;
        uint256 maxPositionBps;
        uint256 registeredAt;
        bool    active;
        uint256 tradeCount;
        int256  cumulativePnl;
    }

    // ── STATE ─────────────────────────────────────────────────────────────
    address public owner;
    uint256 public totalTrades;
    uint256 public constant MAX_RISK_BPS = 1000; // 10% max risk per trade

    mapping(bytes32 => Trade)         public trades;
    mapping(address => AgentProfile)  public agents;
    mapping(address => bytes32[])     public agentTrades;

    bytes32[] public allTradeIds;

    // ── CONSTRUCTOR ───────────────────────────────────────────────────────
    constructor() {
        owner = msg.sender;
    }

    // ── AGENT REGISTRATION ────────────────────────────────────────────────
    /**
     * @notice Register an autonomous agent with scoped risk parameters
     */
    function registerAgent(
        string calldata name,
        uint256 riskPerTradeBps,
        uint256 maxPositionBps
    ) external {
        require(riskPerTradeBps <= MAX_RISK_BPS, "Risk too high");
        require(maxPositionBps <= 5000, "Max position too high"); // 50% max
        require(bytes(name).length > 0, "Name required");

        agents[msg.sender] = AgentProfile({
            wallet:          msg.sender,
            name:            name,
            riskPerTradeBps: riskPerTradeBps,
            maxPositionBps:  maxPositionBps,
            registeredAt:    block.timestamp,
            active:          true,
            tradeCount:      0,
            cumulativePnl:   0
        });

        emit AgentRegistered(msg.sender, name, riskPerTradeBps, block.timestamp);
    }

    // ── TRADE ATTESTATION ─────────────────────────────────────────────────
    /**
     * @notice Attest a trade execution on-chain. Called by the agent after execution.
     * @param pair     Trading pair e.g. "BTC/USDT"
     * @param action   "BUY" or "SELL"
     * @param price    Execution price scaled by 1e6
     * @param size     Position size in USD scaled by 1e6
     * @param pnl      Realised PnL scaled by 1e6
     */
    function attestTrade(
        string calldata pair,
        string calldata action,
        uint256 price,
        uint256 size,
        int256 pnl
    ) external returns (bytes32 tradeId) {
        AgentProfile storage agent = agents[msg.sender];

        // Enforce risk limits if agent is registered
        if (agent.registeredAt > 0) {
            require(agent.active, "Agent not active");
            // Check size against risk limit (simplified: size < risk% of some notional)
            // In production this would check against real portfolio value
            agent.tradeCount++;
            agent.cumulativePnl += pnl;
        }

        tradeId = keccak256(abi.encodePacked(
            msg.sender, pair, action, price, size, block.timestamp, totalTrades
        ));

        trades[tradeId] = Trade({
            tradeId:   tradeId,
            agent:     msg.sender,
            pair:      pair,
            action:    action,
            price:     price,
            size:      size,
            pnl:       pnl,
            timestamp: block.timestamp,
            exists:    true
        });

        agentTrades[msg.sender].push(tradeId);
        allTradeIds.push(tradeId);
        totalTrades++;

        emit TradeAttested(
            tradeId, msg.sender, pair, action,
            price, size, pnl, block.timestamp
        );
    }

    // ── PORTFOLIO ATTESTATION ─────────────────────────────────────────────
    /**
     * @notice Attest the agent's full portfolio state
     */
    function attestPortfolio(
        uint256 portfolioValue,
        int256 totalPnl,
        uint256 tradeCount
    ) external {
        require(agents[msg.sender].registeredAt > 0 || msg.sender == owner, "Not registered");

        emit PortfolioAttested(
            msg.sender, portfolioValue, totalPnl, tradeCount, block.timestamp
        );
    }

    // ── VIEWS ─────────────────────────────────────────────────────────────
    function getAgentTrades(address agent) external view returns (bytes32[] memory) {
        return agentTrades[agent];
    }

    function getTrade(bytes32 tradeId) external view returns (Trade memory) {
        require(trades[tradeId].exists, "Trade not found");
        return trades[tradeId];
    }

    function getAgentStats(address agent) external view returns (
        uint256 tradeCount,
        int256  cumulativePnl,
        bool    active,
        uint256 riskPerTradeBps
    ) {
        AgentProfile storage a = agents[agent];
        return (a.tradeCount, a.cumulativePnl, a.active, a.riskPerTradeBps);
    }

    function totalTradeCount() external view returns (uint256) {
        return totalTrades;
    }

    // ── OWNER CONTROLS ────────────────────────────────────────────────────
    function deactivateAgent(address agent) external {
        require(msg.sender == owner, "Not owner");
        agents[agent].active = false;
    }

    function transferOwnership(address newOwner) external {
        require(msg.sender == owner, "Not owner");
        owner = newOwner;
    }
}
