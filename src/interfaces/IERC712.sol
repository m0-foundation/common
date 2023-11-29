// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.21;

import { IStatelessERC712 } from "./IStatelessERC712.sol";

interface IERC712 is IStatelessERC712 {
    error ReusedNonce(uint256 nonce, uint256 currentNonce);

    function nonces(address account) external view returns (uint256 nonce);
}
