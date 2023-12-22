// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.23;

import { Test } from "../../lib/forge-std/src/Test.sol";

import { ERC20ExtendedHarness } from "./ERC20ExtendedHarness.sol";

contract TestUtils is Test {
    /* ============ Permit ============ */
    function _signPermit(
        uint256 signerPrivateKey_,
        bytes32 digest_
    ) internal pure returns (uint8 v_, bytes32 r_, bytes32 s_) {
        (v_, r_, s_) = vm.sign(signerPrivateKey_, digest_);
    }

    function _getTransferWithAuthorizationDigest(
        ERC20ExtendedHarness asset_,
        address from_,
        address to_,
        uint256 value_,
        uint256 validAfter_,
        uint256 validBefore_,
        bytes32 fromNonce_
    ) internal view returns (bytes32 digest_) {
        return
            asset_.getDigest(
                keccak256(
                    abi.encode(
                        asset_.TRANSFER_WITH_AUTHORIZATION_TYPEHASH(),
                        from_,
                        to_,
                        value_,
                        validAfter_,
                        validBefore_,
                        fromNonce_
                    )
                )
            );
    }

    function _getReceiveWithAuthorizationDigest(
        ERC20ExtendedHarness asset_,
        address from_,
        address to_,
        uint256 value_,
        uint256 validAfter_,
        uint256 validBefore_,
        bytes32 fromNonce_
    ) internal view returns (bytes32 digest_) {
        return
            asset_.getDigest(
                keccak256(
                    abi.encode(
                        asset_.RECEIVE_WITH_AUTHORIZATION_TYPEHASH(),
                        from_,
                        to_,
                        value_,
                        validAfter_,
                        validBefore_,
                        fromNonce_
                    )
                )
            );
    }

    function _getCancelAuthorizationDigest(
        ERC20ExtendedHarness asset_,
        address from_,
        bytes32 fromNonce_
    ) internal view returns (bytes32 digest_) {
        return asset_.getDigest(keccak256(abi.encode(asset_.CANCEL_AUTHORIZATION_TYPEHASH(), from_, fromNonce_)));
    }

    function _getVS(uint8 v_, bytes32 s_) internal pure returns (bytes32 vs_) {
        if (v_ == 28) {
            // then left-most bit of s has to be flipped to 1 to get vs
            vs_ = s_ | bytes32(uint256(1) << 255);
        }
    }

    function _encodeSignature(uint8 v_, bytes32 r_, bytes32 s_) internal pure returns (bytes memory signature_) {
        return abi.encodePacked(r_, s_, v_);
    }

    function _encodeShortSignature(bytes32 r_, bytes32 vs_) internal pure returns (bytes memory signature_) {
        return abi.encodePacked(r_, vs_);
    }
}
