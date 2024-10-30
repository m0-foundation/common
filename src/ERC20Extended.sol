// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.20 <0.9.0;

import { IERC20 } from "./interfaces/IERC20.sol";
import { IERC20Extended } from "./interfaces/IERC20Extended.sol";

import { Bytes32String } from "./libs/Bytes32String.sol";

import { ERC3009 } from "./ERC3009.sol";

/**
 * @title  An ERC20 token extended with EIP-2612 permits for signed approvals (via EIP-712 and with EIP-1271
 *         and EIP-5267 compatibility), and extended with EIP-3009 transfer with authorization (via EIP-712).
 * @author M^0 Labs
 */
abstract contract ERC20Extended is IERC20Extended, ERC3009 {
    /* ============ Variables ============ */

    /**
     * @inheritdoc IERC20Extended
     * @dev Keeping this constant, despite `permit` parameter name differences, to ensure max EIP-2612 compatibility.
     *      keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)")
     */
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    /// @inheritdoc IERC20
    uint8 public immutable decimals;

    /// @dev The symbol of the token (stored as a bytes32 instead of a string in order to be immutable).
    bytes32 internal immutable _symbol;

    /// @inheritdoc IERC20
    mapping(address account => mapping(address spender => uint256 allowance)) public allowance;

    /* ============ Constructor ============ */

    /**
     * @notice Constructs the ERC20Extended contract.
     * @param  name_     The name of the token.
     * @param  symbol_   The symbol of the token.
     * @param  decimals_ The number of decimals the token uses.
     */
    constructor(string memory name_, string memory symbol_, uint8 decimals_) ERC3009(name_) {
        _symbol = Bytes32String.toBytes32(symbol_);
        decimals = decimals_;
    }

    /* ============ Interactive Functions ============ */

    /// @inheritdoc IERC20
    function approve(address spender_, uint256 amount_) external returns (bool success_) {
        _approve(msg.sender, spender_, amount_);
        return true;
    }

    /// @inheritdoc IERC20Extended
    function permit(
        address owner_,
        address spender_,
        uint256 value_,
        uint256 deadline_,
        uint8 v_,
        bytes32 r_,
        bytes32 s_
    ) external {
        _revertIfInvalidSignature(owner_, _permitAndGetDigest(owner_, spender_, value_, deadline_), v_, r_, s_);
    }

    /// @inheritdoc IERC20Extended
    function permit(
        address owner_,
        address spender_,
        uint256 value_,
        uint256 deadline_,
        bytes memory signature_
    ) external {
        _revertIfInvalidSignature(owner_, _permitAndGetDigest(owner_, spender_, value_, deadline_), signature_);
    }

    /// @inheritdoc IERC20
    function transfer(address recipient_, uint256 amount_) external returns (bool success_) {
        _transfer(msg.sender, recipient_, amount_);
        return true;
    }

    /// @inheritdoc IERC20
    function transferFrom(address sender_, address recipient_, uint256 amount_) external returns (bool success_) {
        uint256 spenderAllowance_ = allowance[sender_][msg.sender]; // Cache `spenderAllowance_` to stack.

        if (spenderAllowance_ != type(uint256).max) {
            if (spenderAllowance_ < amount_) revert InsufficientAllowance(msg.sender, spenderAllowance_, amount_);

            unchecked {
                _setAllowance(sender_, msg.sender, spenderAllowance_ - amount_);
            }
        }

        _transfer(sender_, recipient_, amount_);

        return true;
    }

    /* ============ View/Pure Functions ============ */

    /// @inheritdoc IERC20
    function name() external view returns (string memory) {
        return Bytes32String.toString(_name);
    }

    /// @inheritdoc IERC20
    function symbol() external view returns (string memory) {
        return Bytes32String.toString(_symbol);
    }

    /* ============ Internal Interactive Functions ============ */

    /**
     * @dev Approve `spender_` to spend `amount_` of tokens from `account_`.
     * @param  account_ The address approving the allowance.
     * @param  spender_ The address approved to spend the tokens.
     * @param  amount_  The amount of tokens being approved for spending.
     */
    function _approve(address account_, address spender_, uint256 amount_) internal virtual {
        _setAllowance(account_, spender_, amount_);
        emit Approval(account_, spender_, amount_);
    }

    /**
     * @dev Set the `amount_` of tokens `spender_` is allowed to spend from `account_`.
     * @param  account_ The address for which the allowance is set.
     * @param  spender_ The address allowed to spend the tokens.
     * @param  amount_  The amount of tokens being allowed for spending.
     */
    function _setAllowance(address account_, address spender_, uint256 amount_) internal virtual {
        allowance[account_][spender_] = amount_;
    }

    /**
     * @dev    Performs the approval based on the permit info, validates the deadline, and returns the digest.
     * @param  owner_    The address of the account approving the allowance.
     * @param  spender_  The address of the account being allowed to spend the tokens.
     * @param  amount_   The amount of tokens being approved for spending.
     * @param  deadline_ The deadline by which the signature must be used.
     * @return digest_   The EIP-712 digest of the permit.
     */
    function _permitAndGetDigest(
        address owner_,
        address spender_,
        uint256 amount_,
        uint256 deadline_
    ) internal virtual returns (bytes32 digest_) {
        _revertIfExpired(deadline_);

        _approve(owner_, spender_, amount_);

        unchecked {
            // Nonce realistically cannot overflow.
            return
                _getDigest(
                    keccak256(abi.encode(PERMIT_TYPEHASH, owner_, spender_, amount_, nonces[owner_]++, deadline_))
                );
        }
    }
}
