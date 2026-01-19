// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ISentinelVault} from "./interfaces/ISentinelVault.sol";

/// @title Sentinel Vault
/// @notice Core contract that holds assets and executes logic of authorized modules
/// @dev Hub & Spoke architecture's Hub role
contract SentinelVault is Ownable, ReentrancyGuard, ISentinelVault {
    using SafeERC20 for IERC20;

    // =========================================================================
    // State Variables
    // =========================================================================

    /// @notice Mapping of authorized strategy modules
    mapping(address => bool) public isModule;

    // =========================================================================
    // Modifiers
    // =========================================================================

    /// @notice Restricts function access to authorized modules only
    modifier onlyModule() {
        if (!isModule[msg.sender]) {
            revert UnauthorizedModule(msg.sender);
        }
        _;
    }

    // =========================================================================
    // Constructor
    // =========================================================================

    constructor() Ownable(msg.sender) {}

    // =========================================================================
    // Governance Functions (Owner)
    // =========================================================================

    /// @notice Adds or removes a strategy module
    /// @param _module The module address to configure
    /// @param _status True to authorize, false to revoke
    function setModule(address _module, bool _status) external onlyOwner {
        isModule[_module] = _status;
        emit ModuleSet(_module, _status);
    }

    /// @notice Withdraws funds in case of emergency or to realize profits
    /// @param _token The token address to withdraw
    /// @param _amount The amount to withdraw
    function withdraw(address _token, uint256 _amount) external onlyOwner nonReentrant {
        if (_amount == 0) revert InvalidAmount();
        IERC20(_token).safeTransfer(msg.sender, _amount);
        emit Withdraw(_token, msg.sender, _amount);
    }

    // =========================================================================
    // Core Logic (Module)
    // =========================================================================

    /// @notice Executes an external call on behalf of the vault
    /// @dev Only authorized modules can call this function
    /// @param _target The target contract address
    /// @param _value The ETH value to send
    /// @param _data The calldata to execute
    /// @return result The return data from the call
    function invoke(address _target, uint256 _value, bytes calldata _data)
        external
        onlyModule
        nonReentrant
        returns (bytes memory result)
    {
        (bool success, bytes memory returnData) = _target.call{value: _value}(_data);

        if (!success) {
            revert TargetCallFailed(_target, returnData);
        }

        emit Executed(msg.sender, _target, _value, _data);
        return returnData;
    }

    // =========================================================================
    // Public Functions
    // =========================================================================

    /// @notice Deposits ERC20 tokens into the vault
    /// @param _token The token address to deposit
    /// @param _amount The amount to deposit
    function deposit(address _token, uint256 _amount) external {
        if (_amount == 0) revert InvalidAmount();
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        emit Deposit(_token, msg.sender, _amount);
    }

    /// @notice Receives ETH deposits
    receive() external payable {
        emit Deposit(address(0), msg.sender, msg.value);
    }
}
