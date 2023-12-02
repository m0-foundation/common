// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.21;

import { IERC20Permit } from "./interfaces/IERC20Permit.sol";

import { ERC712 } from "./ERC712.sol";

// TODO: Consider changing `owner/account`, `value/amount`, `expiry/deadline`, and thus the typehash literals.

abstract contract ERC20Permit is IERC20Permit, ERC712 {
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)")
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    string public symbol;

    uint8 public immutable decimals;

    mapping(address account => mapping(address spender => uint256 allowance)) internal _allowance;

    constructor(string memory name_, string memory symbol_, uint8 decimals_) ERC712(name_) {
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
        uint256 amount_,
        uint256 deadline_,
        uint8 v_,
        bytes32 r_,
        bytes32 s_
    ) external {
        _revertIfInvalidSignature(owner_, _permit(owner_, spender_, amount_, deadline_), v_, r_, s_);
    }

    function permit(
        address owner_,
        address spender_,
        uint256 amount_,
        uint256 deadline_,
        bytes memory signature_
    ) external {
        _revertIfInvalidSignature(owner_, _permit(owner_, spender_, amount_, deadline_), signature_);
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

    function allowance(address account_, address spender_) external view returns (uint256 allowance_) {
        return _allowance[account_][spender_];
    }

    function balanceOf(address account_) external view virtual returns (uint256 balance_);

    function name() external view returns (string memory name_) {
        return _name;
    }

    function totalSupply() external view virtual returns (uint256 totalSupply_);

    /******************************************************************************************************************\
    |                                          Internal Interactive Functions                                          |
    \******************************************************************************************************************/

    function _approve(address account_, address spender_, uint256 amount_) internal virtual {
        emit Approval(account_, spender_, _allowance[account_][spender_] = amount_);
    }

    function _decreaseAllowance(address account_, address spender_, uint256 subtractedAmount_) internal virtual {
        if (subtractedAmount_ == 0) return;

        uint256 spenderAllowance_ = _allowance[account_][spender_]; // Cache to memory.

        if (spenderAllowance_ == type(uint256).max) return;

        _approve(account_, spender_, spenderAllowance_ - subtractedAmount_);
    }

    function _increaseAllowance(address account_, address spender_, uint256 addedAmount_) internal virtual {
        if (addedAmount_ == 0) return;

        uint256 spenderAllowance_ = _allowance[account_][spender_]; // Cache to memory.

        if (spenderAllowance_ == type(uint256).max) return;

        _approve(account_, spender_, spenderAllowance_ + addedAmount_);
    }

    function _permit(
        address owner_,
        address spender_,
        uint256 amount_,
        uint256 deadline_
    ) internal virtual returns (bytes32 digest_) {
        _revertIfExpired(deadline_);

        uint256 currentNonce_ = _nonces[owner_];

        unchecked {
            _nonces[owner_] = currentNonce_ + 1; // Nonce realistically cannot overflow.
        }

        _approve(owner_, spender_, amount_);

        return _getPermitDigest(owner_, spender_, amount_, currentNonce_, deadline_);
    }

    function _transfer(address sender_, address recipient_, uint256 amount_) internal virtual;

    /******************************************************************************************************************\
    |                                           Internal View/Pure Functions                                           |
    \******************************************************************************************************************/

    function _getPermitDigest(
        address owner_,
        address spender_,
        uint256 amount_,
        uint256 nonce_,
        uint256 deadline_
    ) internal view returns (bytes32 digest_) {
        return _getDigest(keccak256(abi.encode(PERMIT_TYPEHASH, owner_, spender_, amount_, nonce_, deadline_)));
    }
}
