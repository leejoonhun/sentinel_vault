// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/SentinelVault.sol";
import "../src/interfaces/ISentinelVault.sol";
import { MockERC20 } from "solmate/test/utils/mocks/MockERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title SentinelVault Test Suite
/// @notice Unit tests for SentinelVault core functionality
contract SentinelVaultTest is Test {
    SentinelVault public vault;
    MockERC20 public token;

    address user = address(0x1);
    address module = address(0x2);

    function setUp() public {
        // Deploy contracts
        vault = new SentinelVault();
        token = new MockERC20("Test Token", "TEST", 18);

        // Setup initial state
        token.mint(user, 100e18);
    }

    // =========================================================================
    // Deposit Tests
    // =========================================================================

    /// @notice User can deposit ERC20 tokens into the vault
    function testDeposit() public {
        // Arrange
        vm.startPrank(user);
        token.approve(address(vault), 10e18);

        // Act
        vault.deposit(address(token), 10e18);

        // Assert
        assertEq(token.balanceOf(address(vault)), 10e18);
        assertEq(token.balanceOf(user), 90e18);

        vm.stopPrank();
    }

    /// @notice Deposit reverts when amount is zero
    function testRevertDepositZeroAmount() public {
        // Arrange & Act & Assert
        vm.expectRevert(ISentinelVault.InvalidAmount.selector);
        vault.deposit(address(token), 0);
    }

    // =========================================================================
    // Withdraw Tests
    // =========================================================================

    /// @notice Owner can withdraw ERC20 tokens from the vault
    function testWithdraw() public {
        // Arrange: User deposits tokens first
        vm.startPrank(user);
        token.approve(address(vault), 50e18);
        vault.deposit(address(token), 50e18);
        vm.stopPrank();

        // Act: Owner withdraws
        vault.withdraw(address(token), 50e18);

        // Assert
        assertEq(token.balanceOf(address(this)), 50e18);
        assertEq(token.balanceOf(address(vault)), 0);
    }

    /// @notice Withdraw reverts when amount is zero
    function testRevertWithdrawZeroAmount() public {
        // Arrange & Act & Assert
        vm.expectRevert(ISentinelVault.InvalidAmount.selector);
        vault.withdraw(address(token), 0);
    }

    // =========================================================================
    // Module Tests
    // =========================================================================

    /// @notice Owner can authorize and deauthorize modules
    function testSetModule() public {
        // Act: Authorize module
        vault.setModule(module, true);

        // Assert
        assertTrue(vault.isModule(module));

        // Act: Deauthorize module
        vault.setModule(module, false);

        // Assert
        assertFalse(vault.isModule(module));
    }

    /// @notice Authorized module can invoke external calls through vault
    function testInvokeAsModule() public {
        // Arrange: Authorize module and deposit tokens
        vault.setModule(module, true);

        vm.startPrank(user);
        token.approve(address(vault), 10e18);
        vault.deposit(address(token), 10e18);
        vm.stopPrank();

        // Act: Module executes token transfer
        bytes memory data = abi.encodeWithSelector(IERC20.transfer.selector, user, 5e18);
        vm.prank(module);
        vault.invoke(address(token), 0, data);

        // Assert
        assertEq(token.balanceOf(address(vault)), 5e18);
        assertEq(token.balanceOf(user), 95e18);
    }

    /// @notice Invoke reverts when caller is not authorized module
    function testRevertInvokeUnauthorized() public {
        // Arrange & Act & Assert
        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(ISentinelVault.UnauthorizedModule.selector, user));
        vault.invoke(address(token), 0, "");
    }

    // =========================================================================
    // ETH Handling Tests
    // =========================================================================

    /// @notice Vault can receive ETH via receive() function
    function testReceiveETH() public {
        // Arrange
        vm.deal(user, 1 ether);

        // Act
        vm.prank(user);
        (bool success,) = address(vault).call{ value: 1 ether }("");

        // Assert
        assertTrue(success);
        assertEq(address(vault).balance, 1 ether);
    }
}
