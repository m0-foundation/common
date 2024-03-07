// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.23;

import { IERC1271 } from "../interfaces/IERC1271.sol";

/**
 * @title  A library to handle ECDSA/secp256k1 and ERC1271 signatures, individually or in arbitrarily in combination.
 * @author M^0 Labs
 */
library SignatureChecker {
    /* ============ Enums ============ */

    /**
     * @notice An enum representing the possible errors that can be emitted during signature validation.
     * @param  NoError                No error occurred during signature validation.
     * @param  InvalidSignature       The signature is invalid.
     * @param  InvalidSignatureLength The signature length is invalid.
     * @param  InvalidSignatureS      The signature parameter S is invalid.
     * @param  InvalidSignatureV      The signature parameter V is invalid.
     * @param  SignerMismatch         The signer does not match the recovered signer.
     */
    enum Error {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV,
        SignerMismatch
    }

    /* ============ Internal View/Pure Functions ============ */

    /**
     * @dev    Returns whether a signature is valid (ECDSA/secp256k1 or ERC1271) for a signer and digest.
     * @dev    Signatures must not be used as unique identifiers since the `ecrecover` EVM opcode
     *         allows for malleable (non-unique) signatures.
     *         See https://github.com/OpenZeppelin/openzeppelin-contracts/security/advisories/GHSA-4h98-2769-gh6h
     * @param  signer    The address of the account purported to have signed.
     * @param  digest    The hash of the data that was signed.
     * @param  signature A byte array signature.
     * @return           Whether the signature is valid or not.
     */
    function isValidSignature(address signer, bytes32 digest, bytes memory signature) internal view returns (bool) {
        return isValidECDSASignature(signer, digest, signature) || isValidERC1271Signature(signer, digest, signature);
    }

    /**
     * @dev    Returns whether an ERC1271 signature is valid for a signer and digest.
     * @param  signer    The address of the account purported to have signed.
     * @param  digest    The hash of the data that was signed.
     * @param  signature A byte array ERC1271 signature.
     * @return           Whether the signature is valid or not.
     */
    function isValidERC1271Signature(
        address signer,
        bytes32 digest,
        bytes memory signature
    ) internal view returns (bool) {
        (bool success, bytes memory result) = signer.staticcall(
            abi.encodeCall(IERC1271.isValidSignature, (digest, signature))
        );

        return
            success &&
            result.length >= 32 &&
            abi.decode(result, (bytes32)) == bytes32(IERC1271.isValidSignature.selector);
    }

    /**
     * @dev    Decodes an ECDSA/secp256k1 signature from a byte array to standard v, r, and s parameters.
     * @param  signature A byte array ECDSA/secp256k1 signature.
     * @return v         An ECDSA/secp256k1 signature parameter.
     * @return r         An ECDSA/secp256k1 signature parameter.
     * @return s         An ECDSA/secp256k1 signature parameter.
     */
    function decodeECDSASignature(bytes memory signature) internal pure returns (uint8 v, bytes32 r, bytes32 s) {
        // ecrecover takes the signature parameters, and they can be decoded using assembly.
        /// @solidity memory-safe-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }
    }

    /**
     * @dev    Decodes an ECDSA/secp256k1 short signature as defined by EIP2098
     *         from a byte array to standard v, r, and s parameters.
     * @param  signature A byte array ECDSA/secp256k1 short signature.
     * @return r         An ECDSA/secp256k1 signature parameter.
     * @return vs        An ECDSA/secp256k1 short signature parameter.
     */
    function decodeShortECDSASignature(bytes memory signature) internal pure returns (bytes32 r, bytes32 vs) {
        // ecrecover takes the signature parameters, and they can be decoded using assembly.
        /// @solidity memory-safe-assembly
        assembly {
            r := mload(add(signature, 0x20))
            vs := mload(add(signature, 0x40))
        }
    }

    /**
     * @dev    Returns whether an ECDSA/secp256k1 signature is valid for a signer and digest.
     * @param  signer    The address of the account purported to have signed.
     * @param  digest    The hash of the data that was signed.
     * @param  signature A byte array ECDSA/secp256k1 signature (encoded r, s, v).
     * @return           Whether the signature is valid or not.
     */
    function isValidECDSASignature(
        address signer,
        bytes32 digest,
        bytes memory signature
    ) internal pure returns (bool) {
        if (signature.length == 64) {
            (bytes32 r, bytes32 vs) = decodeShortECDSASignature(signature);
            return isValidECDSASignature(signer, digest, r, vs);
        }

        return validateECDSASignature(signer, digest, signature) == Error.NoError;
    }

    /**
     * @dev    Returns whether an ECDSA/secp256k1 short signature is valid for a signer and digest.
     * @param  signer  The address of the account purported to have signed.
     * @param  digest  The hash of the data that was signed.
     * @param  r       An ECDSA/secp256k1 signature parameter.
     * @param  vs      An ECDSA/secp256k1 short signature parameter.
     * @return         Whether the signature is valid or not.
     */
    function isValidECDSASignature(address signer, bytes32 digest, bytes32 r, bytes32 vs) internal pure returns (bool) {
        return validateECDSASignature(signer, digest, r, vs) == Error.NoError;
    }

    /**
     * @dev    Returns the signer of an ECDSA/secp256k1 signature for some digest.
     * @param  digest    The hash of the data that was signed.
     * @param  signature A byte array ECDSA/secp256k1 signature.
     * @return           An error, if any, that occurred during the signer recovery.
     * @return           The address of the account recovered form the signature (0 if error).
     */
    function recoverECDSASigner(bytes32 digest, bytes memory signature) internal pure returns (Error, address) {
        if (signature.length != 65) return (Error.InvalidSignatureLength, address(0));

        (uint8 v, bytes32 r, bytes32 s) = decodeECDSASignature(signature);

        return recoverECDSASigner(digest, v, r, s);
    }

    /**
     * @dev    Returns the signer of an ECDSA/secp256k1 short signature for some digest.
     * @dev    See https://eips.ethereum.org/EIPS/eip-2098
     * @param  digest The hash of the data that was signed.
     * @param  r      An ECDSA/secp256k1 signature parameter.
     * @param  vs     An ECDSA/secp256k1 short signature parameter.
     * @return        An error, if any, that occurred during the signer recovery.
     * @return        The address of the account recovered form the signature (0 if error).
     */
    function recoverECDSASigner(bytes32 digest, bytes32 r, bytes32 vs) internal pure returns (Error, address) {
        unchecked {
            // We do not check for an overflow here since the shift operation results in 0 or 1.
            uint8 v = uint8((uint256(vs) >> 255) + 27);
            bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
            return recoverECDSASigner(digest, v, r, s);
        }
    }

    /**
     * @dev    Returns the signer of an ECDSA/secp256k1 signature for some digest.
     * @param  digest The hash of the data that was signed.
     * @param  v      An ECDSA/secp256k1 signature parameter.
     * @param  r      An ECDSA/secp256k1 signature parameter.
     * @param  s      An ECDSA/secp256k1 signature parameter.
     * @return        An error, if any, that occurred during the signer recovery.
     * @return signer The address of the account recovered form the signature (0 if error).
     */
    function recoverECDSASigner(
        bytes32 digest,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (Error, address signer) {
        // Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}.
        if (uint256(s) > uint256(0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0))
            return (Error.InvalidSignatureS, address(0));

        if (v != 27 && v != 28) return (Error.InvalidSignatureV, address(0));

        signer = ecrecover(digest, v, r, s);

        return (signer == address(0)) ? (Error.InvalidSignature, address(0)) : (Error.NoError, signer);
    }

    /**
     * @dev    Returns an error, if any, in validating an ECDSA/secp256k1 signature for a signer and digest.
     * @param  signer    The address of the account purported to have signed.
     * @param  digest    The hash of the data that was signed.
     * @param  signature A byte array ERC1271 signature.
     * @return           An error, if any, that occurred during the signer recovery.
     */
    function validateECDSASignature(
        address signer,
        bytes32 digest,
        bytes memory signature
    ) internal pure returns (Error) {
        (Error recoverError, address recoveredSigner) = recoverECDSASigner(digest, signature);

        return (recoverError == Error.NoError) ? validateRecoveredSigner(signer, recoveredSigner) : recoverError;
    }

    /**
     * @dev    Returns an error, if any, in validating an ECDSA/secp256k1 short signature for a signer and digest.
     * @param  signer The address of the account purported to have signed.
     * @param  digest The hash of the data that was signed.
     * @param  r      An ECDSA/secp256k1 signature parameter.
     * @param  vs     An ECDSA/secp256k1 short signature parameter.
     * @return        An error, if any, that occurred during the signer recovery.
     */
    function validateECDSASignature(
        address signer,
        bytes32 digest,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (Error) {
        (Error recoverError, address recoveredSigner) = recoverECDSASigner(digest, r, vs);

        return (recoverError == Error.NoError) ? validateRecoveredSigner(signer, recoveredSigner) : recoverError;
    }

    /**
     * @dev    Returns an error, if any, in validating an ECDSA/secp256k1 signature for a signer and digest.
     * @param  signer The address of the account purported to have signed.
     * @param  digest The hash of the data that was signed.
     * @param  v      An ECDSA/secp256k1 signature parameter.
     * @param  r      An ECDSA/secp256k1 signature parameter.
     * @param  s      An ECDSA/secp256k1 signature parameter.
     * @return        An error, if any, that occurred during the signer recovery.
     */
    function validateECDSASignature(
        address signer,
        bytes32 digest,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (Error) {
        (Error recoverError, address recoveredSigner) = recoverECDSASigner(digest, v, r, s);

        return (recoverError == Error.NoError) ? validateRecoveredSigner(signer, recoveredSigner) : recoverError;
    }

    /**
     * @dev    Returns an error if `signer` is not `recoveredSigner`.
     * @param  signer          The address of the some signer.
     * @param  recoveredSigner The address of the some recoveredSigner.
     * @return                 An error if `signer` is not `recoveredSigner`.
     */
    function validateRecoveredSigner(address signer, address recoveredSigner) internal pure returns (Error) {
        return (signer == recoveredSigner) ? Error.NoError : Error.SignerMismatch;
    }
}
