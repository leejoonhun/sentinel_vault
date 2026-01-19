// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Order } from "../VaultTypes.sol";

/**
 * @title ISentinelVault
 * @notice Interface for the Sentinel Vault
 * @dev Main entry point for user interactions
 */
interface ISentinelVault {
    // =========================================================================
    // User Functions
    // =========================================================================

    /// @notice Deposit tokens into the vault
    /// @param token Token address to deposit
    /// @param amount Amount to deposit
    function deposit(
        address token,
        uint256 amount
    ) external;

    /// @notice Withdraw tokens from the vault
    /// @param token Token address to withdraw
    /// @param amount Amount to withdraw
    function withdraw(
        address token,
        uint256 amount
    ) external;

    /// @notice Get user's balance of a token
    /// @param user User address
    /// @param token Token address
    /// @return balance User's balance
    function balanceOf(
        address user,
        address token
    ) external view returns (uint256 balance);

    // =========================================================================
    // Order Functions
    // =========================================================================

    /// @notice Create a new order
    /// @param order Order parameters
    /// @return orderId Unique identifier of the created order
    function createOrder(
        Order calldata order
    ) external returns (uint256 orderId);

    /// @notice Cancel an existing order
    /// @param orderId Order identifier
    function cancelOrder(
        uint256 orderId
    ) external;

    /// @notice Get order details
    /// @param orderId Order identifier
    /// @return order Order data
    function getOrder(
        uint256 orderId
    ) external view returns (Order memory order);

    /// @notice Get all order IDs for an owner
    /// @param owner Owner address
    /// @return orderIds Array of order identifiers
    function getOrdersByOwner(
        address owner
    ) external view returns (uint256[] memory orderIds);

    // =========================================================================
    // Execution Functions (Keeper only)
    // =========================================================================

    /// @notice Execute an order (keeper only)
    /// @param orderId Order identifier
    function executeOrder(
        uint256 orderId
    ) external;

    /// @notice Execute multiple orders (keeper only)
    /// @param orderIds Array of order identifiers
    function executeBatch(
        uint256[] calldata orderIds
    ) external;

    // =========================================================================
    // Admin Functions
    // =========================================================================

    /// @notice Add a keeper
    /// @param keeper Keeper address
    function addKeeper(
        address keeper
    ) external;

    /// @notice Remove a keeper
    /// @param keeper Keeper address
    function removeKeeper(
        address keeper
    ) external;

    /// @notice Set an adapter
    /// @param adapterKey Adapter identifier
    /// @param adapter Adapter address
    function setAdapter(
        bytes32 adapterKey,
        address adapter
    ) external;

    /// @notice Pause the vault
    function pause() external;

    /// @notice Unpause the vault
    function unpause() external;

    // =========================================================================
    // View Functions
    // =========================================================================

    /// @notice Check if an address is an authorized keeper
    /// @param keeper Address to check
    /// @return authorized Whether the address is a keeper
    function isKeeper(
        address keeper
    ) external view returns (bool authorized);

    /// @notice Check if the vault is paused
    /// @return paused Whether the vault is paused
    function isPaused() external view returns (bool paused);
}
