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

// =========================================================================
// Enums
// =========================================================================

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

// =========================================================================
// Structs
// =========================================================================

/// @notice Trigger conditions for order execution
struct Trigger {
    address oracle;         // Price oracle address
    uint256 targetPrice;    // Target price (1e18 scale)
    uint256 deadline;       // Order expiration timestamp
}

/// @notice Execution parameters for order
struct Execution {
    address inputToken;     // Token to sell
    address outputToken;    // Token to buy
    uint256 inputAmount;    // Amount to sell
    uint256 minOutputAmount; // Minimum amount to receive
    uint16 slippageBps;     // Slippage tolerance in basis points (100 = 1%)
}

/// @notice Complete order data structure
struct Order {
    uint256 id;
    address owner;
    OrderKind kind;
    OrderState state;
    Trigger trigger;
    Execution execution;
    uint256 createdAt;
}
```

### Events (VaultEvents.sol)

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {OrderKind} from "./VaultTypes.sol";

// =========================================================================
// Order Lifecycle Events
// =========================================================================

/// @notice Emitted when a new order is created
event OrderCreated(
    uint256 indexed orderId,
    address indexed owner,
    OrderKind kind
);

/// @notice Emitted when an order is updated
event OrderUpdated(uint256 indexed orderId);

/// @notice Emitted when an order is cancelled
event OrderCancelled(uint256 indexed orderId);

/// @notice Emitted when an order is executed
event OrderExecuted(
    uint256 indexed orderId,
    address indexed keeper,
    uint256 amountIn,
    uint256 amountOut
);

// =========================================================================
// Admin Events
// =========================================================================

/// @notice Emitted when keeper authorization changes
event KeeperAuthorized(address indexed keeper, bool allowed);

/// @notice Emitted when an adapter is configured
event AdapterSet(bytes32 indexed adapterKey, address adapter);

/// @notice Emitted when protocol is paused
event Paused(address indexed by);

/// @notice Emitted when protocol is unpaused
event Unpaused(address indexed by);
```

### Errors (VaultErrors.sol)

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// =========================================================================
// Authorization Errors
// =========================================================================

/// @notice Caller is not the order owner
error NotOrderOwner();

/// @notice Caller is not an authorized keeper
error UnauthorizedKeeper();

/// @notice Signature verification failed
error InvalidSignature();

// =========================================================================
// Order State Errors
// =========================================================================

/// @notice Order is not in OPEN state
error OrderNotOpen();

/// @notice Order has passed its deadline
error OrderExpired();

/// @notice Order has already been executed
error OrderAlreadyExecuted();

// =========================================================================
// Execution Errors
// =========================================================================

/// @notice Price condition not met for execution
error TriggerNotSatisfied();

/// @notice Slippage exceeds maximum allowed
error SlippageTooHigh();

/// @notice Insufficient token balance
error InsufficientBalance();

/// @notice Token transfer failed
error TransferFailed();

// =========================================================================
// Configuration Errors
// =========================================================================

/// @notice Required adapter not configured
error AdapterNotSet();

/// @notice Address cannot be zero
error ZeroAddress();

/// @notice Amount cannot be zero
error ZeroAmount();

/// @notice Deadline is in the past or too far
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

Use `///` single-line NatSpec comments (not `/** */` block comments):

```solidity
/// @title SentinelVault
/// @notice Main vault contract for automated order execution
/// @dev Implements Hub & Spoke architecture

/// @notice Creates a new order
/// @dev Assets must already be deposited in the vault
/// @param order The order parameters
/// @return orderId The unique identifier of the created order
function createOrder(Order calldata order) external returns (uint256 orderId) {
    // implementation
}
```

### Contract Layout Order

Follow this section order within contracts:

```solidity
contract SentinelVault is Ownable, ReentrancyGuard {
    // =========================================================================
    // State Variables
    // =========================================================================

    /// @notice Mapping of authorized strategy modules
    mapping(address => bool) public isModule;

    /// @notice Reference to the parent vault contract
    ISentinelVault public immutable VAULT;  // immutables use SCREAMING_SNAKE_CASE

    // =========================================================================
    // Events
    // =========================================================================

    /// @notice Emitted when a new order is created
    event OrderCreated(uint256 indexed orderId, address indexed owner);

    // =========================================================================
    // Errors
    // =========================================================================

    /// @notice Order is not in ACTIVE state
    error OrderNotActive();

    // =========================================================================
    // Modifiers
    // =========================================================================

    modifier onlyModule() {
        _onlyModule();
        _;
    }

    function _onlyModule() internal view {
        if (!isModule[msg.sender]) {
            revert UnauthorizedModule(msg.sender);
        }
    }

    // =========================================================================
    // Constructor
    // =========================================================================

    constructor() Ownable(msg.sender) {}

    // =========================================================================
    // Governance Functions (Owner)
    // =========================================================================

    // =========================================================================
    // Core Logic (Module)
    // =========================================================================

    // =========================================================================
    // Public Functions
    // =========================================================================

    // =========================================================================
    // Internal Functions
    // =========================================================================
}
```

### Section Separators

Use consistent 77-character `=` separators:

```solidity
// =========================================================================
// Section Name
// =========================================================================
```

### Variable Naming

| Type      | Convention             | Example                 |
| --------- | ---------------------- | ----------------------- |
| State     | `camelCase`            | `nextOrderId`           |
| Immutable | `SCREAMING_SNAKE_CASE` | `VAULT`, `MAX_SLIPPAGE` |
| Constant  | `SCREAMING_SNAKE_CASE` | `PRICE_PRECISION`       |
| Parameter | `_camelCase`           | `_orderId`, `_token`    |
| Local     | `camelCase`            | `orderId`, `amount`     |

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

# ✅ Good - structured logging with Rich
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
- [ ] Immutables are `SCREAMING_SNAKE_CASE`?
- [ ] NatSpec comments use `///` style?
- [ ] Section separators use `// ===...===`?
- [ ] Using Custom Errors (instead of require)?
- [ ] Events are properly emitted?

**Python:**

- [ ] Class names are `PascalCase`?
- [ ] Function names are `snake_case`?
- [ ] Type hints on all functions?
- [ ] Docstrings are written?
- [ ] Using Rich-based logger for structured logging?
- [ ] Using relative imports for internal modules?
