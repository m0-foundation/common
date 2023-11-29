// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.21;

import { IERC712 } from "./interfaces/IERC712.sol";

import { StatelessERC712 } from "./StatelessERC712.sol";

abstract contract ERC712 is IERC712, StatelessERC712 {
    mapping(address account => uint256 nonce) internal _nonces; // Nonces for all signatures.

    constructor(string memory name_) StatelessERC712(name_) {}

    /******************************************************************************************************************\
    |                                       External/Public View/Pure Functions                                        |
    \******************************************************************************************************************/

    function nonces(address account_) external view returns (uint256 nonce_) {
        return _nonces[account_];
    }

}
