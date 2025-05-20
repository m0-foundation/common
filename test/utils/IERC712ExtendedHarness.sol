// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.20 <0.9.0;

import { IERC712Extended } from "../../src/interfaces/IERC712Extended.sol";

interface IERC712ExtendedHarness is IERC712Extended {
    function getDomainSeparator() external view returns (bytes32);

    function getDigest(bytes32 internalDigest_) external view returns (bytes32);

    function getSignerAndRevertIfInvalidSignature(
        bytes32 digest_,
        uint8 v_,
        bytes32 r_,
        bytes32 s_
    ) external pure returns (address);

    function revertIfExpired(uint256 expiry_) external view;

    function revertIfInvalidSignature(address signer_, bytes32 digest_, bytes memory signature_) external view;

    function revertIfInvalidSignature(address signer_, bytes32 digest_, bytes32 r_, bytes32 vs_) external pure;

    function revertIfInvalidSignature(address signer_, bytes32 digest_, uint8 v_, bytes32 r_, bytes32 s_) external pure;
}
