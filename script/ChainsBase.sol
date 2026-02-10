// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.20 <0.9.0;

/// @notice Common EVM chain IDs shared across M0 protocol repos.
library ChainsBase {
    // Mainnet
    uint256 internal constant ETHEREUM = 1;

    // Testnet
    uint256 internal constant ETHEREUM_SEPOLIA = 11155111;

    function isHub(uint256 chainId_) internal pure returns (bool) {
        return chainId_ == ETHEREUM || chainId_ == ETHEREUM_SEPOLIA;
    }
}
