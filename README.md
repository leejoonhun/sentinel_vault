# 🛡️ Sentinel Protocol

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Solidity](https://img.shields.io/badge/Solidity-0.8.24-blue.svg)](https://soliditylang.org/)
[![Foundry](https://img.shields.io/badge/Built%20with-Foundry-orange.svg)](https://getfoundry.sh/)
[![Python](https://img.shields.io/badge/Python-3.11%20|%203.12-green.svg)](https://www.python.org/)

> **The Modular On-Chain Execution Layer for Quantitative Finance**

Sentinel Protocol is an open-source infrastructure that enables **automated, trustless execution** of trading strategies on EVM-compatible blockchains. It bridges the gap between off-chain quantitative logic and on-chain DeFi execution.

---

## ✨ Features

- 🏦 **Non-Custodial Vault** - Your assets, your keys. The protocol never takes custody.
- 🔌 **Modular Architecture** - Plug-and-play strategy modules (StopLoss, TakeProfit, TWAP)
- 🤖 **Keeper Network** - Off-chain bots monitor conditions and trigger executions
- 🔗 **DEX Agnostic** - Adapter pattern supports Uniswap, SushiSwap, and more
- 🛡️ **Security First** - Reentrancy guards, access control, and emergency pause
- ⚡ **Gas Optimized** - Efficient storage patterns and batched operations

---

## 🏗️ Architecture

```
        ┌────────────────────────────────────────────┐
        │                USER INTERFACE              │
        └─────────────────────┬──────────────────────┘
                              │
                              ▼
        ┌────────────────────────────────────────────┐
        │               SENTINEL VAULT               │
        │          (Asset Custody & Orders)          │
        └─────────────────────┬──────────────────────┘
                              │
                              ▼
        ┌────────────────────────────────────────────┐
        │                  MODULES                   │
        │  ┌──────────┐ ┌──────────┐ ┌───────────┐   │
        │  │  Order   │ │   Risk   │ │   Auth    │   │
        │  │  Module  │ │  Module  │ │   Module  │   │
        │  └──────────┘ └──────────┘ └───────────┘   │
        └─────────────────────┬──────────────────────┘
                              │
                              ▼
        ┌────────────────────────────────────────────┐
        │                  ADAPTERS                  │
        │         ┌──────────┐ ┌──────────┐          │
        │         │  Oracle  │ │   Swap   │          │
        │         │ Adapter  │ │  Adapter │          │
        │         └──────────┘ └──────────┘          │
        └─────────────────────┬──────────────────────┘
                              │
                              ▼
        ┌────────────────────────────────────────────┐
        │           EXTERNAL PROTOCOLS               │
        │     (Uniswap, SushiSwap, Chainlink...)     │
        └────────────────────────────────────────────┘

                    ┌─────────────┐
                    │   KEEPER    │  ◄── Off-Chain Bot
                    │  (Python)   │      Monitors & Executes
                    └─────────────┘
```

### Design Philosophy

**Hub-and-Spoke Pattern**: `SentinelVault` acts as the central hub holding assets, while `Modules` handle specific logic. This separation ensures:

- Minimal attack surface on the vault
- Easy auditing of individual modules
- Upgradeable strategies without touching core assets

---

## 📁 Project Structure

```
sentinel-vault/
├── .github/workflows/         # CI/CD
│   ├── forge-test.yml         # Solidity tests
│   └── python-lint.yml        # Python linting
├── contracts/                 # On-Chain (Solidity)
│   ├── src/
│   │   ├── SentinelVault.sol  # Main vault contract
│   │   ├── VaultTypes.sol     # Structs & enums (Order, Trigger, Execution)
│   │   ├── VaultErrors.sol    # Custom errors
│   │   ├── VaultEvents.sol    # Events
│   │   ├── interfaces/        # Contract interfaces
│   │   │   ├── ISentinelVault.sol
│   │   │   └── ISentinelTypes.sol
│   │   ├── modules/           # Business logic modules
│   │   │   └── OrderModule.sol # Conditional orders (stop-loss, take-profit)
│   │   └── adapters/          # External integrations (planned)
│   ├── test/
│   │   ├── SentinelVault.t.sol
│   │   ├── OrderModule.t.sol
│   │   └── mocks/
│   │       └── MockOracle.sol
│   ├── script/
│   │   └── Deploy.s.sol
│   └── lib/                   # Dependencies
│       ├── forge-std/
│       ├── openzeppelin-contracts/
│       └── solmate/
├── keeper/                    # Off-Chain (Python)
│   ├── sentinel_keeper/
│   │   ├── app.py             # KeeperService entrypoint
│   │   ├── config.py          # Settings (pydantic-settings)
│   │   ├── main.py            # CLI entrypoint
│   │   ├── chain/             # Blockchain layer
│   │   │   ├── client.py      # ChainClient (Web3)
│   │   │   ├── events.py      # EventIndexer
│   │   │   └── tx.py          # TransactionManager
│   │   ├── strategies/        # Strategy evaluation
│   │   │   └── base.py        # BaseStrategy (ABC)
│   │   ├── executors/         # Order execution
│   │   │   ├── order_executor.py
│   │   │   └── retry.py       # Retry with backoff
│   │   ├── models/            # Pydantic models
│   │   │   └── order.py       # Order, Trigger, Execution
│   │   └── observability/     # Logging & metrics
│   │       ├── logger.py      # Rich-based logging
│   │       └── metrics.py     # MetricsCollector
│   ├── tests/
│   └── pyproject.toml
├── docs/                      # Documentation
│   ├── ARCHITECTURE.md        # System architecture
│   ├── CONTRACTS.md           # Contract documentation
│   ├── KEEPER.md              # Keeper bot documentation
│   └── README.md              # Docs index
├── STYLEGUIDE.md              # Naming conventions
├── CONTRIBUTING.md            # Contribution guide
├── docker-compose.yml         # Local dev environment
├── Makefile                   # Build automation
└── LICENSE                    # MIT License
```

---

## 🚀 Getting Started

### Prerequisites

- [Foundry](https://getfoundry.sh/) (Forge, Anvil)
- [Python 3.11+](https://www.python.org/)
- [uv](https://docs.astral.sh/uv/) (Fast Python package manager)

### Installation

```bash
# Clone the repository
git clone https://github.com/your-username/sentinel-vault.git
cd sentinel-vault

# Install all dependencies
make install

# Or manually:
cd contracts && forge install
cd ../keeper && uv sync
```

### Quick Start

```bash
# 1. Start local Anvil node
make anvil

# 2. Deploy contracts (new terminal)
make deploy-local

# 3. Run keeper bot (new terminal)
make keeper-local
```

---

## 📖 Usage

### Creating a Stop-Loss Order

```solidity
import {Order, OrderKind, Trigger, Execution} from "./VaultTypes.sol";

// Create order
Order memory order = Order({
    id: 0,  // Assigned by contract
    owner: msg.sender,
    kind: OrderKind.STOP_LOSS,
    state: OrderState.OPEN,
    trigger: Trigger({
        oracle: chainlinkOracle,
        targetPrice: 2000 * 1e18,  // Trigger at $2000
        deadline: block.timestamp + 7 days
    }),
    execution: Execution({
        inputToken: WETH,
        outputToken: USDC,
        inputAmount: 1 ether,
        minOutputAmount: 1900 * 1e6,  // Min USDC out
        slippageBps: 50  // 0.5%
    }),
    createdAt: 0  // Set by contract
});

vault.createOrder(order);
```

### Running the Keeper

```bash
# Configure environment
cp keeper/.env.example keeper/.env
# Edit .env with your RPC URL and private key

# Run keeper
make keeper-local
# Or: cd keeper && uv run python -m sentinel_keeper.main
```

---

## 🗺️ Roadmap

### Phase 1: The Skeleton ✅

- [x] Repository structure & tooling
- [x] VaultTypes, VaultErrors, VaultEvents
- [x] ISentinelVault interface
- [x] ISentinelTypes interface
- [x] Python keeper scaffold (chain/, strategies/, executors/)
- [x] Rich-based structured logging

### Phase 2: The Logic ✅

- [x] SentinelVault core implementation (deposit, withdraw, invoke)
- [x] OrderModule (createOrder, cancelOrder, executeOrder)
- [x] MockOracle for testing
- [x] SentinelVault test suite (8 tests)
- [x] OrderModule test suite (3 tests)

### Phase 3: The Brand 🚧

- [ ] SwapAdapter (Uniswap V3)
- [ ] OracleAdapter (Chainlink)
- [ ] Keeper execution logic integration
- [ ] Local fork testing (Anvil)
- [ ] Security audit preparation
- [ ] Testnet deployment

### Future

- [ ] Multi-chain support (Arbitrum, Base, Polygon)
- [ ] Advanced strategies (TWAP, Grid Trading)
- [ ] Flashbots integration for MEV protection
- [ ] Governance token & DAO

---

## 🧪 Testing

### Solidity Tests

```bash
# Run all tests
make test

# With verbosity
make test-v

# Gas report
make gas

# Coverage
make coverage
```

### Python Tests

```bash
# Run all tests
make keeper-test

# With coverage
make keeper-test-cov
```

---

## 🔐 Security

### Implemented Safeguards

- **ReentrancyGuard** - Prevents reentrancy attacks
- **Access Control** - Role-based permissions (Owner, Keeper, Module)
- **Emergency Pause** - Circuit breaker for critical situations
- **Custom Errors** - Gas-efficient error handling
- **Oracle Staleness Check** - Validates price feed freshness

### Responsible Disclosure

Found a vulnerability? Please email **security@sentinel-protocol.xyz** (do not open a public issue).

---

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) and [Style Guide](STYLEGUIDE.md) for details.

```bash
# Install pre-commit hooks
pip install pre-commit
pre-commit install

# Run linters
make lint
```

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- [OpenZeppelin](https://openzeppelin.com/) - Security patterns and libraries
- [Foundry](https://getfoundry.sh/) - Blazing fast Solidity toolchain
- [Uniswap](https://uniswap.org/) - DEX integration reference
- [Chainlink](https://chain.link/) - Price oracle infrastructure
