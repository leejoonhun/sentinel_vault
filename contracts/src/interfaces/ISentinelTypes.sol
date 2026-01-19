// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title Sentinel Types Interface
/// @notice Type definitions shared across Sentinel Protocol
/// @dev Used by modules and external integrations
interface ISentinelTypes {
    // =========================================================================
    // Enums
    // =========================================================================

    /// @notice Order type enumeration
    enum OrderType {
        STOP_LOSS,
        TAKE_PROFIT,
        TWAP
    }

    /// @notice Order status enumeration
    enum OrderStatus {
        ACTIVE, // Awaiting execution
        EXECUTED, // Successfully executed
        CANCELLED // Cancelled by owner
    }

    // =========================================================================
    // Structs
    // =========================================================================

    /// @notice Order data structure
    /// @param id Unique order identifier
    /// @param owner Address that created the order
    /// @param inputToken Token to sell
    /// @param outputToken Token to receive
    /// @param inputQuantity Amount to sell
    /// @param targetPrice Trigger price (1e18 scale)
    /// @param orderType Type of order
    /// @param status Current order status
    struct Order {
        uint256 id;
        address owner;
        address inputToken;
        address outputToken;
        uint256 inputQuantity;
        uint256 targetPrice;
        OrderType orderType;
        OrderStatus status;
    }
}
