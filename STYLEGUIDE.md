# 🎨 Style Guide

> **"Consistent naming is the team's language and the brand's identity."**

This document defines the naming conventions and code style for Sentinel Protocol.
All contributors should follow this guide to maintain a consistent codebase.

---

## 📋 Table of Contents

- [General Naming Rules](#general-naming-rules)
- [Repository Structure](#repository-structure)
- [Solidity Conventions](#solidity-conventions)
- [Python Conventions](#python-conventions)
- [Domain Terminology](#domain-terminology)

---

## General Naming Rules

| Target             | Convention            | Example                                     |
| ------------------ | --------------------- | ------------------------------------------- |
| Repository/Folder  | `kebab-case`          | `sentinel-vault`, `order-module`            |
| Solidity Contract  | `PascalCase`          | `SentinelVault`, `OrderModule`              |
| Solidity Function  | `camelCase`           | `createOrder`, `executeOrder`               |
| Python Package     | `snake_case`          | `sentinel_keeper`                           |
| Python Module/File | `snake_case`          | `order_executor.py`                         |
| Python Class       | `PascalCase`          | `KeeperService`, `EventIndexer`             |
| Python Function    | `snake_case`          | `poll_blocks`, `handle_event`               |
| Events             | `Domain + Past Tense` | `OrderCreated`, `OrderExecuted`             |
| Errors             | `2-3 Word Phrase`     | `TriggerNotSatisfied`, `UnauthorizedKeeper` |

---

## Repository Structure

```
sentinel-vault/
├── contracts/                   # On-Chain (Solidity)
│   ├── src/
│   │   ├── SentinelVault.sol    # main vault contract
│   │   ├── VaultTypes.sol       # struct/enum definitions
│   │   ├── VaultErrors.sol      # custom errors
│   │   ├── VaultEvents.sol      # events
│   │   ├── interfaces/          # contract interfaces
│   │   │   └── ISentinelVault.sol
│   │   ├── modules/             # internal logic modules
│   │   │   ├── OrderModule.sol
│   │   │   ├── ExecutionModule.sol
│   │   │   ├── RiskModule.sol
│   │   │   └── AuthModule.sol
│   │   └── adapters/            # external integration adapters
│   │       ├── OracleAdapter.sol
│   │       └── SwapAdapter.sol
│   ├── test/
│   ├── script/
│   └── lib/                     # dependencies (forge-std, openzeppelin)
├── keeper/                      # Off-Chain (Python)
│   ├── sentinel_keeper/
│   │   ├── __init__.py
│   │   ├── app.py               # entrypoint
│   │   ├── config.py
│   │   ├── chain/               # blockchain connectivity
│   │   │   ├── client.py
│   │   │   ├── events.py
│   │   │   └── tx.py
│   │   ├── strategies/          # strategy logic
│   │   │   ├── stoploss.py
│   │   │   └── twap.py
│   │   ├── executors/           # execution and retry
│   │   │   ├── order_executor.py
│   │   │   └── retry.py
│   │   └── observability/       # logging/metrics
│   │       ├── logger.py
│   │       └── metrics.py
│   └── pyproject.toml
├── sdk/                         # (Optional) External SDK
│   ├── python/
│   └── typescript/
├── deployments/                 # Per-chain deployment artifacts
│   ├── sepolia/
│   └── mainnet/
└── docs/
```

### Directory Separation Principles

| Directory     | Role                      | Separation Criteria                 |
| ------------- | ------------------------- | ----------------------------------- |
| `interfaces/` | Contract interfaces       | Public API definitions (Solidity)   |
| `modules/`    | Core business logic       | Operates only within protocol       |
| `adapters/`   | External integrations     | External dependencies (Oracle, DEX) |
| `chain/`      | Blockchain infrastructure | RPC, events, transactions           |
| `strategies/` | Decision logic            | Determines when to execute          |
| `executors/`  | Execution logic           | Handles how to execute              |

---

## Solidity Conventions

### File Structure

```
contracts/src/
├── SentinelVault.sol        # Main contract
├── VaultTypes.sol           # Types (struct, enum)
├── VaultErrors.sol          # Custom Errors
├── VaultEvents.sol          # Events
├── interfaces/              # Contract interfaces
│   └── ISentinelVault.sol
├── modules/                 # Internal Logic
└── adapters/                # External Integration
```

### Contract Naming

```solidity
// ✅ Good
contract SentinelVault { }
contract OrderModule { }
contract OracleAdapter { }

// ❌ Bad
contract sentinel_vault { }
contract ordermodule { }
contract Oracle_Adapter { }
```

### Types (VaultTypes.sol)

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @notice Order kind enumeration
enum OrderKind {
    STOP_LOSS,
    TAKE_PROFIT,
    TWAP
}

/// @notice Order state enumeration
enum OrderState {
    OPEN,
    EXECUTED,
    CANCELLED,
    EXPIRED
}

/// @notice Order data structure
struct Order {
    uint256 id;
    address owner;
    OrderKind kind;
    OrderState state;
    Trigger trigger;
    Execution execution;
}

/// @notice Execution conditions (price, time, etc.)
struct Trigger {
    address oracle;
    uint256 targetPrice;    // 1e18 scale
    uint256 deadline;
}

/// @notice Execution parameters
struct Execution {
    address inputToken;
    address outputToken;
    uint256 inputAmount;
    uint256 minOutputAmount;
    uint16 slippageBps;     // basis points (100 = 1%)
}
```

### Events (VaultEvents.sol)

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {OrderKind} from "./VaultTypes.sol";

/// @notice Order lifecycle events
event OrderCreated(
    uint256 indexed orderId,
    address indexed owner,
    OrderKind kind
);

event OrderUpdated(uint256 indexed orderId);

event OrderCancelled(uint256 indexed orderId);

event OrderExecuted(
    uint256 indexed orderId,
    address indexed keeper,
    uint256 amountIn,
    uint256 amountOut
);

/// @notice Admin events
event KeeperAuthorized(address indexed keeper, bool allowed);

event AdapterSet(bytes32 indexed adapterKey, address adapter);

event Paused(address indexed by);

event Unpaused(address indexed by);
```

### Errors (VaultErrors.sol)

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @notice Authorization errors
error NotOrderOwner();
error UnauthorizedKeeper();
error InvalidSignature();

/// @notice Order state errors
error OrderNotOpen();
error OrderExpired();
error OrderAlreadyExecuted();

/// @notice Execution errors
error TriggerNotSatisfied();
error SlippageTooHigh();
error InsufficientBalance();
error TransferFailed();

/// @notice Configuration errors
error AdapterNotSet();
error ZeroAddress();
error ZeroAmount();
error InvalidDeadline();
```

### Function Naming

```solidity
// Create
function createOrder(Order calldata order) external returns (uint256 orderId);

// Cancel
function cancelOrder(uint256 orderId) external;

// Query
function getOrder(uint256 orderId) external view returns (Order memory);
function getOrdersByOwner(address owner) external view returns (uint256[] memory);

// Execute
function executeOrder(uint256 orderId) external;
function executeBatch(uint256[] calldata orderIds) external;

// Validate (internal)
function _validateTrigger(Trigger memory trigger) internal view returns (bool);
function _validateExecution(Execution memory exec) internal view returns (bool);
```

### NatSpec Comments

```solidity
/// @title SentinelVault
/// @author Sentinel Protocol Team
/// @notice Main vault contract for automated order execution
/// @dev Implements EIP-712 for signature verification

/// @notice Creates a new order
/// @param order The order parameters
/// @return orderId The unique identifier of the created order
/// @dev Emits {OrderCreated} event
function createOrder(Order calldata order) external returns (uint256 orderId) {
    // implementation
}
```

---

## Python Conventions

### Package Structure

```
keeper/
├── sentinel_keeper/           # Main package
│   ├── __init__.py
│   ├── app.py                 # Entrypoint
│   ├── config.py              # Configuration management
│   ├── chain/                 # Blockchain layer
│   │   ├── __init__.py
│   │   ├── client.py          # Web3 provider
│   │   ├── events.py          # Event subscription
│   │   └── tx.py              # Transaction management
│   ├── strategies/            # Strategy layer
│   │   ├── __init__.py
│   │   ├── base.py            # Abstract class
│   │   ├── stoploss.py
│   │   └── twap.py
│   ├── executors/             # Execution layer
│   │   ├── __init__.py
│   │   ├── order_executor.py
│   │   └── retry.py
│   └── observability/         # Observability layer
│       ├── __init__.py
│       ├── logger.py
│       └── metrics.py
└── tests/
```

### Class Naming

```python
# ✅ Good - PascalCase for classes
class KeeperService:
    """Main keeper application loop."""
    pass

class EventIndexer:
    """Indexes blockchain events."""
    pass

class OrderExecutor:
    """Executes orders on-chain."""
    pass

class ChainClient:
    """Web3 provider wrapper."""
    pass

# ❌ Bad
class keeper_service:
    pass

class eventIndexer:
    pass
```

### Function Naming

```python
# ✅ Good - snake_case for functions
async def poll_blocks() -> None:
    """Poll new blocks from the chain."""
    pass

async def handle_event(event: dict) -> None:
    """Handle a blockchain event."""
    pass

async def submit_tx(tx: Transaction) -> TxReceipt:
    """Submit a transaction to the chain."""
    pass

def validate_order(order: Order) -> bool:
    """Validate order parameters."""
    pass

# ❌ Bad
async def PollBlocks():
    pass

async def handleEvent():
    pass
```

### Type Hints Required

```python
from typing import Optional
from pydantic import BaseModel

class Order(BaseModel):
    """Order model matching on-chain struct."""

    id: int
    owner: str
    kind: OrderKind
    state: OrderState
    trigger: Trigger
    execution: Execution


async def get_order(order_id: int) -> Optional[Order]:
    """Fetch order from chain.

    Args:
        order_id: The unique order identifier.

    Returns:
        The order if found, None otherwise.
    """
    pass
```

### Logging Convention

```python
from ..observability.logger import get_logger

log = get_logger()

# ✅ Good - structured logging with rich
log.info("order_created", order_id=123, owner="0x...")
log.error("execution_failed", order_id=123, error=str(e))

# Domain-specific methods
log.keeper_starting(chain_id=1, vault_address="0x...")
log.order_executed(order_id=123, keeper="0x...", gas_used=150000, amount_out=1000)

# ❌ Bad - unstructured logging
log.info(f"Order {order_id} created by {owner}")
```

### Import Conventions

```python
# =========================================================================
# Import Order (enforced by ruff/isort)
# =========================================================================
# 1. Standard library
# 2. Third-party packages
# 3. Local imports (relative)

# =========================================================================
# Relative vs Absolute Imports
# =========================================================================

# ✅ Good - Relative imports for internal modules
from .config import get_settings
from ..models.order import Order
from ..observability.logger import get_logger

# ✅ Good - Absolute imports for third-party packages
from pydantic import BaseModel
from web3 import Web3

# ❌ Bad - Absolute imports for internal modules
from sentinel_keeper.config import get_settings
from sentinel_keeper.models.order import Order
```

**Import Guidelines:**

| Import Type                     | When to Use              | Example                            |
| ------------------------------- | ------------------------ | ---------------------------------- |
| Relative (`from .` / `from ..`) | Internal package modules | `from ..models.order import Order` |
| Absolute                        | Third-party packages     | `from web3 import Web3`            |
| Absolute                        | System paths (env vars)  | `Path(os.environ["CONFIG_PATH"])`  |

---

## Domain Terminology

### Core Term Definitions

| Term      | Description                                    |
| --------- | ---------------------------------------------- |
| Order     | Conditional execution request created by user  |
| Trigger   | Order execution conditions (price, time, etc.) |
| Execution | Actual swap parameters for the order           |
| Keeper    | Bot that monitors conditions and executes      |
| Adapter   | Abstraction for external protocol integration  |
| Module    | Internal logic component                       |

### Order Lifecycle

```
OPEN → EXECUTED
     ↘ CANCELLED
     ↘ EXPIRED
```

| State       | Description                | Transition Condition   |
| ----------- | -------------------------- | ---------------------- |
| `OPEN`      | Active, awaiting execution | Initial state          |
| `EXECUTED`  | Successfully executed      | Trigger conditions met |
| `CANCELLED` | Cancelled by user          | `cancelOrder()` called |
| `EXPIRED`   | Deadline passed            | `deadline` exceeded    |

### Price Scaling

```solidity
// All prices use 1e18 scale
uint256 constant PRICE_PRECISION = 1e18;

// Example: ETH price $2000
uint256 ethPrice = 2000 * PRICE_PRECISION;  // 2000000000000000000000
```

### Slippage (Basis Points)

```solidity
// 1 bp = 0.01% = 0.0001
// 100 bp = 1%
uint16 constant MAX_SLIPPAGE_BPS = 500;  // 5%

// Example: 0.5% slippage
uint16 slippageBps = 50;
```

---

## Checklist

### Pre-PR Submission Checklist

**Solidity:**

- [ ] Contract names are `PascalCase`?
- [ ] Function names are `camelCase`?
- [ ] NatSpec comments are written?
- [ ] Using Custom Errors (instead of require)?
- [ ] Events are properly emitted?

**Python:**

- [ ] Class names are `PascalCase`?
- [ ] Function names are `snake_case`?
- [ ] Type hints on all functions?
- [ ] Docstrings are written?
- [ ] Using structlog for structured logging?
