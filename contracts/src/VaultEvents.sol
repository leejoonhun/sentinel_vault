// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { OrderKind } from "./VaultTypes.sol";

/**
 * @title VaultEvents
 * @notice Events emitted by Sentinel Protocol
 * @dev All events use indexed parameters for efficient filtering
 */

// =============================================================================
// Order Lifecycle Events
// =============================================================================

/// @notice Emitted when a new order is created
/// @param orderId Unique identifier of the order
/// @param owner Address that created the order
/// @param kind Type of order (STOP_LOSS, TAKE_PROFIT, TWAP)
event OrderCreated(uint256 indexed orderId, address indexed owner, OrderKind kind);

/// @notice Emitted when an order is updated
/// @param orderId Unique identifier of the order
event OrderUpdated(uint256 indexed orderId);

/// @notice Emitted when an order is cancelled by owner
/// @param orderId Unique identifier of the order
event OrderCancelled(uint256 indexed orderId);

/// @notice Emitted when an order is successfully executed
/// @param orderId Unique identifier of the order
/// @param keeper Address of the keeper that executed the order
/// @param amountIn Amount of input tokens spent
/// @param amountOut Amount of output tokens received
event OrderExecuted(
    uint256 indexed orderId, address indexed keeper, uint256 amountIn, uint256 amountOut
);

/// @notice Emitted when an order expires
/// @param orderId Unique identifier of the order
event OrderExpired(uint256 indexed orderId);

// =============================================================================
// Vault Events
// =============================================================================

/// @notice Emitted when tokens are deposited
/// @param user Address that deposited
/// @param token Token address
/// @param amount Amount deposited
event Deposit(address indexed user, address indexed token, uint256 amount);

/// @notice Emitted when tokens are withdrawn
/// @param user Address that withdrew
/// @param token Token address
/// @param amount Amount withdrawn
event Withdraw(address indexed user, address indexed token, uint256 amount);

// =============================================================================
// Admin Events
// =============================================================================

/// @notice Emitted when a keeper is authorized or deauthorized
/// @param keeper Address of the keeper
/// @param allowed Whether the keeper is now authorized
event KeeperAuthorized(address indexed keeper, bool allowed);

/// @notice Emitted when an adapter is configured
/// @param adapterKey Unique key identifying the adapter type
/// @param adapter Address of the adapter contract
event AdapterSet(bytes32 indexed adapterKey, address adapter);

/// @notice Emitted when a module is added
/// @param module Address of the module
event ModuleAdded(address indexed module);

/// @notice Emitted when a module is removed
/// @param module Address of the module
event ModuleRemoved(address indexed module);

/// @notice Emitted when the vault is paused
/// @param by Address that triggered the pause
event Paused(address indexed by);

/// @notice Emitted when the vault is unpaused
/// @param by Address that triggered the unpause
event Unpaused(address indexed by);
