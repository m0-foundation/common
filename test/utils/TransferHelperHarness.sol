// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.20 <0.9.0;

import { TransferHelper } from "../../src/libs/TransferHelper.sol";
import { IERC20 } from "../../src/interfaces/IERC20.sol";

/// @title TransferHelper harness used to correctly display test coverage.
contract TransferHelperHarness {
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) external {
        TransferHelper.safeTransferFrom(token, from, to, value);
    }

    function safeTransferExactFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) external {
        TransferHelper.safeTransferExactFrom(token, from, to, value);
    }

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) external {
        TransferHelper.safeTransfer(token, to, value);
    }

    function safeTransferExact(
        IERC20 token,
        address to,
        uint256 value
    ) external {
        TransferHelper.safeTransferExact(token, to, value);
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) external {
        TransferHelper.safeApprove(token, spender, value);
    }
}
