// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Order } from "../VaultTypes.sol";

/**
 * @title ISentinelVault
 * @notice Interface for the Sentinel Vault
 * @dev Main entry point for user interactions
 */
interface ISentinelVault {
    // Events
    event Deposit(address indexed token, address indexed from, uint256 amount);
    event Withdraw(address indexed token, address indexed to, uint256 amount);
    event ModuleSet(address indexed module, bool isAuthorized);
    event Executed(address indexed module, address indexed target, uint256 value, bytes data);

    // Errors
    // NOTE: Using custom errors for gas efficiency (vs require strings)
    error UnauthorizedModule(address caller);
    error TargetCallFailed(address target, bytes returnData);
    error InvalidAmount();
}
