// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.23;

import { Test } from "../../lib/forge-std/src/Test.sol";

contract TestUtils is Test {
    /* ============ Permit ============ */
    function _signDigest(
        uint256 signerPrivateKey_,
        bytes32 digest_
    ) internal pure returns (uint8 v_, bytes32 r_, bytes32 s_) {
        (v_, r_, s_) = vm.sign(signerPrivateKey_, digest_);
    }

    function _getVS(uint8 v_, bytes32 s_) internal pure returns (bytes32) {
        if (v_ == 28) {
            // then v equals 1 bit and the left-most bit of s has to be flipped to 1.
            s_ = s_ | bytes32(uint256(1) << 255);
        }

        return s_;
    }

    function _encodeSignature(uint8 v_, bytes32 r_, bytes32 s_) internal pure returns (bytes memory signature_) {
        return abi.encodePacked(r_, s_, v_);
    }

    function _encodeShortSignature(bytes32 r_, bytes32 vs_) internal pure returns (bytes memory signature_) {
        return abi.encodePacked(r_, vs_);
    }
}
