// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {SentinelVault} from "../src/SentinelVault.sol";
import {OrderModule} from "../src/modules/OrderModule.sol";
import {MockOracle} from "./mocks/MockOracle.sol";
import {MockERC20} from "solmate/src/test/utils/mocks/MockERC20.sol";
import {ISentinelTypes} from "../src/interfaces/ISentinelTypes.sol";

/// @title OrderModule Test Suite
/// @notice Unit tests for OrderModule functionality
contract OrderModuleTest is Test {
    SentinelVault public vault;
    OrderModule public orderModule;
    MockOracle public oracle;
    MockERC20 public token;

    address user = address(0x1);
    address keeper = address(0x2);
    address target = address(0x3);

    function setUp() public {
        // Deploy contracts
        vault = new SentinelVault();
        oracle = new MockOracle();
        orderModule = new OrderModule(address(vault), address(oracle));
        token = new MockERC20("Test Token", "TEST", 18);

        // Authorize OrderModule as a trusted module
        vault.setModule(address(orderModule), true);

        // Fund user and deposit to vault
        token.mint(user, 100e18);

        vm.startPrank(user);
        token.approve(address(vault), 100e18);
        vault.deposit(address(token), 10e18);
        vm.stopPrank();
    }

    // =========================================================================
    // Order Creation Tests
    // =========================================================================

    /// @notice User can create a stop-loss order
    function testCreateOrder() public {
        vm.startPrank(user);
        uint256 orderId =
            orderModule.createOrder(address(token), address(0), 1e18, 2000e18, ISentinelTypes.OrderType.STOP_LOSS);
        vm.stopPrank();

        // Verify order was stored correctly
        (uint256 id, address owner,,,,,,) = orderModule.orders(orderId);
        assertEq(id, 0);
        assertEq(owner, user);
    }

    // =========================================================================
    // Order Execution Tests
    // =========================================================================

    /// @notice Stop-loss order executes when price drops below target
    function testExecuteStopLoss() public {
        // Create order
        vm.startPrank(user);
        uint256 orderId =
            orderModule.createOrder(address(token), address(0), 1e18, 2000e18, ISentinelTypes.OrderType.STOP_LOSS);
        vm.stopPrank();

        // Set price above target (safe zone)
        oracle.setPrice(address(token), 2100e18);

        // Execution should fail when price is above target
        vm.prank(keeper);
        vm.expectRevert(abi.encodeWithSelector(OrderModule.ConditionNotMet.selector, 2100e18, 2000e18));
        orderModule.executeOrder(orderId, target, "");

        // Price drops below target (trigger zone)
        oracle.setPrice(address(token), 1900e18);

        // Execution should succeed
        vm.prank(keeper);
        orderModule.executeOrder(orderId, target, hex"1234");

        // Verify order status changed to EXECUTED
        (,,,,,,, ISentinelTypes.OrderStatus status) = orderModule.orders(orderId);
        assertEq(uint256(status), uint256(ISentinelTypes.OrderStatus.EXECUTED));
    }

    // =========================================================================
    // Order Cancellation Tests
    // =========================================================================

    /// @notice User can cancel their own order
    function testCancelOrder() public {
        vm.startPrank(user);
        uint256 orderId =
            orderModule.createOrder(address(token), address(0), 1e18, 2000e18, ISentinelTypes.OrderType.STOP_LOSS);

        orderModule.cancelOrder(orderId);

        (,,,,,,, ISentinelTypes.OrderStatus status) = orderModule.orders(orderId);
        assertEq(uint256(status), uint256(ISentinelTypes.OrderStatus.CANCELLED));
        vm.stopPrank();
    }
}
