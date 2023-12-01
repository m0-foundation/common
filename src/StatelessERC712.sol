// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.21;

import { IStatelessERC712 } from "./interfaces/IStatelessERC712.sol";

import { SignatureChecker } from "./SignatureChecker.sol";

abstract contract StatelessERC712 is IStatelessERC712 {
    // keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
    bytes32 internal constant _EIP712_DOMAIN_HASH = 0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;

    // keccak256("1")
    bytes32 internal constant _EIP712_VERSION_HASH = 0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6;

    bytes32 internal immutable _domainSeparator;

    string internal _name;

    constructor(string memory name_) {
        _domainSeparator = keccak256(
            abi.encode(
                _EIP712_DOMAIN_HASH,
                keccak256(bytes(_name = name_)),
                _EIP712_VERSION_HASH,
                block.chainid,
                address(this)
            )
        );
    }

    /******************************************************************************************************************\
    |                                       External/Public View/Pure Functions                                        |
    \******************************************************************************************************************/

    function DOMAIN_SEPARATOR() public view returns (bytes32 domainSeparator_) {
        domainSeparator_ = _domainSeparator;
    }

    /******************************************************************************************************************\
    |                                           Internal View/Pure Functions                                           |
    \******************************************************************************************************************/

    function _getDigest(bytes32 internalDigest_) internal view returns (bytes32 digest_) {
        digest_ = keccak256(abi.encodePacked("\x19\x01", _domainSeparator, internalDigest_));
    }

    function _getSignerAndRevertItInvalidSignature(
        bytes32 digest_,
        uint8 v_,
        bytes32 r_,
        bytes32 s_
    ) internal pure returns (address signer_) {
        SignatureChecker.Error error_;

        (error_, signer_) = SignatureChecker.recoverECDSASigner(digest_, v_, r_, s_);

        _revertIfError(error_);
    }

    function _revertIfError(SignatureChecker.Error error_) private pure {
        if (error_ == SignatureChecker.Error.NoError) return;

        if (error_ == SignatureChecker.Error.InvalidSignature) revert InvalidSignature();

        if (error_ == SignatureChecker.Error.InvalidSignatureLength) revert InvalidSignatureLength();

        if (error_ == SignatureChecker.Error.SignerMismatch) revert SignerMismatch();

        revert InvalidSignature();
    }

    function _revertIfExpired(uint256 expiry_) internal view {
        if (block.timestamp > expiry_) revert SignatureExpired(expiry_, block.timestamp);
    }

    function _revertItInvalidSignature(address signer_, bytes32 digest_, bytes memory signature) internal view {
        if (!SignatureChecker.isValidSignature(signer_, digest_, signature)) revert InvalidSignature();
    }

    function _revertItInvalidSignature(
        address signer_,
        bytes32 digest_,
        uint8 v_,
        bytes32 r_,
        bytes32 s_
    ) internal pure {
        _revertIfError(SignatureChecker.validateECDSASignature(signer_, digest_, v_, r_, s_));
    }
}
