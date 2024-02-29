// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.23;

import { ERC712Extended } from "../../src/ERC712.sol";

contract ERC712Harness is ERC712Extended {
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    struct Permit {
        address owner;
        address spender;
        uint256 value;
        uint256 nonce;
        uint256 deadline;
    }

    constructor(string memory name_) ERC712Extended(name_) {}

    function name() external view returns (string memory) {
        return _name;
    }

    function computeDomainSeparator(string memory name_, uint256 chainId_) external view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name_)),
                    keccak256("1"),
                    chainId_,
                    address(this)
                )
            );
    }

    function getDomainSeparator() external view returns (bytes32) {
        return _getDomainSeparator();
    }

    function getDigest(bytes32 internalDigest_) external view returns (bytes32) {
        return _getDigest(internalDigest_);
    }

    function getPermitHash(Permit memory _permit) external pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    PERMIT_TYPEHASH,
                    _permit.owner,
                    _permit.spender,
                    _permit.value,
                    _permit.nonce,
                    _permit.deadline
                )
            );
    }

    function getSignerAndRevertIfInvalidSignature(
        bytes32 digest_,
        uint8 v_,
        bytes32 r_,
        bytes32 s_
    ) external pure returns (address) {
        return _getSignerAndRevertIfInvalidSignature(digest_, v_, r_, s_);
    }

    function revertIfExpired(uint256 expiry_) external view returns (bool) {
        _revertIfExpired(expiry_);
        return true;
    }

    function revertIfInvalidSignature(
        address signer_,
        bytes32 digest_,
        bytes memory signature_
    ) external view returns (bool) {
        _revertIfInvalidSignature(signer_, digest_, signature_);
        return true;
    }

    function revertIfInvalidSignature(
        address signer_,
        bytes32 digest_,
        bytes32 r_,
        bytes32 vs_
    ) external pure returns (bool) {
        _revertIfInvalidSignature(signer_, digest_, r_, vs_);
        return true;
    }

    function revertIfInvalidSignature(
        address signer_,
        bytes32 digest_,
        uint8 v_,
        bytes32 r_,
        bytes32 s_
    ) external pure returns (bool) {
        _revertIfInvalidSignature(signer_, digest_, v_, r_, s_);
        return true;
    }
}
