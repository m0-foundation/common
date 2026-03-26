// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";

import { BytesParser } from "../src/libs/BytesParser.sol";

contract BytesParserTest is Test {
    using BytesParser for bytes;

    function test_asUint8Unchecked() external pure {
        bytes memory data = hex"0203";

        (uint8 value, uint256 nextOffset) = data.asUint8Unchecked(0);
        assertEq(value, 2);
        assertEq(nextOffset, 1);

        (value, nextOffset) = data.asUint8Unchecked(nextOffset);
        assertEq(value, 3);
        assertEq(nextOffset, 2);
    }

    function testFuzz_asUint8Unchecked(uint8 inputValue) external pure {
        bytes memory data = abi.encodePacked(uint8(inputValue));

        (uint8 value, uint256 nextOffset) = data.asUint8Unchecked(0);
        assertEq(value, inputValue);
        assertEq(nextOffset, 1);
    }

    function test_asBoolUnchecked() external pure {
        bytes memory trueData = abi.encodePacked(true);
        bytes memory falseData = abi.encodePacked(false);

        (bool trueValue,) = trueData.asBoolUnchecked(0);
        (bool falseValue,) = falseData.asBoolUnchecked(0);

        assertTrue(trueValue);
        assertFalse(falseValue);
    }

    /// forge-config: default.allow_internal_expect_revert = true
    function test_asBoolUnchecked_invalidValue() external {
        bytes memory invalidData = abi.encodePacked(uint8(2));

        vm.expectRevert(abi.encodeWithSelector(BytesParser.InvalidBool.selector, 0x02));
        invalidData.asBoolUnchecked(0);
    }

    function test_asUint256Unchecked() external pure {
        bytes memory data = abi.encodePacked(uint256(1));

        (uint256 value, uint256 nextOffset) = data.asUint256Unchecked(0);
        assertEq(value, 1);
        assertEq(nextOffset, 32);
    }

    function testFuzz_asUint256Unchecked(uint256 inputValue) external pure {
        bytes memory data = abi.encodePacked(inputValue);

        (uint256 value, uint256 nextOffset) = data.asUint256Unchecked(0);
        assertEq(value, inputValue);
        assertEq(nextOffset, 32);
    }

    function test_asUint128Unchecked() external pure {
        bytes memory data = abi.encodePacked(uint128(1));

        (uint128 value, uint256 nextOffset) = data.asUint128Unchecked(0);
        assertEq(value, 1);
        assertEq(nextOffset, 16);
    }

    function testFuzz_asUint128Unchecked(uint128 inputValue) external pure {
        bytes memory data = abi.encodePacked(inputValue);

        (uint128 value, uint256 nextOffset) = data.asUint128Unchecked(0);
        assertEq(value, inputValue);
        assertEq(nextOffset, 16);
    }

    function test_asUint32Unchecked() external pure {
        bytes memory data = abi.encodePacked(uint32(1));

        (uint32 value, uint256 nextOffset) = data.asUint32Unchecked(0);
        assertEq(value, 1);
        assertEq(nextOffset, 4);
    }

    function testFuzz_asUint32Unchecked(uint32 inputValue) external pure {
        bytes memory data = abi.encodePacked(inputValue);

        (uint32 value, uint256 nextOffset) = data.asUint32Unchecked(0);
        assertEq(value, inputValue);
        assertEq(nextOffset, 4);
    }

    function test_asBytes32Unchecked() external pure {
        bytes memory data = abi.encodePacked(bytes32(uint256(1)));

        (bytes32 value, uint256 nextOffset) = data.asBytes32Unchecked(0);
        assertEq(value, bytes32(uint256(1)));
        assertEq(nextOffset, 32);
    }

    function testFuzz_asBytes32Unchecked(bytes32 inputValue) external pure {
        bytes memory data = abi.encodePacked(inputValue);

        (bytes32 value, uint256 nextOffset) = data.asBytes32Unchecked(0);
        assertEq(value, inputValue);
        assertEq(nextOffset, 32);
    }

    function test_asAddressUnchecked() external pure {
        bytes memory data = abi.encodePacked(address(1));

        (address value, uint256 nextOffset) = data.asAddressUnchecked(0);
        assertEq(value, address(1));
        assertEq(nextOffset, 20);
    }

    function testFuzz_asAddressUnchecked(address inputValue) external pure {
        bytes memory data = abi.encodePacked(inputValue);

        (address value, uint256 nextOffset) = data.asAddressUnchecked(0);
        assertEq(value, inputValue);
        assertEq(nextOffset, 20);
    }
}
