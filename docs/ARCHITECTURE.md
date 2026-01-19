# 🏗️ Architecture

> System architecture and design decisions for Sentinel Protocol

---

## Overview

Sentinel Protocol is built on a **Hub-and-Spoke** architecture with two main components:

1. **On-Chain (Solidity)**: Smart contracts managing assets and order execution
2. **Off-Chain (Python)**: Keeper bots monitoring conditions and triggering executions

```
┌──────────────────────────────────────────────────────────────────┐
│                         USER INTERFACE                           │
│                    (Web App / SDK / Direct)                      │
└─────────────────────────────┬────────────────────────────────────┘
                              │
                              ▼
┌──────────────────────────────────────────────────────────────────┐
│                       SENTINEL VAULT                             │
│                   (Asset Custody & Orders)                       │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │  - deposit() / withdraw()                                  │  │
│  │  - createOrder() / cancelOrder()                           │  │
│  │  - executeOrder() (keeper only)                            │  │
│  └────────────────────────────────────────────────────────────┘  │
└─────────────────────────────┬────────────────────────────────────┘
                              │
            ┌─────────────────┼─────────────────┐
            ▼                 ▼                 ▼
┌───────────────────┐ ┌───────────────┐ ┌───────────────┐
│   OrderModule     │ │  RiskModule   │ │  AuthModule   │
│  Order lifecycle  │ │ Risk checks   │ │ Permissions   │
└───────────────────┘ └───────────────┘ └───────────────┘
                              │
            ┌─────────────────┴─────────────────┐
            ▼                                   ▼
┌───────────────────────────┐   ┌───────────────────────────┐
│      OracleAdapter        │   │       SwapAdapter         │
│   (Chainlink, Pyth...)    │   │   (Uniswap, Curve...)     │
└───────────────────────────┘   └───────────────────────────┘

                    ┌─────────────────┐
                    │     KEEPER      │  ◄── Off-Chain (Python)
                    │   (sentinel_    │      Monitors conditions
                    │    keeper)      │      Triggers executions
                    └─────────────────┘
```

---

## Design Principles

### 1. Non-Custodial

- Users maintain full control of their assets
- Assets stored in user-specific vaults (mapping)
- Protocol cannot move funds without user-signed orders

### 2. Separation of Concerns

| Layer    | Responsibility            | Location        |
| -------- | ------------------------- | --------------- |
| Vault    | Asset custody, order CRUD | `SentinelVault` |
| Modules  | Business logic            | `modules/`      |
| Adapters | External integrations     | `adapters/`     |
| Keeper   | Condition monitoring      | `keeper/`       |

### 3. Upgrade Path

- Modules and Adapters are swappable via admin functions
- Core vault logic is immutable after deployment
- Emergency pause mechanism for critical issues

---

## On-Chain Components

### SentinelVault (Hub)

The central contract that:

- Holds user balances (`mapping(address => mapping(address => uint256))`)
- Manages order lifecycle (create → execute/cancel)
- Delegates execution logic to modules/adapters

```solidity
contract SentinelVault {
    mapping(address user => mapping(address token => uint256 balance)) public balances;
    mapping(uint256 orderId => Order) public orders;
    mapping(address => bool) public keepers;

    function deposit(address token, uint256 amount) external;
    function createOrder(Order calldata order) external returns (uint256);
    function executeOrder(uint256 orderId) external; // keeper only
}
```

### Modules (Spoke)

Internal logic components:

| Module            | Purpose                               |
| ----------------- | ------------------------------------- |
| `OrderModule`     | Order validation, state management    |
| `ExecutionModule` | Swap execution, slippage protection   |
| `RiskModule`      | Position limits, exposure checks      |
| `AuthModule`      | Role management, keeper authorization |

### Adapters (Spoke)

External protocol integrations:

| Adapter         | Purpose                                     |
| --------------- | ------------------------------------------- |
| `OracleAdapter` | Price feeds (Chainlink, Pyth, Redstone)     |
| `SwapAdapter`   | DEX integration (Uniswap, SushiSwap, Curve) |

### Interfaces

Public API definitions:

| Interface        | Purpose                                   |
| ---------------- | ----------------------------------------- |
| `ISentinelVault` | Main vault interface for external callers |

---

## Off-Chain Components

