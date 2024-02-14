// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.23;

import { IERC712 } from "./IERC712.sol";

/// @title Stateful Extension for EIP-712 typed structured data hashing and signing with nonces.
interface IStatefulERC712 is IERC712 {
    /**
     * @notice Revert message when a signing account's nonce is not the expected current nonce.
     * @param  nonce         The nonce used in the signature.
     * @param  expectedNonce The expected nonce to be used in a signature by the signing account.
     */
    error InvalidAccountNonce(uint256 nonce, uint256 expectedNonce);

    /**
     * @notice Returns the next nonce to be used in a signature by `account`.
     * @param  account The address of some account.
     * @return nonce   The next nonce to be used in a signature by `account`.
     */
    function nonces(address account) external view returns (uint256 nonce);
}
