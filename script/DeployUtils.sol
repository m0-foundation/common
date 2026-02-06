// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.20 <0.9.0;

/// @notice Shared deployment constants for M^0 protocol repos.
abstract contract DeployUtils {
    /// @dev Same address for all EVM chains.
    address internal constant _SWAP_FACILITY = 0xB6807116b3B1B321a390594e31ECD6e0076f6278;
}
