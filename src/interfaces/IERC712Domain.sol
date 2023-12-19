// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.23;

/// @title EIP-712 domain separator.
/// @dev   The domain separator as defined by EIP-712: https://eips.ethereum.org/EIPS/eip-712
interface IERC712Domain {
    /// @notice Returns the EIP712 domain separator used in the encoding of a signed digest.
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}
