// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.21;

interface IStatelessERC712 {
    error InvalidSignature();

    error InvalidSignatureLength();

    error SignatureExpired(uint256 deadline, uint256 timestamp);

    error SignerMismatch();

    function DOMAIN_SEPARATOR() external view returns (bytes32 domainSeparator);
}
