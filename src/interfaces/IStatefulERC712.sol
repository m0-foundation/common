// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.21;

import { IERC712 } from "./IERC712.sol";

/// @title Stateful Extension for EIP-712 typed structured data hashing and signing with nonces.
interface IStatefulERC712 is IERC712 {
    /**
     * @notice Revert message when a signing account's nonce is reused by a signature.
     * @param  nonce        The nonce used in the signature.
     * @param  currentNonce The last nonce used in a signature by then signing account.
     */
    error ReusedNonce(uint256 nonce, uint256 currentNonce);

    /**
     * @notice Returns the last nonce used in a signature by `account`.
     * @param  account The address of some account.
     * @return nonce   The last nonce used in a signature by `account`.
     */
    function nonces(address account) external view returns (uint256 nonce);
}
