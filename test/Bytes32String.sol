// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.20 <0.9.0;

import { Test } from "../lib/forge-std/src/Test.sol";

import { Bytes32StringHarness } from "./utils/Bytes32StringHarness.sol";

contract Bytes32StringTests is Test {
    Bytes32StringHarness internal _bytes32String;

    function setUp() external {
        _bytes32String = new Bytes32StringHarness();
    }

    function test_full() external view {
        assertEq(_bytes32String.toString(_bytes32String.toBytes32("")), "");
        assertEq(_bytes32String.toString(_bytes32String.toBytes32("T")), "T");
        assertEq(_bytes32String.toString(_bytes32String.toBytes32("Te")), "Te");
        assertEq(_bytes32String.toString(_bytes32String.toBytes32("Tes")), "Tes");
        assertEq(_bytes32String.toString(_bytes32String.toBytes32("Test")), "Test");
        assertEq(_bytes32String.toString(_bytes32String.toBytes32("Test1")), "Test1");
        assertEq(_bytes32String.toString(_bytes32String.toBytes32("Test1-")), "Test1-");
        assertEq(_bytes32String.toString(_bytes32String.toBytes32("Test1-T")), "Test1-T");
        assertEq(_bytes32String.toString(_bytes32String.toBytes32("Test1-Te")), "Test1-Te");
        assertEq(_bytes32String.toString(_bytes32String.toBytes32("Test1-Tes")), "Test1-Tes");
        assertEq(_bytes32String.toString(_bytes32String.toBytes32("Test1-Test")), "Test1-Test");
        assertEq(_bytes32String.toString(_bytes32String.toBytes32("Test1-Test2")), "Test1-Test2");
        assertEq(_bytes32String.toString(_bytes32String.toBytes32("Test1-Test2-")), "Test1-Test2-");
        assertEq(_bytes32String.toString(_bytes32String.toBytes32("Test1-Test2-T")), "Test1-Test2-T");
        assertEq(_bytes32String.toString(_bytes32String.toBytes32("Test1-Test2-Te")), "Test1-Test2-Te");
        assertEq(_bytes32String.toString(_bytes32String.toBytes32("Test1-Test2-Tes")), "Test1-Test2-Tes");
        assertEq(_bytes32String.toString(_bytes32String.toBytes32("Test1-Test2-Test")), "Test1-Test2-Test");
        assertEq(_bytes32String.toString(_bytes32String.toBytes32("Test1-Test2-Test3")), "Test1-Test2-Test3");
        assertEq(_bytes32String.toString(_bytes32String.toBytes32("Test1-Test2-Test3-")), "Test1-Test2-Test3-");
        assertEq(_bytes32String.toString(_bytes32String.toBytes32("Test1-Test2-Test3-T")), "Test1-Test2-Test3-T");
        assertEq(_bytes32String.toString(_bytes32String.toBytes32("Test1-Test2-Test3-Te")), "Test1-Test2-Test3-Te");
        assertEq(_bytes32String.toString(_bytes32String.toBytes32("Test1-Test2-Test3-Tes")), "Test1-Test2-Test3-Tes");
        assertEq(_bytes32String.toString(_bytes32String.toBytes32("Test1-Test2-Test3-Test")), "Test1-Test2-Test3-Test");
        assertEq(
            _bytes32String.toString(_bytes32String.toBytes32("Test1-Test2-Test3-Test4")),
            "Test1-Test2-Test3-Test4"
        );
        assertEq(
            _bytes32String.toString(_bytes32String.toBytes32("Test1-Test2-Test3-Test4-")),
            "Test1-Test2-Test3-Test4-"
        );
        assertEq(
            _bytes32String.toString(_bytes32String.toBytes32("Test1-Test2-Test3-Test4-T")),
            "Test1-Test2-Test3-Test4-T"
        );
        assertEq(
            _bytes32String.toString(_bytes32String.toBytes32("Test1-Test2-Test3-Test4-Te")),
            "Test1-Test2-Test3-Test4-Te"
        );
        assertEq(
            _bytes32String.toString(_bytes32String.toBytes32("Test1-Test2-Test3-Test4-Tes")),
            "Test1-Test2-Test3-Test4-Tes"
        );
        assertEq(
            _bytes32String.toString(_bytes32String.toBytes32("Test1-Test2-Test3-Test4-Test")),
            "Test1-Test2-Test3-Test4-Test"
        );
        assertEq(
            _bytes32String.toString(_bytes32String.toBytes32("Test1-Test2-Test3-Test4-Test5")),
            "Test1-Test2-Test3-Test4-Test5"
        );
        assertEq(
            _bytes32String.toString(_bytes32String.toBytes32("Test1-Test2-Test3-Test4-Test5-")),
            "Test1-Test2-Test3-Test4-Test5-"
        );
        assertEq(
            _bytes32String.toString(_bytes32String.toBytes32("Test1-Test2-Test3-Test4-Test5-T")),
            "Test1-Test2-Test3-Test4-Test5-T"
        );
        assertEq(
            _bytes32String.toString(_bytes32String.toBytes32("Test1-Test2-Test3-Test4-Test5-Te")),
            "Test1-Test2-Test3-Test4-Test5-Te"
        );

        // Beyond this point, input is larger than 32 bytes, so it is truncated.
        assertEq(
            _bytes32String.toString(_bytes32String.toBytes32("Test1-Test2-Test3-Test4-Test5-Tes")),
            "Test1-Test2-Test3-Test4-Test5-Te"
        );
        assertEq(
            _bytes32String.toString(_bytes32String.toBytes32("Test1-Test2-Test3-Test4-Test5-Test")),
            "Test1-Test2-Test3-Test4-Test5-Te"
        );
        assertEq(
            _bytes32String.toString(_bytes32String.toBytes32("Test1-Test2-Test3-Test4-Test5-Test6")),
            "Test1-Test2-Test3-Test4-Test5-Te"
        );
    }

    function testFuzz_full(string memory input_) external view {
        assertEq(_bytes32String.toString(_bytes32String.toBytes32(input_)), _truncate32(input_));
    }

    function _truncate32(string memory input_) internal pure returns (string memory) {
        bytes memory bytesIn_ = bytes(input_);

        if (bytesIn_.length <= 32) return input_;

        bytes memory bytesOut_ = new bytes(32);

        for (uint256 index_; index_ < 32; ++index_) {
            bytesOut_[index_] = bytesIn_[index_];
        }

        return string(bytesOut_);
    }
}
