// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.23;

import { SignatureChecker } from "./SignatureChecker.sol";

/// @title Typed structured data hashing and signing via EIP-712.
/// @dev   An abstract implementation to satisfy EIP-712: https://eips.ethereum.org/EIPS/eip-712
library ERC712 {
    // keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
    bytes32 internal constant _EIP712_DOMAIN_HASH = 0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;

    // keccak256("1")
    bytes32 internal constant _EIP712_VERSION_HASH = 0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6;

    /// @notice Revert message when an invalid signature is detected.
    error InvalidSignature();

    /// @notice Revert message when a signature with invalid length is detected.
    error InvalidSignatureLength();

    /**
     * @notice Revert message when a signature is being used beyond its deadline (i.e. expiry).
     * @param  deadline  The deadline of the signature.
     * @param  timestamp The current timestamp.
     */
    error SignatureExpired(uint256 deadline, uint256 timestamp);

    /// @notice Revert message when a recovered signer does not match the account being purported to have signed.
    error SignerMismatch();

    /**
     * @notice Computes the EIP-712 domain separator.
     * @param  name_ The name of the contract
     * @return       The EIP-712 domain separator
     */
    function computeDomainSeparator(string memory name_) internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    _EIP712_DOMAIN_HASH,
                    keccak256(bytes(name_)),
                    _EIP712_VERSION_HASH,
                    block.chainid,
                    address(this)
                )
            );
    }

    /**
     * @notice Returns the digest to be signed, via EIP-712, given an internal digest (i.e. hash struct).
     * @param  domainSeparator_ The EIP-712 domain separator
     * @param  internalDigest_  The internal digest
     * @return digest_          The digest to be signed
     */
    function getDigest(bytes32 domainSeparator_, bytes32 internalDigest_) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator_, internalDigest_));
    }

    /**
     * @notice Returns the signer of a signed digest, via EIP-712, and reverts if the signature is invalid.
     * @param  digest_  The digest that was signed
     * @param  v_       v of the signature
     * @param  r_       r of the signature
     * @param  s_       s of the signature
     * @return signer_  The signer of the digest
     */
    function getSignerAndRevertIfInvalidSignature(
        bytes32 digest_,
        uint8 v_,
        bytes32 r_,
        bytes32 s_
    ) internal pure returns (address signer_) {
        SignatureChecker.Error error_;

        (error_, signer_) = SignatureChecker.recoverECDSASigner(digest_, v_, r_, s_);

        _revertIfError(error_);
    }

    /**
     * @notice Revert if the signature is expired.
     * @param  expiry_ Timestamp at which the signature expires or max uint256 for no expiry
     */
    function revertIfExpired(uint256 expiry_) internal view {
        if (expiry_ != type(uint256).max) {
            if (block.timestamp > expiry_) revert SignatureExpired(expiry_, block.timestamp);
        }
    }

    /**
     * @notice Revert if the signature is invalid.
     * @param  signer_    The signer of the signature
     * @param  digest_    The digest that was signed
     * @param  signature_ The signature
     */
    function revertIfInvalidSignature(address signer_, bytes32 digest_, bytes memory signature_) internal view {
        if (!SignatureChecker.isValidSignature(signer_, digest_, signature_)) revert InvalidSignature();
    }

    /**
     * @notice Revert if the signature is invalid.
     * @param  signer_    The signer of the signature
     * @param  digest_    The digest that was signed
     * @param  v_         v of the signature
     * @param  r_         r of the signature
     * @param  s_         s of the signature
     */
    function revertIfInvalidSignature(
        address signer_,
        bytes32 digest_,
        uint8 v_,
        bytes32 r_,
        bytes32 s_
    ) internal pure {
        _revertIfError(SignatureChecker.validateECDSASignature(signer_, digest_, v_, r_, s_));
    }

    /**
     * @notice Revert if error.
     * @param  error_ The SignatureChecker Error enum
     */
    function _revertIfError(SignatureChecker.Error error_) private pure {
        if (error_ == SignatureChecker.Error.NoError) return;
        if (error_ == SignatureChecker.Error.InvalidSignature) revert InvalidSignature();
        if (error_ == SignatureChecker.Error.InvalidSignatureLength) revert InvalidSignatureLength();
        if (error_ == SignatureChecker.Error.SignerMismatch) revert SignerMismatch();

        revert InvalidSignature();
    }
}
