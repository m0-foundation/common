// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.23;

import { IERC20Permit } from "./interfaces/IERC20Permit.sol";

import { StatefulERC712 } from "./StatefulERC712.sol";

/// @title Permit Extension for ERC20 Signed Approvals via EIP-712 with EIP-2612 and EIP-1271 compatibility.
/// @dev   An abstract implementation to satisfy EIP-2612: https://eips.ethereum.org/EIPS/eip-2612
abstract contract ERC20Permit is IERC20Permit, StatefulERC712 {
    // NOTE: Keeping this constant, despite `permit` parameter name differences, to ensure max EIP-2612 compatibility.
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)")
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    string public symbol;

    uint8 public immutable decimals;

    mapping(address account => mapping(address spender => uint256 allowance)) public allowance;

    constructor(string memory name_, string memory symbol_, uint8 decimals_) StatefulERC712(name_) {
        symbol = symbol_;
        decimals = decimals_;
    }

    /******************************************************************************************************************\
    |                                      External/Public Interactive Functions                                       |
    \******************************************************************************************************************/

    function approve(address spender_, uint256 amount_) external returns (bool success_) {
        _approve(msg.sender, spender_, amount_);
        return true;
    }

    function decreaseAllowance(address spender_, uint256 subtractedAmount_) external returns (bool success_) {
        _decreaseAllowance(msg.sender, spender_, subtractedAmount_);
        return true;
    }

    function increaseAllowance(address spender_, uint256 addedAmount_) external returns (bool success_) {
        _increaseAllowance(msg.sender, spender_, addedAmount_);
        return true;
    }

    function permit(
        address owner_,
        address spender_,
        uint256 value_,
        uint256 deadline_,
        uint8 v_,
        bytes32 r_,
        bytes32 s_
    ) external {
        // NOTE: `_permit` returns the digest.
        _revertIfInvalidSignature(owner_, _permit(owner_, spender_, value_, deadline_), v_, r_, s_);
    }

    function permit(
        address owner_,
        address spender_,
        uint256 value_,
        uint256 deadline_,
        bytes memory signature_
    ) external {
        // NOTE: `_permit` returns the digest.
        _revertIfInvalidSignature(owner_, _permit(owner_, spender_, value_, deadline_), signature_);
    }

    function transfer(address recipient_, uint256 amount_) external returns (bool success_) {
        _transfer(msg.sender, recipient_, amount_);
        return true;
    }

    function transferFrom(address sender_, address recipient_, uint256 amount_) external returns (bool success_) {
        _decreaseAllowance(sender_, msg.sender, amount_);
        _transfer(sender_, recipient_, amount_);
        return true;
    }

    /******************************************************************************************************************\
    |                                       External/Public View/Pure Functions                                        |
    \******************************************************************************************************************/

    function name() external view returns (string memory name_) {
        return _name;
    }

    /******************************************************************************************************************\
    |                                          Internal Interactive Functions                                          |
    \******************************************************************************************************************/

    function _approve(address account_, address spender_, uint256 amount_) internal virtual {
        emit Approval(account_, spender_, allowance[account_][spender_] = amount_);
    }

    function _decreaseAllowance(address account_, address spender_, uint256 subtractedAmount_) internal virtual {
        if (subtractedAmount_ == 0) return; // No failure for no-op due to 0 decrease.

        uint256 spenderAllowance_ = allowance[account_][spender_]; // Cache `spenderAllowance_` to stack.

        if (spenderAllowance_ == type(uint256).max) return; // No failure for no-op due to infinite allowance.

        _approve(account_, spender_, spenderAllowance_ - subtractedAmount_);
    }

    function _increaseAllowance(address account_, address spender_, uint256 addedAmount_) internal virtual {
        if (addedAmount_ == 0) return; // No failure for no-op due to 0 increase.

        uint256 spenderAllowance_ = allowance[account_][spender_]; // Cache `spenderAllowance_` to stack.

        if (spenderAllowance_ == type(uint256).max) return; // No failure for no-op due to infinite allowance.

        _approve(account_, spender_, spenderAllowance_ + addedAmount_);
    }

    function _permit(
        address owner_,
        address spender_,
        uint256 amount_,
        uint256 deadline_
    ) internal virtual returns (bytes32 digest_) {
        _revertIfExpired(deadline_);

        uint256 currentNonce_ = _nonces[owner_]; // Cache `currentNonce_` to stack.

        unchecked {
            _nonces[owner_] = currentNonce_ + 1; // Nonce realistically cannot overflow.
        }

        _approve(owner_, spender_, amount_);

        return _getDigest(keccak256(abi.encode(PERMIT_TYPEHASH, owner_, spender_, amount_, currentNonce_, deadline_)));
    }

    function _transfer(address sender_, address recipient_, uint256 amount_) internal virtual;
}
