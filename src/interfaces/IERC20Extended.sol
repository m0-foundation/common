// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.23;

import { IERC20 } from "./IERC20.sol";
import { IERC3009 } from "./IERC3009.sol";

/// @title An ERC20 token extended with EIP-2612 permits for signed approvals (via EIP-712 and with EIP-1271
//         compatibility), and extended with EIP-3009 transfer with authorization (via EIP-712).
/// @dev   The additional interface as defined by EIP-2612: https://eips.ethereum.org/EIPS/eip-2612
interface IERC20Extended is IERC20, IERC3009 {
    /**
     * @notice Revert message when spender's allowance is not sufficient.
     * @param  spender    Address that may be allowed to operate on tokens without being their owner.
     * @param  allowance  Amount of tokens a `spender` is allowed to operate with.
     * @param  needed     Minimum amount required to perform a transfer.
     */
    error InsufficientAllowance(address spender, uint256 allowance, uint256 needed);

    /**
     * @notice Revert message emitted when the transferred amount is insufficient.
     * @param  amount Amount transferred.
     */
    error InsufficientAmount(uint256 amount);

    /**
     * @notice Revert message emitted when the recipient of a token is invalid.
     * @param  recipient Address of the invalid recipient.
     */
    error InvalidRecipient(address recipient);

    /**
     * @notice Approves `spender` to spend up to `amount` of the token balance of `owner`, via a signature.
     * @param  owner    The address of the account who's token balance is being approved to be spent by `spender`.
     * @param  spender  The address of an account allowed to spend on behalf of `owner`.
     * @param  value    The amount of the allowance being approved.
     * @param  deadline The last block number where the signature is still valid.
     * @param  v        An ECDSA secp256k1 signature parameter (EIP-2612 via EIP-712).
     * @param  r        An ECDSA secp256k1 signature parameter (EIP-2612 via EIP-712).
     * @param  s        An ECDSA secp256k1 signature parameter (EIP-2612 via EIP-712).
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @notice Approves `spender` to spend up to `amount` of the token balance of `owner`, via a signature.
     * @param  owner     The address of the account who's token balance is being approved to be spent by `spender`.
     * @param  spender   The address of an account allowed to spend on behalf of `owner`.
     * @param  value     The amount of the allowance being approved.
     * @param  deadline  The last block number where the signature is still valid.
     * @param  signature An arbitrary signature (EIP-712).
     */
    function permit(address owner, address spender, uint256 value, uint256 deadline, bytes memory signature) external;

    /// @notice Returns the EIP712 typehash used in the encoding of the digest for the permit function.
    function PERMIT_TYPEHASH() external view returns (bytes32 typehash);
}
