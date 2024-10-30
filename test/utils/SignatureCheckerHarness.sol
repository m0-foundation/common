// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.20 <0.9.0;

import { SignatureChecker } from "../../src/libs/SignatureChecker.sol";

/// @title SignatureChecker harness used to correctly display test coverage.
contract SignatureCheckerHarness {
    function decodeECDSASignature(bytes memory signature) external pure returns (uint8 v, bytes32 r, bytes32 s) {
        return SignatureChecker.decodeECDSASignature(signature);
    }

    function isValidSignature(
        address signer,
        bytes32 digest,
        bytes memory signature
    ) external view returns (bool isValid) {
        return SignatureChecker.isValidSignature(signer, digest, signature);
    }

    function isValidECDSASignature(
        address signer,
        bytes32 digest,
        bytes memory signature
    ) external pure returns (bool isValid) {
        return SignatureChecker.isValidECDSASignature(signer, digest, signature);
    }

    function isValidECDSASignature(
        address signer,
        bytes32 digest,
        bytes32 r,
        bytes32 vs
    ) external pure returns (bool isValid) {
        return SignatureChecker.isValidECDSASignature(signer, digest, r, vs);
    }

    function isValidERC1271Signature(
        address signer,
        bytes32 digest,
        bytes memory signature
    ) external view returns (bool isValid) {
        return SignatureChecker.isValidERC1271Signature(signer, digest, signature);
    }

    function recoverECDSASigner(
        bytes32 digest,
        bytes memory signature
    ) external pure returns (SignatureChecker.Error error, address signer) {
        return SignatureChecker.recoverECDSASigner(digest, signature);
    }

    function recoverECDSASigner(
        bytes32 digest,
        bytes32 r,
        bytes32 vs
    ) external pure returns (SignatureChecker.Error error, address signer) {
        return SignatureChecker.recoverECDSASigner(digest, r, vs);
    }

    function recoverECDSASigner(
        bytes32 digest,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external pure returns (SignatureChecker.Error error, address signer) {
        return SignatureChecker.recoverECDSASigner(digest, v, r, s);
    }

    function validateECDSASignature(
        address signer,
        bytes32 digest,
        bytes memory signature
    ) external pure returns (SignatureChecker.Error error) {
        return SignatureChecker.validateECDSASignature(signer, digest, signature);
    }

    function validateECDSASignature(
        address signer,
        bytes32 digest,
        bytes32 r,
        bytes32 vs
    ) external pure returns (SignatureChecker.Error error) {
        return SignatureChecker.validateECDSASignature(signer, digest, r, vs);
    }

    function validateECDSASignature(
        address signer,
        bytes32 digest,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external pure returns (SignatureChecker.Error error) {
        return SignatureChecker.validateECDSASignature(signer, digest, v, r, s);
    }

    function validateRecoveredSigner(
        address signer,
        address recoveredSigner
    ) external pure returns (SignatureChecker.Error error) {
        return SignatureChecker.validateRecoveredSigner(signer, recoveredSigner);
    }
}
