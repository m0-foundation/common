// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.20 <0.9.0;

/**
 * @title  A library to convert between string and bytes32 (assuming 32 characters or less).
 * @author M^0 Labs
 */
library Bytes32String {
    function toBytes32(string memory input) internal pure returns (bytes32) {
        return bytes32(abi.encodePacked(input));
    }

    function toString(bytes32 input) internal pure returns (string memory) {
        uint256 length;

        while (length < 32 && uint8(input[length]) != 0) {
            ++length;
        }

        bytes memory name = new bytes(length);

        for (uint256 index; index < length; ++index) {
            name[index] = input[index];
        }

        return string(name);
    }
}
