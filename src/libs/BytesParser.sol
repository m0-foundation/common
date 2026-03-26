// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.20 <0.9.0;

/// @title  BytesParser
/// @author Wormhole Labs
/// @notice Parses tightly packed data.
/// @dev    Modified from
///         https://github.com/wormhole-foundation/wormhole-solidity-sdk/blob/main/src/libraries/BytesParsing.sol
library BytesParser {
    error LengthMismatch(uint256 encodedLength, uint256 expectedLength);
    error InvalidBool(uint8 value);

    /// @notice Reverts if the encoded byte array length does not match the expected length.
    /// @param  encoded  The byte array to check.
    /// @param  expected The expected length.
    function checkLength(bytes memory encoded, uint256 expected) internal pure {
        if (encoded.length != expected) revert LengthMismatch(encoded.length, expected);
    }

    /// @notice Reads a uint8 from `encoded` at the given byte `offset` without bounds checking.
    /// @param  encoded    The byte array to read from.
    /// @param  offset     The byte offset to start reading from.
    /// @return value      The decoded uint8 value.
    /// @return nextOffset The offset immediately after the read bytes.
    function asUint8Unchecked(
        bytes memory encoded,
        uint256 offset
    ) internal pure returns (uint8 value, uint256 nextOffset) {
        assembly ("memory-safe") {
            nextOffset := add(offset, 1)
            value := mload(add(encoded, nextOffset))
        }
    }

    /// @notice Reads a bool from `encoded` at the given byte `offset` without bounds checking.
    /// @dev    Reverts with `InvalidBool` if the underlying uint8 is not 0 or 1.
    /// @param  encoded    The byte array to read from.
    /// @param  offset     The byte offset to start reading from.
    /// @return value      The decoded bool value.
    /// @return nextOffset The offset immediately after the read bytes.
    function asBoolUnchecked(
        bytes memory encoded,
        uint256 offset
    ) internal pure returns (bool value, uint256 nextOffset) {
        uint8 uint8Value;
        (uint8Value, nextOffset) = asUint8Unchecked(encoded, offset);

        if (uint8Value & 0xfe != 0) revert InvalidBool(uint8Value);

        uint256 cleanedValue = uint256(uint8Value);
        // skip 2x iszero opcode
        assembly ("memory-safe") {
            value := cleanedValue
        }
    }

    /// @notice Reads a uint256 from `encoded` at the given byte `offset` without bounds checking.
    /// @param  encoded    The byte array to read from.
    /// @param  offset     The byte offset to start reading from.
    /// @return value      The decoded uint256 value.
    /// @return nextOffset The offset immediately after the read bytes.
    function asUint256Unchecked(
        bytes memory encoded,
        uint256 offset
    ) internal pure returns (uint256 value, uint256 nextOffset) {
        assembly ("memory-safe") {
            nextOffset := add(offset, 32)
            value := mload(add(encoded, nextOffset))
        }
    }

    /// @notice Reads a uint128 from `encoded` at the given byte `offset` without bounds checking.
    /// @param  encoded    The byte array to read from.
    /// @param  offset     The byte offset to start reading from.
    /// @return value      The decoded uint128 value.
    /// @return nextOffset The offset immediately after the read bytes.
    function asUint128Unchecked(
        bytes memory encoded,
        uint256 offset
    ) internal pure returns (uint128 value, uint256 nextOffset) {
        assembly ("memory-safe") {
            nextOffset := add(offset, 16)
            value := mload(add(encoded, nextOffset))
        }
    }

    /// @notice Reads a uint32 from `encoded` at the given byte `offset` without bounds checking.
    /// @param  encoded    The byte array to read from.
    /// @param  offset     The byte offset to start reading from.
    /// @return value      The decoded uint32 value.
    /// @return nextOffset The offset immediately after the read bytes.
    function asUint32Unchecked(
        bytes memory encoded,
        uint256 offset
    ) internal pure returns (uint32 value, uint256 nextOffset) {
        assembly ("memory-safe") {
            nextOffset := add(offset, 4)
            value := mload(add(encoded, nextOffset))
        }
    }

    /// @notice Reads a bytes32 from `encoded` at the given byte `offset` without bounds checking.
    /// @param  encoded    The byte array to read from.
    /// @param  offset     The byte offset to start reading from.
    /// @return value      The decoded bytes32 value.
    /// @return nextOffset The offset immediately after the read bytes.
    function asBytes32Unchecked(
        bytes memory encoded,
        uint256 offset
    ) internal pure returns (bytes32 value, uint256 nextOffset) {
        uint256 uint256Value;
        (uint256Value, nextOffset) = asUint256Unchecked(encoded, offset);
        value = bytes32(uint256Value);
    }

    /// @notice Reads an address from `encoded` at the given byte `offset` without bounds checking.
    /// @param  encoded    The byte array to read from.
    /// @param  offset     The byte offset to start reading from.
    /// @return value      The decoded address value.
    /// @return nextOffset The offset immediately after the read bytes.
    function asAddressUnchecked(
        bytes memory encoded,
        uint256 offset
    ) internal pure returns (address value, uint256 nextOffset) {
        assembly ("memory-safe") {
            nextOffset := add(offset, 20)
            value := mload(add(encoded, nextOffset))
        }
    }
}
