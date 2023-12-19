// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.23;

import { ERC20Permit } from "../../src/ERC20Permit.sol";
import { ERC3009 } from "../../src/ERC3009.sol";

contract ERC3009Harness is ERC20Permit, ERC3009 {
    mapping(address account => uint256 balance) internal _balances;

    uint256 _totalSupply;

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) ERC20Permit(name_, symbol_, decimals_) ERC3009(name_) {}

    function balanceOf(address account_) external view returns (uint256) {
        return _balances[account_];
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function getDigest(bytes32 internalDigest_) external view returns (bytes32) {
        return _getDigest(internalDigest_);
    }

    function setAuthorizationState(address authorizer_, bytes32 nonce_, bool isNonceUsed_) external {
        _authorizationStates[authorizer_][nonce_] = isNonceUsed_;
    }

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
    }
}
