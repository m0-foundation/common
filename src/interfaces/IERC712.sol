// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.26;

/**
 * @title  Typed structured data hashing and signing via EIP-712.
 * @author M^0 Labs
 * @dev    The interface as defined by EIP-712: https://eips.ethereum.org/EIPS/eip-712
 */
interface IERC712 {
    /* ============ Custom Errors ============ */

    /// @notice Revert message when an invalid signature is detected.
    error InvalidSignature();

    /// @notice Revert message when a signature with invalid length is detected.
    error InvalidSignatureLength();

    /// @notice Revert message when the S portion of a signature is invalid.
    error InvalidSignatureS();

    /// @notice Revert message when the V portion of a signature is invalid.
    error InvalidSignatureV();

    /**
     * @notice Revert message when a signature is being used beyond its deadline (i.e. expiry).
     * @param  deadline  The last timestamp where the signature is still valid.
     * @param  timestamp The current timestamp.
     */
    error SignatureExpired(uint256 deadline, uint256 timestamp);

    /// @notice Revert message when a recovered signer does not match the account being purported to have signed.
    error SignerMismatch();

    /* ============ View/Pure Functions ============ */

    /// @notice Returns the EIP712 domain separator used in the encoding of a signed digest.
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}
