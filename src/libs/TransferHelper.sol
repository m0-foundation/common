// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

import {IERC20} from "../interfaces/IERC20.sol";

/// @notice Safe ERC20 transfer library that safely handles missing return values.
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v3-periphery/blob/main/contracts/libraries/TransferHelper.sol)
/// @dev    Only change from Uniswap is the addition of the "safeTransferExact*" function variants which check that there was no fee on transfer.
library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @dev Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            address(token).call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "STF");
    }

    /// @notice Transfer tokens from the targeted address to the given destination with a balance check
    /// @dev Errors with 'STFE' if transfer fails or there is a fee on transfer
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferExactFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        uint256 balanceBefore = token.balanceOf(to);
        safeTransferFrom(token, from, to, value);
        require(token.balanceOf(to) - balanceBefore >= value, "STFE");
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "ST");
    }

    /// @notice Transfer tokens from msg.sender to a recipient with a balance check
    /// @dev Errors with 'STE' if transfer fails or there is a fee on transfer
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransferExact(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        uint256 balanceBefore = token.balanceOf(to);
        safeTransfer(token, to, value);
        require(token.balanceOf(to) - balanceBefore >= value, "STE");
    }

    /// @notice Approves the stipulated contract to spend the given allowance in the given token
    /// @dev Errors with 'SA' if transfer fails
    /// @param token The contract address of the token to be approved
    /// @param to The target of the approval
    /// @param value The amount of the given token the target will be allowed to spend
    function safeApprove(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "SA");
    }
}
