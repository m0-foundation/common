// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.20 <0.9.0;

import { ERC712Extended } from "../../src/ERC712Extended.sol";

import { IERC712ExtendedHarness } from "./IERC712ExtendedHarness.sol";

contract ERC712ExtendedHarness is IERC712ExtendedHarness, ERC712Extended {
    constructor(string memory name_) ERC712Extended(name_) {}

    function getDomainSeparator() external view returns (bytes32) {
        return _getDomainSeparator();
    }

    function getDigest(bytes32 internalDigest_) external view returns (bytes32) {
        return _getDigest(internalDigest_);
    }

    function getSignerAndRevertIfInvalidSignature(
        bytes32 digest_,
        uint8 v_,
        bytes32 r_,
        bytes32 s_
    ) external pure returns (address) {
        return _getSignerAndRevertIfInvalidSignature(digest_, v_, r_, s_);
    }

    function revertIfExpired(uint256 expiry_) external view {
        _revertIfExpired(expiry_);
    }

    function revertIfInvalidSignature(address signer_, bytes32 digest_, bytes memory signature_) external view {
        _revertIfInvalidSignature(signer_, digest_, signature_);
    }

    function revertIfInvalidSignature(address signer_, bytes32 digest_, bytes32 r_, bytes32 vs_) external pure {
        _revertIfInvalidSignature(signer_, digest_, r_, vs_);
    }

    function revertIfInvalidSignature(
        address signer_,
        bytes32 digest_,
        uint8 v_,
        bytes32 r_,
        bytes32 s_
    ) external pure {
        _revertIfInvalidSignature(signer_, digest_, v_, r_, s_);
    }
}
