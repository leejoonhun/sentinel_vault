// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title VaultErrors
 * @notice Custom errors for Sentinel Protocol
 * @dev Using custom errors for gas efficiency (vs require strings)
 */

// =============================================================================
// Authorization Errors
// =============================================================================

/// @notice Caller is not the order owner
error NotOrderOwner();

/// @notice Caller is not an authorized keeper
error UnauthorizedKeeper();

/// @notice Signature verification failed
error InvalidSignature();

/// @notice Caller is not authorized for this action
error Unauthorized();

// =============================================================================
// Order State Errors
// =============================================================================

/// @notice Order is not in OPEN state
error OrderNotOpen();

/// @notice Order has already expired
error OrderExpired();

/// @notice Order has already been executed
error OrderAlreadyExecuted();

/// @notice Order does not exist
error OrderNotFound();

// =============================================================================
// Execution Errors
// =============================================================================

/// @notice Trigger conditions are not satisfied
error TriggerNotSatisfied();

/// @notice Slippage exceeds allowed tolerance
error SlippageTooHigh();

/// @notice User has insufficient balance
error InsufficientBalance();

/// @notice Token transfer failed
error TransferFailed();

/// @notice Swap execution failed
error SwapFailed();

// =============================================================================
// Configuration Errors
// =============================================================================

/// @notice Required adapter is not configured
error AdapterNotSet();

/// @notice Address cannot be zero
error ZeroAddress();

/// @notice Amount cannot be zero
error ZeroAmount();

/// @notice Deadline is invalid or in the past
error InvalidDeadline();

/// @notice Slippage exceeds maximum allowed
error SlippageExceedsMax();

// =============================================================================
// System Errors
// =============================================================================

/// @notice Contract is paused
error VaultPaused();

/// @notice Reentrancy detected
error ReentrancyGuard();

/// @notice Module is not whitelisted
error ModuleNotWhitelisted();
