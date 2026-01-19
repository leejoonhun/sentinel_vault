// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title VaultTypes
 * @notice Common types used across Sentinel Protocol
 * @dev All structs and enums are defined here for consistency
 */

// =============================================================================
// Enums
// =============================================================================

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

// =============================================================================
// Structs
// =============================================================================

/// @notice Trigger conditions for order execution
struct Trigger {
    address oracle; // Price oracle address
    uint256 targetPrice; // Target price (1e18 scale)
    uint256 deadline; // Order expiration timestamp
}

/// @notice Execution parameters for order
struct Execution {
    address inputToken; // Token to sell
    address outputToken; // Token to buy
    uint256 inputAmount; // Amount to sell
    uint256 minOutputAmount; // Minimum amount to receive
    uint16 slippageBps; // Slippage tolerance in basis points (100 = 1%)
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
