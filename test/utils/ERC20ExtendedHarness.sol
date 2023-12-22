// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.23;

import { ERC712 } from "../../src/ERC712.sol";
import { ERC20Extended } from "../../src/ERC20Extended.sol";

contract ERC20ExtendedHarness is ERC20Extended {
    constructor(string memory name_, string memory symbol_, uint8 decimals_) ERC20Extended(name_, symbol_, decimals_) {}

    /******************************************************************************************************************\
    |                                      External/Public Interactive Functions                                       |
    \******************************************************************************************************************/

    function setAuthorizationState(address authorizer_, bytes32 nonce_, bool isNonceUsed_) external {
        authorizationState[authorizer_][nonce_] = isNonceUsed_;
    }

    /******************************************************************************************************************\
    |                                       External/Public View/Pure Functions                                        |
    \******************************************************************************************************************/

    function balanceOf(address account_) external view returns (uint256) {}

    function totalSupply() external view returns (uint256) {}

    function getDigest(bytes32 internalDigest_) external view returns (bytes32) {
        return _getDigest(internalDigest_);
    }

    /******************************************************************************************************************\
    |                                          Internal Interactive Functions                                          |
    \******************************************************************************************************************/

    function _transfer(address sender_, address recipient_, uint256 amount_) internal override {}
}
