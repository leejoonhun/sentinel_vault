// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ISentinelVault} from "../interfaces/ISentinelVault.sol";
import {ISentinelTypes} from "../interfaces/ISentinelTypes.sol";

/// @title Oracle Interface
/// @notice Simplified oracle interface for price feeds
/// @dev Production should use Chainlink or Pyth
interface IOracle {
    function getPrice(address token) external view returns (uint256);
}

/// @title Order Module
/// @notice Manages conditional orders (stop-loss, take-profit, TWAP)
/// @dev Executes trades via Vault.invoke when conditions are met
contract OrderModule is Ownable, ISentinelTypes {
    // =========================================================================
    // State Variables
    // =========================================================================

    /// @notice Reference to the parent vault contract
    ISentinelVault public immutable VAULT;

    /// @notice Oracle for price verification
    IOracle public oracle;

    /// @notice Counter for generating unique order IDs
    uint256 public nextOrderId;

    /// @notice Mapping from order ID to order data
    mapping(uint256 => Order) public orders;

    // =========================================================================
    // Events
    // =========================================================================

    /// @notice Emitted when a new order is created
    event OrderCreated(uint256 indexed orderId, address indexed owner, OrderType orderType);

    /// @notice Emitted when an order is cancelled
    event OrderCancelled(uint256 indexed orderId);

    /// @notice Emitted when an order is executed
    event OrderExecuted(uint256 indexed orderId, address indexed keeper);

    // =========================================================================
    // Errors
    // =========================================================================

    /// @notice Order is not in ACTIVE state
    error OrderNotActive();

    /// @notice Caller is not authorized for this action
    error Unauthorized();

    /// @notice Price condition not satisfied
    error ConditionNotMet(uint256 currentPrice, uint256 targetPrice);

    /// @notice Output amount below minimum after slippage
    error SlippageExceeded();

    /// @notice Invalid order parameters
    error InvalidQuantity();

    // =========================================================================
    // Constructor
    // =========================================================================

    /// @notice Initialize the order module
    /// @param _vault Address of the parent vault
    /// @param _oracle Address of the price oracle
    constructor(address _vault, address _oracle) Ownable(msg.sender) {
        VAULT = ISentinelVault(_vault);
        oracle = IOracle(_oracle);
    }

    // =========================================================================
    // User Actions
    // =========================================================================

    /// @notice Create a new conditional order
    /// @dev Assets must already be deposited in the vault
    /// @param _inputToken Token to sell
    /// @param _outputToken Token to receive
    /// @param _inputQuantity Amount of input token to sell
    /// @param _targetPrice Trigger price (1e18 scale)
    /// @param _orderType Type of conditional order
    /// @return orderId The unique identifier for the created order
    function createOrder(
        address _inputToken,
        address _outputToken,
        uint256 _inputQuantity,
        uint256 _targetPrice,
        OrderType _orderType
    ) external returns (uint256) {
        if (_inputQuantity == 0) revert InvalidQuantity();

        uint256 orderId = nextOrderId++;

        orders[orderId] = Order({
            id: orderId,
            owner: msg.sender,
            inputToken: _inputToken,
            outputToken: _outputToken,
            inputQuantity: _inputQuantity,
            targetPrice: _targetPrice,
            orderType: _orderType,
            status: OrderStatus.ACTIVE
        });

        emit OrderCreated(orderId, msg.sender, _orderType);
        return orderId;
    }

    /// @notice Cancel an existing order
    /// @param _orderId ID of the order to cancel
    function cancelOrder(uint256 _orderId) external {
        Order storage order = orders[_orderId];

        if (order.owner != msg.sender && msg.sender != owner()) {
            revert Unauthorized();
        }
        if (order.status != OrderStatus.ACTIVE) revert OrderNotActive();

        order.status = OrderStatus.CANCELLED;
        emit OrderCancelled(_orderId);
    }

    // =========================================================================
    // Keeper Actions
    // =========================================================================

    /// @notice Execute an order when conditions are met
    /// @dev Called by keepers with valid swap data
    /// @param _orderId ID of the order to execute
    /// @param _target Address of the swap router/adapter
    /// @param _swapData Encoded swap calldata for the target
    function executeOrder(uint256 _orderId, address _target, bytes calldata _swapData) external {
        Order storage order = orders[_orderId];

        // 1. Validate order state
        if (order.status != OrderStatus.ACTIVE) revert OrderNotActive();

        // 2. Verify price condition via oracle
        uint256 currentPrice = oracle.getPrice(order.inputToken);
        _validateCondition(order, currentPrice);

        // 3. Update state (prevents reentrancy and double execution)
        order.status = OrderStatus.EXECUTED;

        // 4. Execute swap via vault
        VAULT.invoke(_target, 0, _swapData);

        // 5. Optional: verify output balance increased
        // if (IERC20(output).balanceOf(vault) < expected) revert SlippageExceeded();

        emit OrderExecuted(_orderId, msg.sender);
    }

    // =========================================================================
    // Internal Functions
    // =========================================================================

    /// @notice Validate that price conditions are met for execution
    /// @param order The order to validate
    /// @param currentPrice Current price from oracle
    function _validateCondition(Order memory order, uint256 currentPrice) internal pure {
        if (order.orderType == OrderType.STOP_LOSS) {
            // Stop Loss: triggers when price <= target
            if (currentPrice > order.targetPrice) {
                revert ConditionNotMet(currentPrice, order.targetPrice);
            }
        } else if (order.orderType == OrderType.TAKE_PROFIT) {
            // Take Profit: triggers when price >= target
            if (currentPrice < order.targetPrice) {
                revert ConditionNotMet(currentPrice, order.targetPrice);
            }
        }
        // TWAP orders have different validation logic (time-based)
    }

    // =========================================================================
    // Admin Functions
    // =========================================================================

    /// @notice Update the oracle address
    /// @param _oracle New oracle address
    function setOracle(address _oracle) external onlyOwner {
        oracle = IOracle(_oracle);
    }
}
