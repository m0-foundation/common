// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.20 <0.9.0;

/// @title  TypeConverter
/// @author M0 Labs
/// @notice Utilities for converting between different data types.
library TypeConverter {
    /// @notice Thrown when a uint256 value exceeds the max uint64 value.
    error Uint64Overflow();
    /// @notice Thrown when a uint256 value exceeds the max uint128 value.
    error Uint128Overflow();

    /// @notice Thrown when a bytes32 value doesn't represent a valid Ethereum address.
    error InvalidAddress(bytes32 value);

    /// @notice Converts a uint256 to uint64, reverting if the value overflows.
    /// @param  value The uint256 value to convert.
    /// @return The uint64 representation of the value.
    function toUint64(uint256 value) internal pure returns (uint64) {
        if (value > type(uint64).max) revert Uint64Overflow();
        return uint64(value);
    }

    /// @notice Converts a uint256 to uint128, reverting if the value overflows.
    /// @param  value The uint256 value to convert.
    /// @return The uint128 representation of the value.
    function toUint128(uint256 value) internal pure returns (uint128) {
        if (value > type(uint128).max) revert Uint128Overflow();
        return uint128(value);
    }

    /// @notice Convert an Ethereum address to bytes32.
    /// @dev    Pads the 20-byte address to 32 bytes by converting to uint160, then uint256, then bytes32.
    /// @param  addressValue The address to convert.
    /// @return The bytes32 representation of the address.
    function toBytes32(address addressValue) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(addressValue)));
    }

    /// @notice Convert bytes32 to an Ethereum address.
    /// @dev    Truncates the 32-byte value to 20 bytes by converting to uint256, then uint160, then address.
    /// @param  bytes32Value The bytes32 value to convert.
    /// @return The address representation of the bytes32 value.
    function toAddress(bytes32 bytes32Value) internal pure returns (address) {
        if (!isValidAddress(bytes32Value)) revert InvalidAddress(bytes32Value);
        return address(uint160(uint256(bytes32Value)));
    }

    /// @notice Check if a bytes32 value represents a valid Ethereum address.
    /// @dev    An Ethereum address must have the top 12 bytes as zero.
    /// @param  bytes32Value The bytes32 value to check.
    /// @return True if the bytes32 value can be safely converted to an Ethereum address.
    function isValidAddress(bytes32 bytes32Value) internal pure returns (bool) {
        // The top 12 bytes must be zero for a valid Ethereum address
        return uint256(bytes32Value) >> 160 == 0;
    }
}
