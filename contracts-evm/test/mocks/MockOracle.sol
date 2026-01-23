// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title Mock Oracle
/// @notice Mock price oracle for testing
/// @dev Returns manually set prices for tokens
contract MockOracle {
    mapping(address => uint256) public prices;

    /// @notice Set the price for a token
    /// @param token Token address
    /// @param price Price in 1e18 scale
    function setPrice(address token, uint256 price) external {
        prices[token] = price;
    }

    /// @notice Get the price for a token
    /// @param token Token address
    /// @return Price in 1e18 scale
    function getPrice(address token) external view returns (uint256) {
        return prices[token];
    }
}
