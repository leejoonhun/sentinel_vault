// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title Sentinel Vault Interface
/// @notice Interface for the Sentinel Vault
/// @dev Main entry point for user interactions
interface ISentinelVault {
    // =========================================================================
    // Events
    // =========================================================================

    /// @notice Emitted when tokens are deposited into the vault
    /// @param token The token address (address(0) for ETH)
    /// @param from The depositor address
    /// @param amount The amount deposited
    event Deposit(address indexed token, address indexed from, uint256 amount);

    /// @notice Emitted when tokens are withdrawn from the vault
    /// @param token The token address
    /// @param to The recipient address
    /// @param amount The amount withdrawn
    event Withdraw(address indexed token, address indexed to, uint256 amount);

    /// @notice Emitted when a module's authorization status changes
    /// @param module The module address
    /// @param isAuthorized Whether the module is authorized
    event ModuleSet(address indexed module, bool isAuthorized);

    /// @notice Emitted when a module executes an external call
    /// @param module The module that initiated the call
    /// @param target The target contract address
    /// @param value The ETH value sent
    /// @param data The calldata
    event Executed(address indexed module, address indexed target, uint256 value, bytes data);

    // =========================================================================
    // Errors
    // =========================================================================

    /// @notice Thrown when caller is not an authorized module
    /// @param caller The unauthorized caller address
    error UnauthorizedModule(address caller);

    /// @notice Thrown when an external call fails
    /// @param target The target contract that failed
    /// @param returnData The revert data from the failed call
    error TargetCallFailed(address target, bytes returnData);

    /// @notice Thrown when amount is zero or invalid
    error InvalidAmount();

    // =========================================================================
    // External Functions
    // =========================================================================

    /// @notice Deposit tokens into the vault
    /// @param token The token address
    /// @param amount The amount to deposit
    function deposit(address token, uint256 amount) external;

    /// @notice Withdraw tokens from the vault
    /// @param token The token address
    /// @param amount The amount to withdraw
    function withdraw(address token, uint256 amount) external;

    /// @notice Execute an arbitrary call on behalf of the vault
    /// @dev Only callable by authorized modules
    /// @param target Target contract address
    /// @param value ETH value to send
    /// @param data Calldata to execute
    /// @return result Return data from the call
    function invoke(address target, uint256 value, bytes calldata data) external returns (bytes memory result);

    /// @notice Set module authorization status
    /// @param module Module address
    /// @param isAuthorized Authorization status
    function setModule(address module, bool isAuthorized) external;

    /// @notice Check if an address is an authorized module
    /// @param module Module address to check
    /// @return Whether the module is authorized
    function isModule(address module) external view returns (bool);
}
