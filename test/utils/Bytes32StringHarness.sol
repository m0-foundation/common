// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.23;

import { Bytes32String } from "../../src/libs/Bytes32String.sol";

/// @title Bytes32String harness used to correctly display test coverage.
contract Bytes32StringHarness {
    function toBytes32(string memory input_) external pure returns (bytes32) {
        return Bytes32String.toBytes32(input_);
    }

    function toString(bytes32 input_) external pure returns (string memory) {
        return Bytes32String.toString(input_);
    }
}
