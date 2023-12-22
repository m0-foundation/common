// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.23;

import { ERC712 } from "../../src/ERC712.sol";
import { ERC20Permit } from "../../src/ERC20Permit.sol";

contract ERC20PermitHarness is ERC20Permit {
    mapping(address account => uint256 balance) internal _balances;

    uint256 _totalSupply;

    constructor(string memory name_, string memory symbol_, uint8 decimals_) ERC20Permit(name_, symbol_, decimals_) {}

    /******************************************************************************************************************\
    |                                       External/Public View/Pure Functions                                        |
    \******************************************************************************************************************/

    function balanceOf(address account_) external view returns (uint256) {
        return _balances[account_];
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function getDigest(bytes32 internalDigest_) external view returns (bytes32) {
        return _getDigest(internalDigest_);
    }

    /******************************************************************************************************************\
    |                                      External/Public Interactive Functions                                       |
    \******************************************************************************************************************/

    function mint(address account_, uint256 amount_) external {
        _transfer(address(0), account_, amount_);
    }

    function setAuthorizationState(address authorizer_, bytes32 nonce_, bool isNonceUsed_) external {
        authorizationState[authorizer_][nonce_] = isNonceUsed_;
    }

    /******************************************************************************************************************\
    |                                          Internal Interactive Functions                                          |
    \******************************************************************************************************************/

    function _transfer(address sender_, address recipient_, uint256 amount_) internal override {
        if (sender_ == address(0)) {
            _totalSupply += amount_;
        } else {
            unchecked {
                _balances[sender_] -= amount_;
            }
        }

        if (recipient_ == address(0)) {
            unchecked {
                _totalSupply -= amount_;
            }
        } else {
            unchecked {
                _balances[recipient_] += amount_;
            }
        }

        emit Transfer(sender_, recipient_, amount_);
    }
}
