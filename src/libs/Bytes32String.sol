// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.20 <0.9.0;

/**
 * @title  A library to convert between string and bytes32 (assuming 32 characters or less).
 * @author M^0 Labs
 */
library Bytes32String {
    function toBytes32(string memory input_) internal pure returns (bytes32) {
        return bytes32(abi.encodePacked(input_));
    }

    function toString(bytes32 input_) internal pure returns (string memory) {
        uint256 length_;

        while (length_ < 32 && uint8(input_[length_]) != 0) {
            ++length_;
        }

        bytes memory name_ = new bytes(length_);

        for (uint256 index_; index_ < length_; ++index_) {
            name_[index_] = input_[index_];
        }

        return string(name_);
    }
}
