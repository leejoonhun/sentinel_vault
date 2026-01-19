# 📜 Contracts Documentation

> Detailed documentation for Sentinel Protocol smart contracts

---

## Overview

The contract system follows a **Hub-and-Spoke** pattern:

```
contracts/src/
├── SentinelVault.sol        # Main hub contract (WIP)
├── VaultTypes.sol           # Shared types (struct, enum)
├── VaultErrors.sol          # Custom errors
├── VaultEvents.sol          # Events
├── interfaces/
│   └── ISentinelVault.sol   # Public interface
├── modules/                 # Internal logic
│   ├── OrderModule.sol
│   ├── ExecutionModule.sol
│   ├── RiskModule.sol
│   └── AuthModule.sol
└── adapters/                # External integrations
    ├── OracleAdapter.sol
    └── SwapAdapter.sol
```

---

## Core Types (`VaultTypes.sol`)

### Enums

```solidity
/// @notice Order kind enumeration
enum OrderKind {
    STOP_LOSS,      // Sell when price drops below target
    TAKE_PROFIT,    // Sell when price rises above target
    TWAP            // Time-weighted average execution
}

/// @notice Order state enumeration
enum OrderState {
    OPEN,           // Active, awaiting execution
    EXECUTED,       // Successfully executed
    CANCELLED,      // Cancelled by user
    EXPIRED         // Deadline passed
}
```

### Structs

```solidity
/// @notice Trigger conditions for order execution
struct Trigger {
    address oracle;         // Price oracle address
    uint256 targetPrice;    // Target price (1e18 scale)
    uint256 deadline;       // Order expiration timestamp
}

/// @notice Execution parameters
struct Execution {
    address inputToken;     // Token to sell
    address outputToken;    // Token to buy
    uint256 inputAmount;    // Amount to sell
    uint256 minOutputAmount; // Minimum amount to receive
    uint16 slippageBps;     // Slippage tolerance (100 = 1%)
}

/// @notice Complete order structure
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

### Scaling

| Field         | Scale    | Example           |
| ------------- | -------- | ----------------- |
| `targetPrice` | 1e18     | $2000 = `2000e18` |
| `slippageBps` | basis pt | 0.5% = `50`       |
| Token amounts | decimals | Depends on token  |

---

## Errors (`VaultErrors.sol`)

Custom errors for gas-efficient reverts:

### Authorization Errors

| Error                | Description                         |
| -------------------- | ----------------------------------- |
| `NotOrderOwner`      | Caller is not the order owner       |
| `UnauthorizedKeeper` | Caller is not an authorized keeper  |
| `InvalidSignature`   | EIP-712 signature validation failed |

### Order State Errors

| Error                  | Description                |
| ---------------------- | -------------------------- |
| `OrderNotOpen`         | Order is not in OPEN state |
| `OrderExpired`         | Order deadline has passed  |
| `OrderAlreadyExecuted` | Order was already executed |

### Execution Errors

| Error                 | Description                  |
| --------------------- | ---------------------------- |
| `TriggerNotSatisfied` | Price condition not met      |
| `SlippageTooHigh`     | Output below minOutputAmount |
| `InsufficientBalance` | User balance too low         |
| `TransferFailed`      | Token transfer reverted      |

### Configuration Errors

| Error             | Description                     |
| ----------------- | ------------------------------- |
| `AdapterNotSet`   | Required adapter not configured |
| `ZeroAddress`     | Address parameter is zero       |
| `ZeroAmount`      | Amount parameter is zero        |
| `InvalidDeadline` | Deadline is in the past         |

---

## Events (`VaultEvents.sol`)

### Order Events

```solidity
/// @notice Emitted when an order is created
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
```

### Admin Events

```solidity
/// @notice Emitted when a keeper is authorized/deauthorized
event KeeperAuthorized(address indexed keeper, bool allowed);

/// @notice Emitted when an adapter is configured
event AdapterSet(bytes32 indexed adapterKey, address adapter);

/// @notice Emitted when the protocol is paused
event Paused(address indexed by);

/// @notice Emitted when the protocol is unpaused
event Unpaused(address indexed by);
```

---

## Interface (`ISentinelVault.sol`)

The vault interface defines the core contract API:

### Events

```solidity
/// @notice Emitted when tokens are deposited into the vault
event Deposit(address indexed token, address indexed from, uint256 amount);

/// @notice Emitted when tokens are withdrawn from the vault
event Withdraw(address indexed token, address indexed to, uint256 amount);

/// @notice Emitted when a module's authorization status changes
event ModuleSet(address indexed module, bool isAuthorized);

/// @notice Emitted when a module executes an external call
event Executed(address indexed module, address indexed target, uint256 value, bytes data);
```

### Errors

```solidity
/// @notice Thrown when caller is not an authorized module
error UnauthorizedModule(address caller);

/// @notice Thrown when an external call fails
error TargetCallFailed(address target, bytes returnData);

/// @notice Thrown when amount is zero or invalid
error InvalidAmount();
```

### User Functions

```solidity
/// @notice Deposit tokens into the vault
function deposit(address token, uint256 amount) external;

