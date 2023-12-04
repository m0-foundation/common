// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.23;

import { IERC20 } from "./IERC20.sol";
import { IStatefulERC712 } from "./IStatefulERC712.sol";

/// @title Permit Extension for ERC20 Signed Approvals via EIP-712 with EIP-2612 and EIP-1271 compatibility.
/// @dev   The interface as defined by EIP-2612: https://eips.ethereum.org/EIPS/eip-2612
interface IERC20Permit is IERC20, IStatefulERC712 {
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
