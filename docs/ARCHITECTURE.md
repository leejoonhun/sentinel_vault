# 🏗️ Architecture

> System architecture and design decisions for Sentinel Protocol

---

## Overview

Sentinel Protocol is built on a **"One Brain, Many Hands"** architecture designed for multi-chain support:

1. **On-Chain Contracts**: Chain-specific smart contracts/programs
   - **EVM (Ethereum, Arbitrum, Base)**: Solidity contracts via Foundry
   - **SVM (Solana)**: Rust programs via Anchor
2. **Off-Chain Keeper (Python)**: Unified keeper bot that controls all chains through abstraction

```
┌──────────────────────────────────────────────────────────────────┐
│                         USER INTERFACE                           │
│                    (Web App / SDK / Direct)                      │
└─────────────────────────────┬────────────────────────────────────┘
                              │
              ┌───────────────┴───────────────┐
              ▼                               ▼
┌─────────────────────────┐     ┌─────────────────────────┐
│   contracts-evm/        │     │   contracts-svm/        │
│   (Solidity/Foundry)    │     │   (Rust/Anchor)         │
│                         │     │                         │
│  ┌───────────────────┐  │     │  ┌───────────────────┐  │
│  │  SentinelVault    │  │     │  │  sentinel_vault   │  │
│  │  - deposit()      │  │     │  │  - initialize()   │  │
│  │  - createOrder()  │  │     │  │  - create_order() │  │
│  │  - executeOrder() │  │     │  │  - execute_order()│  │
│  └───────────────────┘  │     │  └───────────────────┘  │
│                         │     │                         │
│  Ethereum, Arbitrum,    │     │  Solana mainnet,        │
│  Base, Optimism...      │     │  devnet                 │
└────────────┬────────────┘     └────────────┬────────────┘
             │                               │
             └───────────────┬───────────────┘
                             │
                             ▼
┌──────────────────────────────────────────────────────────────────┐
│                     KEEPER SERVICE (Python)                      │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │              ChainClient (Abstract Base Class)             │  │
│  │   get_price() | get_active_orders() | execute_order()      │  │
│  └─────────────────────────┬──────────────────────────────────┘  │
│                            │                                     │
│            ┌───────────────┴───────────────┐                    │
│            ▼                               ▼                    │
│   ┌─────────────────┐            ┌─────────────────┐            │
│   │   EVMClient     │            │  SolanaClient   │            │
│   │   (web3.py)     │            │  (solana-py)    │            │
│   └─────────────────┘            └─────────────────┘            │
│                                                                  │
│   Strategy → Executor → One interface, multiple chains           │
└──────────────────────────────────────────────────────────────────┘
```

---

## Repository Structure

```
sentinel-vault/
├── contracts-evm/           # EVM contracts (Ethereum, Arbitrum, Base)
│   ├── src/                 #   Solidity source files
│   │   ├── SentinelVault.sol
│   │   ├── modules/
│   │   └── adapters/
│   ├── test/                #   Forge tests
│   └── foundry.toml
│
├── contracts-svm/           # SVM contracts (Solana)
│   ├── programs/            #   Anchor programs
│   │   └── sentinel_vault/
│   │       └── src/lib.rs   #   Rust program code
│   ├── tests/               #   Anchor tests
│   └── Anchor.toml
│
├── keeper/                  # Unified Python keeper
│   └── sentinel_keeper/
│       ├── chain/           #   Chain abstraction layer
│       │   ├── base.py      #     ChainClient ABC
│       │   ├── evm.py       #     EVM implementation
│       │   └── svm.py       #     Solana implementation
│       ├── strategies/      #   Trading strategies
│       └── executors/       #   Order executors
│
└── docs/                    # Documentation
```

---

## Design Principles

### 1. Non-Custodial

- Users maintain full control of their assets
- Assets stored in user-specific vaults/PDAs
- Protocol cannot move funds without user-signed orders

### 2. Separation of Concerns

| Layer    | Responsibility            | EVM Location    | SVM Location          |
| -------- | ------------------------- | --------------- | --------------------- |
| Vault    | Asset custody, order CRUD | `SentinelVault` | `sentinel_vault` prog |
| Modules  | Business logic            | `modules/`      | (inline in lib.rs)    |
| Adapters | External integrations     | `adapters/`     | CPI calls             |
| Keeper   | Condition monitoring      | `keeper/`       | `keeper/` (same)      |

### 3. Chain Abstraction

The Keeper uses the **Strategy Pattern** to support multiple chains:

```python
from sentinel_keeper.chain import EVMClient, SolanaClient

# Same interface, different chains
clients: list[ChainClient] = [
    EVMClient(rpc_url="https://arb1.arbitrum.io/rpc", ...),
    SolanaClient(rpc_url="https://api.mainnet-beta.solana.com", ...),
]

for client in clients:
    orders = await client.get_active_orders(vault_address)
    for order in orders:
        if strategy.should_execute(order):
            await client.execute_order(vault_address, order.id)
```

---

## EVM vs SVM: Key Differences

| Aspect      | EVM (Ethereum)            | SVM (Solana)                 |
| ----------- | ------------------------- | ---------------------------- |
| Language    | Solidity                  | Rust                         |
| State Model | Contract-internal storage | Program + Account separation |
| Execution   | Sequential                | Parallel (faster for HFT)    |
| Tooling     | Foundry                   | Anchor                       |
| Gas/Fees    | Variable (EIP-1559)       | Fixed compute units          |
| Oracles     | Chainlink                 | Pyth, Switchboard            |
| DEXs        | Uniswap, Curve            | Jupiter, Raydium             |

### EVM Storage vs Solana PDAs

**EVM (Storage in Contract):**

```solidity
mapping(address => mapping(address => uint256)) public balances;
mapping(uint256 => Order) public orders;
```

**Solana (Separate Accounts):**

```rust
#[account]
pub struct Vault {
    pub owner: Pubkey,
    pub order_count: u64,
}

#[account]
pub struct Order {
    pub vault: Pubkey,
    pub trigger_price: u64,
}
// Orders are PDAs derived from vault + order_id
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

### Strategic Roadmap

| Phase      | Focus                                          | Status         |
| ---------- | ---------------------------------------------- | -------------- |
| **Step 1** | Repo structure refactoring (`evm/` + `svm/`)   | ✅ Complete    |
| **Step 2** | Python Keeper chain abstraction                | ✅ Complete    |
| **Step 3** | EVM feature completion (Stop-Loss, Flash Loan) | 🔄 In Progress |
| **Step 4** | Solana program implementation (Anchor)         | 📋 Planned     |

### Multi-Chain Support

- **EVM L2s**: Arbitrum, Base, Optimism (same Solidity code)
- **Solana**: Native Rust program for high-frequency trading
- Cross-chain message passing (LayerZero, Wormhole) - future

### Advanced Strategies

- TWAP: Time-weighted average price execution
- Grid Trading: Range-based order ladders
- DCA: Dollar-cost averaging schedules

### MEV Protection

- Flashbots integration for private mempools (EVM)
- Jito bundles for MEV protection (Solana)