/// @notice Withdraw tokens from the vault
function withdraw(address token, uint256 amount) external;
```

### Module Functions

```solidity
/// @notice Execute an arbitrary call on behalf of the vault
/// @dev Only callable by authorized modules
function invoke(
    address target,
    uint256 value,
    bytes calldata data
) external returns (bytes memory result);
```

### Admin Functions

```solidity
/// @notice Set module authorization status
function setModule(address module, bool isAuthorized) external;

/// @notice Check if an address is an authorized module
function isModule(address module) external view returns (bool);
```

---

## Modules

### OrderModule (`modules/OrderModule.sol`)

Manages conditional orders (stop-loss, take-profit, TWAP):

```solidity
/// @notice Create a new conditional order
function createOrder(
    address _inputToken,
    address _outputToken,
    uint256 _inputQuantity,
    uint256 _targetPrice,
    OrderType _orderType
) external returns (uint256);

/// @notice Cancel an existing order
function cancelOrder(uint256 _orderId) external;

/// @notice Execute an order when conditions are met
function executeOrder(
    uint256 _orderId,
    address _target,
    bytes calldata _swapData
) external;
```

**Key Features:**

- `VAULT` immutable reference to parent vault
- Oracle-based price verification
- State transitions: ACTIVE → EXECUTED | CANCELLED

### ExecutionModule (Planned)

Handles swap execution via adapters:

- `_executeSwap()`: Call DEX adapter
- `_validateSlippage()`: Check output amount
- `_updateBalances()`: Adjust user balances

### RiskModule (Planned)

Risk management:

- `_checkPositionLimit()`: Max order size
- `_checkExposure()`: Total exposure limits

### AuthModule (Planned)

Access control:

- `_onlyOwner()`: Admin functions
- `_onlyModule()`: Authorized module functions
- `_onlyOrderOwner()`: Order owner functions

---

## Adapters

### OracleAdapter

Price feed integration:

```solidity
interface IOracleAdapter {
    /// @notice Get current price
    /// @param base Base token (e.g., WETH)
    /// @param quote Quote token (e.g., USDC)
    /// @return price Price in 1e18 scale
    function getPrice(address base, address quote) external view returns (uint256 price);

    /// @notice Check if price is fresh
    /// @return fresh True if within staleness threshold
    function isPriceFresh(address base, address quote) external view returns (bool fresh);
}
```

### SwapAdapter

DEX integration:

```solidity
interface ISwapAdapter {
    /// @notice Execute a swap
    /// @param tokenIn Input token
    /// @param tokenOut Output token
    /// @param amountIn Input amount
    /// @param minAmountOut Minimum output
    /// @return amountOut Actual output amount
    function swap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 minAmountOut
    ) external returns (uint256 amountOut);
}
```

---

## Usage Examples

### Creating a Stop-Loss Order

```solidity
import {Order, OrderKind, OrderState, Trigger, Execution} from "./VaultTypes.sol";
import {ISentinelVault} from "./interfaces/ISentinelVault.sol";

// 1. Deposit tokens first
vault.deposit(WETH, 1 ether);

// 2. Create order
Order memory order = Order({
    id: 0,  // Assigned by contract
    owner: msg.sender,
    kind: OrderKind.STOP_LOSS,
    state: OrderState.OPEN,
    trigger: Trigger({
        oracle: chainlinkETHUSD,
        targetPrice: 1800 * 1e18,  // Trigger at $1800
        deadline: block.timestamp + 7 days
    }),
    execution: Execution({
        inputToken: WETH,
        outputToken: USDC,
        inputAmount: 1 ether,
        minOutputAmount: 1750 * 1e6,  // Min $1750 USDC
        slippageBps: 50  // 0.5%
    }),
    createdAt: 0  // Set by contract
});

uint256 orderId = vault.createOrder(order);
```

### Cancelling an Order

```solidity
vault.cancelOrder(orderId);
```

### Executing an Order (Keeper)

```solidity
// Single execution
vault.executeOrder(orderId);

// Batch execution
uint256[] memory orderIds = new uint256[](3);
orderIds[0] = 1;
orderIds[1] = 5;
orderIds[2] = 12;
vault.executeBatch(orderIds);
```

---

## Dependencies

### OpenZeppelin Contracts v5.5.0

- `ReentrancyGuard`: Reentrancy protection
- `Pausable`: Emergency pause
- `Ownable`: Admin access control
- `SafeERC20`: Safe token transfers

### forge-std v1.14.0

- Testing utilities
- Console logging
- Cheatcodes

---

## Development

### Building

```bash
cd contracts
forge build
```

### Testing

```bash
forge test
forge test -vvvv  # Verbose
forge test --match-test testCreateOrder  # Specific test
```

### Gas Report

```bash
forge test --gas-report
```

### Coverage

```bash
forge coverage
```

---

## Deployment

### Local (Anvil)

```bash
# Terminal 1: Start Anvil
anvil

# Terminal 2: Deploy
forge script script/Deploy.s.sol --rpc-url http://localhost:8545 --broadcast
```

### Testnet (Sepolia)

```bash
forge script script/Deploy.s.sol \
    --rpc-url $SEPOLIA_RPC_URL \
    --private-key $PRIVATE_KEY \
    --broadcast \
    --verify
```
