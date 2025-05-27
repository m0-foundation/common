// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.20 <0.9.0;

import { ERC3009Upgradeable } from "./ERC3009Upgradeable.sol";

import { IERC20 } from "./interfaces/IERC20.sol";
import { IERC20Extended } from "./interfaces/IERC20Extended.sol";

abstract contract ERC20ExtendedUpgradeableStorageLayout {
    /// @custom:storage-location erc7201:M0.storage.ERC20Extended
    struct ERC20ExtendedStorageStruct {
        mapping(address account => mapping(address spender => uint256 allowance)) allowance;
        uint8 decimals;
        string symbol;
    }

    // keccak256(abi.encode(uint256(keccak256("M0.storage.ERC20Extended")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant _ERC20_EXTENDED_STORAGE_LOCATION =
        0xcbbe23efb65c1eaba394256c463812c20abdb5376e247eba1d0e1e92054da100;

    function _getERC20ExtendedStorageLocation() internal pure returns (ERC20ExtendedStorageStruct storage $) {
        assembly {
            $.slot := _ERC20_EXTENDED_STORAGE_LOCATION
        }
    }
}

/**
 * @title  An upgradeable ERC20 token extended with EIP-2612 permits for signed approvals
 *         (via EIP-712 and with EIP-1271 and EIP-5267 compatibility).
 * @author M0 Labs
 */
abstract contract ERC20ExtendedUpgradeable is
    ERC20ExtendedUpgradeableStorageLayout,
    ERC3009Upgradeable,
    IERC20Extended
{
    /* ============ Variables ============ */

    /**
     * @inheritdoc IERC20Extended
     * @dev Keeping this constant, despite `permit` parameter name differences, to ensure max EIP-2612 compatibility.
     *      keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)")
     */
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    /* ============ Initializer ============ */

    function __ERC20ExtendedUpgradeable_init(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) internal onlyInitializing {
        __ERC3009Upgradeable_init(name_);

        ERC20ExtendedStorageStruct storage $ = _getERC20ExtendedStorageLocation();

        $.decimals = decimals_;
        $.symbol = symbol_;
    }

    /* ============ Interactive Functions ============ */

    /// @inheritdoc IERC20
    function approve(address spender_, uint256 amount_) external returns (bool) {
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
    function transfer(address recipient_, uint256 amount_) external returns (bool) {
        _transfer(msg.sender, recipient_, amount_);
        return true;
    }

    /// @inheritdoc IERC20
    function transferFrom(address sender_, address recipient_, uint256 amount_) external returns (bool) {
        ERC20ExtendedStorageStruct storage $ = _getERC20ExtendedStorageLocation();
        uint256 spenderAllowance_ = $.allowance[sender_][msg.sender]; // Cache `spenderAllowance_` to stack.

        if (spenderAllowance_ != type(uint256).max) {
            if (spenderAllowance_ < amount_) revert InsufficientAllowance(msg.sender, spenderAllowance_, amount_);

            unchecked {
                _setAllowance($, sender_, msg.sender, spenderAllowance_ - amount_);
            }
        }

        _transfer(sender_, recipient_, amount_);

        return true;
    }

    /* ============ View/Pure Functions ============ */

    /// @inheritdoc IERC20
    function allowance(address account, address spender) public view returns (uint256) {
        return _getERC20ExtendedStorageLocation().allowance[account][spender];
    }

    /// @inheritdoc IERC20
    function decimals() external view virtual returns (uint8) {
        return _getERC20ExtendedStorageLocation().decimals;
    }

    /// @inheritdoc IERC20
    function name() external view virtual returns (string memory) {
        return _getERC712ExtendedStorageLocation().name;
    }

    /// @inheritdoc IERC20
    function symbol() external view virtual returns (string memory) {
        return _getERC20ExtendedStorageLocation().symbol;
    }

    /* ============ Internal Interactive Functions ============ */

    /**
     * @dev Approve `spender_` to spend `amount_` of tokens from `account_`.
     * @param  account_ The address approving the allowance.
     * @param  spender_ The address approved to spend the tokens.
     * @param  amount_  The amount of tokens being approved for spending.
     */
    function _approve(address account_, address spender_, uint256 amount_) internal virtual {
        _setAllowance(_getERC20ExtendedStorageLocation(), account_, spender_, amount_);
        emit Approval(account_, spender_, amount_);
    }

    /**
     * @dev Set the `amount_` of tokens `spender_` is allowed to spend from `account_`.
     * @param $         ERC20Extended storage location.
     * @param  account_ The address for which the allowance is set.
     * @param  spender_ The address allowed to spend the tokens.
     * @param  amount_  The amount of tokens being allowed for spending.
     */
    function _setAllowance(
        ERC20ExtendedStorageStruct storage $,
        address account_,
        address spender_,
        uint256 amount_
    ) internal virtual {
        $.allowance[account_][spender_] = amount_;
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
    ) internal virtual returns (bytes32) {
        _revertIfExpired(deadline_);

        _approve(owner_, spender_, amount_);

        unchecked {
            // Nonce realistically cannot overflow.
            return
                _getDigest(
                    keccak256(
                        abi.encode(
                            PERMIT_TYPEHASH,
                            owner_,
                            spender_,
                            amount_,
                            _getStatefulERC712ExtendedStorageLocation().nonces[owner_]++,
                            deadline_
                        )
                    )
                );
        }
    }
}
