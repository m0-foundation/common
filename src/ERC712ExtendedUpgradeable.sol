// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.20 <0.9.0;

import { Initializable } from "../lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";

import { IERC712 } from "./interfaces/IERC712.sol";
import { IERC712Extended } from "./interfaces/IERC712Extended.sol";

import { SignatureChecker } from "./libs/SignatureChecker.sol";

abstract contract ERC712ExtendedUpgradeableStorageLayout {
    /// @custom:storage-location erc7201:M0.storage.ERC712Extended
    struct ERC712ExtendedStorageStruct {
        uint256 initialChainId;
        bytes32 initialDomainSeparator;
        string name;
    }

    // keccak256(abi.encode(uint256(keccak256("M0.storage.ERC712Extended")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant _ERC712_EXTENDED_STORAGE_LOCATION =
        0x103ce0bed7138196cdb0d79ef04042681b16e7a2c58d74b78443c813042ea100;

    function _getERC712ExtendedStorageLocation() internal pure returns (ERC712ExtendedStorageStruct storage $) {
        assembly {
            $.slot := _ERC712_EXTENDED_STORAGE_LOCATION
        }
    }
}

/**
 * @title  Typed structured data hashing and signing via EIP-712, extended by EIP-5267.
 * @author M0 Labs
 * @dev    An abstract implementation to satisfy EIP-712: https://eips.ethereum.org/EIPS/eip-712
 */
abstract contract ERC712ExtendedUpgradeable is ERC712ExtendedUpgradeableStorageLayout, IERC712Extended, Initializable {
    /* ============ Variables ============ */

    /// @dev keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
    bytes32 internal constant _EIP712_DOMAIN_HASH = 0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;

    /// @dev keccak256("1")
    bytes32 internal constant _EIP712_VERSION_HASH = 0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6;

    /* ============ Initializer ============ */

    /**
     * @notice Initializes the ERC712ExtendedUpgradeable contract.
     * @param  name_ The name of the contract.
     */
    function __ERC712ExtendedUpgradeable_init(string memory name_) internal onlyInitializing {
        ERC712ExtendedStorageStruct storage $ = _getERC712ExtendedStorageLocation();

        $.name = name_;
        $.initialChainId = block.chainid;
        $.initialDomainSeparator = _getDomainSeparator();
    }

    /* ============ View/Pure Functions ============ */

    /// @inheritdoc IERC712Extended
    function eip712Domain()
        external
        view
        virtual
        returns (
            bytes1 fields_,
            string memory name_,
            string memory version_,
            uint256 chainId_,
            address verifyingContract_,
            bytes32 salt_,
            uint256[] memory extensions_
        )
    {
        return (
            hex"0f", // 01111
            _getERC712ExtendedStorageLocation().name,
            "1",
            block.chainid,
            address(this),
            bytes32(0),
            new uint256[](0)
        );
    }

    /// @inheritdoc IERC712
    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        ERC712ExtendedStorageStruct storage $ = _getERC712ExtendedStorageLocation();
        return block.chainid == $.initialChainId ? $.initialDomainSeparator : _getDomainSeparator();
    }

    /* ============ Internal View/Pure Functions ============ */

    /**
     * @dev    Computes the EIP-712 domain separator.
     * @return The EIP-712 domain separator.
     */
    function _getDomainSeparator() internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    _EIP712_DOMAIN_HASH,
                    keccak256(bytes(_getERC712ExtendedStorageLocation().name)),
                    _EIP712_VERSION_HASH,
                    block.chainid,
                    address(this)
                )
            );
    }

    /**
     * @dev    Returns the digest to be signed, via EIP-712, given an internal digest (i.e. hash struct).
     * @param  internalDigest_ The internal digest.
     * @return The digest to be signed.
     */
    function _getDigest(bytes32 internalDigest_) internal view returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR(), internalDigest_));
    }

    /**
     * @dev   Revert if the signature is expired.
     * @param expiry_ Timestamp at which the signature expires or max uint256 for no expiry.
     */
    function _revertIfExpired(uint256 expiry_) internal view {
        if (block.timestamp > expiry_) revert SignatureExpired(expiry_, block.timestamp);
    }

    /**
     * @dev   Revert if the signature is invalid.
     * @dev   We first validate if the signature is a valid ECDSA signature and return early if it is the case.
     *        Then, we validate if it is a valid ERC-1271 signature, and return early if it is the case.
     *        If not, we revert with the error from the ECDSA signature validation.
     * @param signer_    The signer of the signature.
     * @param digest_    The digest that was signed.
     * @param signature_ The signature.
     */
    function _revertIfInvalidSignature(address signer_, bytes32 digest_, bytes memory signature_) internal view {
        SignatureChecker.Error error_ = SignatureChecker.validateECDSASignature(signer_, digest_, signature_);

        if (error_ == SignatureChecker.Error.NoError) return;

        if (SignatureChecker.isValidERC1271Signature(signer_, digest_, signature_)) return;

        _revertIfError(error_);
    }

    /**
     * @dev    Returns the signer of a signed digest, via EIP-712, and reverts if the signature is invalid.
     * @param  digest_ The digest that was signed.
     * @param  v_      v of the signature.
     * @param  r_      r of the signature.
     * @param  s_      s of the signature.
     * @return signer_ The signer of the digest.
     */
    function _getSignerAndRevertIfInvalidSignature(
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
     * @dev   Revert if the signature is invalid.
     * @param signer_ The signer of the signature.
     * @param digest_ The digest that was signed.
     * @param r_      An ECDSA/secp256k1 signature parameter.
     * @param vs_     An ECDSA/secp256k1 short signature parameter.
     */
    function _revertIfInvalidSignature(address signer_, bytes32 digest_, bytes32 r_, bytes32 vs_) internal pure {
        _revertIfError(SignatureChecker.validateECDSASignature(signer_, digest_, r_, vs_));
    }

    /**
     * @dev   Revert if the signature is invalid.
     * @param signer_ The signer of the signature.
     * @param digest_ The digest that was signed.
     * @param v_      v of the signature.
     * @param r_      r of the signature.
     * @param s_      s of the signature.
     */
    function _revertIfInvalidSignature(
        address signer_,
        bytes32 digest_,
        uint8 v_,
        bytes32 r_,
        bytes32 s_
    ) internal pure {
        _revertIfError(SignatureChecker.validateECDSASignature(signer_, digest_, v_, r_, s_));
    }

    /**
     * @dev   Revert if error.
     * @param error_ The SignatureChecker Error enum.
     */
    function _revertIfError(SignatureChecker.Error error_) private pure {
        if (error_ == SignatureChecker.Error.NoError) return;
        if (error_ == SignatureChecker.Error.InvalidSignature) revert InvalidSignature();
        if (error_ == SignatureChecker.Error.InvalidSignatureLength) revert InvalidSignatureLength();
        if (error_ == SignatureChecker.Error.InvalidSignatureS) revert InvalidSignatureS();
        if (error_ == SignatureChecker.Error.InvalidSignatureV) revert InvalidSignatureV();
        if (error_ == SignatureChecker.Error.SignerMismatch) revert SignerMismatch();

        revert InvalidSignature();
    }
}
