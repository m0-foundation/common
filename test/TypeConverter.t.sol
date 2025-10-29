// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { Test } from "../lib/forge-std/src/Test.sol";

import { TypeConverter } from "../src/libs/TypeConverter.sol";

contract TypeConverterTest is Test {
    ///////////////////////////////////////////////////////////////////////////
    //                                toUint64                               //
    ///////////////////////////////////////////////////////////////////////////

    function test_toUint64_basic() external pure {
        uint256 value = 100;
        uint64 result = TypeConverter.toUint64(value);
        assertEq(result, uint64(100));
    }

    function test_toUint64_maxUint64() external pure {
        uint256 value = type(uint64).max;
        uint64 result = TypeConverter.toUint64(value);
        assertEq(result, type(uint64).max);
    }

    function test_toUint64_zero() external pure {
        uint256 value = 0;
        uint64 result = TypeConverter.toUint64(value);
        assertEq(result, 0);
    }

    function testFuzz_toUint64(uint64 value) external pure {
        uint256 uint256Value = uint256(value);
        uint64 result = TypeConverter.toUint64(uint256Value);
        assertEq(result, value);
    }

    /// forge-config: default.allow_internal_expect_revert = true
    function test_toUint64_overflow() external {
        uint256 value = uint256(type(uint64).max) + 1;
        vm.expectRevert(TypeConverter.Uint64Overflow.selector);
        TypeConverter.toUint64(value);
    }

    /// forge-config: default.allow_internal_expect_revert = true
    function testFuzz_toUint64_overflow(uint256 value) external {
        vm.assume(value > type(uint64).max);
        vm.expectRevert(TypeConverter.Uint64Overflow.selector);
        TypeConverter.toUint64(value);
    }

    ///////////////////////////////////////////////////////////////////////////
    //                                toUint128                              //
    ///////////////////////////////////////////////////////////////////////////

    function test_toUint128_basic() external pure {
        uint256 value = 100;
        uint128 result = TypeConverter.toUint128(value);
        assertEq(result, uint128(100));
    }

    function test_toUint128_maxUint128() external pure {
        uint256 value = type(uint128).max;
        uint128 result = TypeConverter.toUint128(value);
        assertEq(result, type(uint128).max);
    }

    function test_toUint128_zero() external pure {
        uint256 value = 0;
        uint128 result = TypeConverter.toUint128(value);
        assertEq(result, 0);
    }

    function testFuzz_toUint128(uint128 value) external pure {
        uint256 uint256Value = uint256(value);
        uint128 result = TypeConverter.toUint128(uint256Value);
        assertEq(result, value);
    }

    /// forge-config: default.allow_internal_expect_revert = true
    function test_toUint128_overflow() external {
        uint256 value = uint256(type(uint128).max) + 1;
        vm.expectRevert(TypeConverter.Uint128Overflow.selector);
        TypeConverter.toUint128(value);
    }

    /// forge-config: default.allow_internal_expect_revert = true
    function testFuzz_toUint128_overflow(uint256 value) external {
        vm.assume(value > type(uint128).max);
        vm.expectRevert(TypeConverter.Uint128Overflow.selector);
        TypeConverter.toUint128(value);
    }

    ///////////////////////////////////////////////////////////////////////////
    //                               toBytes32                               //
    ///////////////////////////////////////////////////////////////////////////

    function test_toBytes32_basic() external pure {
        address addressValue = address(0x1234567890123456789012345678901234567890);
        bytes32 actual = TypeConverter.toBytes32(addressValue);
        bytes32 expected = bytes32(uint256(uint160(addressValue)));
        assertEq(actual, expected);
    }

    function test_toBytes32_zeroAddress() external pure {
        address addressValue = address(0);
        bytes32 actual = TypeConverter.toBytes32(addressValue);
        assertEq(actual, bytes32(0));
    }

    function test_toBytes32_maxAddress() external pure {
        address addressValue = address(uint160(type(uint160).max));
        bytes32 actual = TypeConverter.toBytes32(addressValue);
        bytes32 expected = bytes32(uint256(type(uint160).max));
        assertEq(actual, expected);
    }

    function testFuzz_toBytes32(address addressValue) external pure {
        bytes32 actual = TypeConverter.toBytes32(addressValue);
        bytes32 expected = bytes32(uint256(uint160(addressValue)));
        assertEq(actual, expected);
    }

    ///////////////////////////////////////////////////////////////////////////
    //                                toAddress                              //
    ///////////////////////////////////////////////////////////////////////////

    function test_toAddress_basic() external pure {
        address expected = address(0x1234567890123456789012345678901234567890);
        bytes32 bytes32Value = bytes32(uint256(uint160(expected)));
        address actual = TypeConverter.toAddress(bytes32Value);
        assertEq(actual, expected);
    }

    function test_toAddress_zeroAddress() external pure {
        bytes32 bytes32Value = bytes32(0);
        assertEq(TypeConverter.toAddress(bytes32Value), address(0));
    }

    function testFuzz_toAddress_valid(address addressValue) external pure {
        bytes32 value = bytes32(uint256(uint160(addressValue)));
        address actual = TypeConverter.toAddress(value);
        assertEq(actual, addressValue);
    }

    /// forge-config: default.allow_internal_expect_revert = true
    function test_toAddress_invalidAddress_topBytesNotZero() external {
        // Create a bytes32 value where the top 12 bytes are not zero (invalid address)
        bytes32 bytes32Value = bytes32(uint256(1) << 160); // Set a bit in the top 12 bytes
        vm.expectRevert(abi.encodeWithSelector(TypeConverter.InvalidAddress.selector, bytes32Value));
        TypeConverter.toAddress(bytes32Value);
    }

    ///////////////////////////////////////////////////////////////////////////
    //                             isValidAddress                            //
    ///////////////////////////////////////////////////////////////////////////

    function test_isValidAddress_valid() external pure {
        address validAddress = address(0x1234567890123456789012345678901234567890);
        bytes32 bytes32Value = bytes32(uint256(uint160(validAddress)));
        assertTrue(TypeConverter.isValidAddress(bytes32Value));
    }

    function test_isValidAddress_zeroAddress() external pure {
        bytes32 bytes32Value = bytes32(0);
        assertTrue(TypeConverter.isValidAddress(bytes32Value));
    }

    function test_isValidAddress_maxAddress() external pure {
        bytes32 bytes32Value = bytes32(uint256(type(uint160).max));
        assertTrue(TypeConverter.isValidAddress(bytes32Value));
    }

    function testFuzz_isValidAddress_valid(address validAddress) external pure {
        bytes32 bytes32Value = bytes32(uint256(uint160(validAddress)));
        assertTrue(TypeConverter.isValidAddress(bytes32Value));
    }

    function test_isValidAddress_invalidTopBitSet() external pure {
        bytes32 bytes32Value = bytes32(uint256(1) << 160);
        assertFalse(TypeConverter.isValidAddress(bytes32Value));
    }

    function testFuzz_isValidAddress_invalid(uint96 topBits) external pure {
        vm.assume(topBits != 0);
        bytes32 bytes32Value = bytes32((uint256(topBits) << 160) | uint256(uint160(address(0x1234567890123456789012345678901234567890))));
        assertFalse(TypeConverter.isValidAddress(bytes32Value));
    }
}
