// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.26;

/**
 * @title  Standard Signature Validation Method for Contracts via EIP-1271.
 * @author M^0 Labs
 * @dev    The interface as defined by EIP-1271: https://eips.ethereum.org/EIPS/eip-1271
 */
interface IERC1271 {
    /**
     * @dev    Returns a specific magic value if the provided signature is valid for the provided digest.
     * @param  digest     Hash of the data purported to have been signed.
     * @param  signature  Signature byte array associated with the digest.
     * @return magicValue Magic value 0x1626ba7e if the signature is valid.
     */
    function isValidSignature(bytes32 digest, bytes memory signature) external view returns (bytes4 magicValue);
}