### Keeper Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                      KEEPER SERVICE                             │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                    app.py (entrypoint)                    │  │
│  └───────────────────────────┬───────────────────────────────┘  │
│                              │                                  │
│  ┌───────────────────────────▼───────────────────────────────┐  │
│  │                       CHAIN LAYER                         │  │
│  │  ┌──────────┐   ┌────────────┐   ┌───────────────────┐   │  │
│  │  │ client   │   │  events    │   │        tx         │   │  │
│  │  │ (Web3)   │   │ (Indexer)  │   │ (TxManager)       │   │  │
│  │  └──────────┘   └────────────┘   └───────────────────┘   │  │
│  └───────────────────────────┬───────────────────────────────┘  │
│                              │                                  │
│  ┌───────────────────────────▼───────────────────────────────┐  │
│  │                    STRATEGY LAYER                         │  │
│  │  ┌──────────────┐   ┌──────────────┐   ┌──────────────┐  │  │
│  │  │  StopLoss    │   │  TakeProfit  │   │    TWAP      │  │  │
│  │  │  Strategy    │   │  Strategy    │   │  Strategy    │  │  │
│  │  └──────────────┘   └──────────────┘   └──────────────┘  │  │
│  └───────────────────────────┬───────────────────────────────┘  │
│                              │                                  │
│  ┌───────────────────────────▼───────────────────────────────┐  │
│  │                   EXECUTOR LAYER                          │  │
│  │  ┌──────────────────────┐   ┌───────────────────────┐    │  │
│  │  │   order_executor     │   │       retry           │    │  │
│  │  │   (submit txs)       │   │   (backoff logic)     │    │  │
│  │  └──────────────────────┘   └───────────────────────┘    │  │
│  └───────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

### Keeper Flow

1. **Poll**: EventIndexer listens for `OrderCreated` events
2. **Evaluate**: Strategy evaluates trigger conditions (price, time)
3. **Execute**: If conditions met, OrderExecutor submits `executeOrder()` tx
4. **Retry**: Failed txs are retried with exponential backoff

---

## Data Flow

### Order Creation

```
User                 SentinelVault            OrderModule
  │                        │                       │
  │  createOrder(order)    │                       │
  │───────────────────────>│                       │
  │                        │  _validateOrder()     │
  │                        │──────────────────────>│
  │                        │       ok              │
  │                        │<──────────────────────│
  │                        │                       │
  │                        │  emit OrderCreated    │
  │   orderId              │                       │
  │<───────────────────────│                       │
```

### Order Execution

```
Keeper              SentinelVault       OracleAdapter      SwapAdapter
  │                       │                  │                  │
  │  executeOrder(id)     │                  │                  │
  │──────────────────────>│                  │                  │
  │                       │  getPrice()      │                  │
  │                       │─────────────────>│                  │
  │                       │    price         │                  │
  │                       │<─────────────────│                  │
  │                       │                  │                  │
  │                       │  [check trigger] │                  │
  │                       │                  │                  │
  │                       │          swap()  │                  │
  │                       │─────────────────────────────────────>
  │                       │                  │    amountOut     │
  │                       │<─────────────────────────────────────
  │                       │                  │                  │
  │                       │  emit OrderExecuted                 │
  │      success          │                  │                  │
  │<──────────────────────│                  │                  │
```

---

## Security Model

### Trust Assumptions

| Entity | Trust Level | Justification                            |
| ------ | ----------- | ---------------------------------------- |
| User   | High        | Controls their own funds                 |
| Keeper | Medium      | Can only execute valid orders            |
| Admin  | Medium      | Can pause, add adapters (not move funds) |
| Oracle | External    | Trusted for price data                   |
| DEX    | External    | Trusted for swap execution               |

### Security Measures

1. **Reentrancy Guard**: All state changes before external calls
2. **Access Control**: Keeper whitelist, owner-only admin functions
3. **Validation**: Order parameters validated on creation
4. **Slippage Protection**: `minOutputAmount` enforced on swaps
5. **Deadline Enforcement**: Orders expire after deadline
6. **Emergency Pause**: Admin can pause all operations

---

## Gas Optimization

### Storage Patterns

- Packed structs (slippage as `uint16`, state as `uint8`)
- Mapping over arrays for O(1) lookups
- Event emission for off-chain indexing vs on-chain storage

### Execution Efficiency

- Batch execution support (`executeBatch`)
- Minimal storage reads in hot paths
- Custom errors over require strings

---

## Future Considerations

### Multi-Chain

- Deploy on Arbitrum, Base, Polygon
- Cross-chain message passing (LayerZero, Wormhole)

### Advanced Strategies

- TWAP: Time-weighted average price execution
- Grid Trading: Range-based order ladders
- DCA: Dollar-cost averaging schedules

### MEV Protection

- Flashbots integration for private mempools
- Time-delayed execution windows
