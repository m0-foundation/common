// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.23;

import { Test } from "../../lib/forge-std/src/Test.sol";

import { ERC20PermitHarness } from "./ERC20PermitHarness.sol";

contract TestUtils is Test {
    /* ============ Permit ============ */
    function _signPermit(
        uint256 signerPrivateKey_,
        bytes32 digest_
    ) internal pure returns (uint8 _v, bytes32 _r, bytes32 _s) {
        (_v, _r, _s) = vm.sign(signerPrivateKey_, digest_);
    }

    function _getTransferWithAuthorizationDigest(
        ERC20PermitHarness asset_,
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
        ERC20PermitHarness asset_,
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
        ERC20PermitHarness asset_,
        address from_,
        bytes32 fromNonce_
    ) internal view returns (bytes32 digest_) {
        return asset_.getDigest(keccak256(abi.encode(asset_.CANCEL_AUTHORIZATION_TYPEHASH(), from_, fromNonce_)));
    }

    function _encodeSignature(uint8 v_, bytes32 r_, bytes32 s_) internal pure returns (bytes memory signature_) {
        return abi.encodePacked(r_, s_, v_);
    }
}
