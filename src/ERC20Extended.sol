// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.23;

import { IERC20 } from "./interfaces/IERC20.sol";
import { IERC20Extended } from "./interfaces/IERC20Extended.sol";
import { IERC5267 } from "./interfaces/IERC5267.sol";

import { ERC3009 } from "./ERC3009.sol";

/// @title An ERC20 token extended with EIP-2612 permits for signed approvals (via EIP-712 and with EIP-1271
///        and EIP-5267 compatibility), and extended with EIP-3009 transfer with authorization (via EIP-712).
abstract contract ERC20Extended is IERC20Extended, IERC5267, ERC3009 {
    /**
     * @inheritdoc IERC20Extended
     * @dev Keeping this constant, despite `permit` parameter name differences, to ensure max EIP-2612 compatibility.
     *      keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)")
     */
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    /// @inheritdoc IERC20
    uint8 public immutable decimals;

    /// @inheritdoc IERC20
    string public symbol;

    /// @inheritdoc IERC20
    mapping(address account => mapping(address spender => uint256 allowance)) public allowance;

    /**
     * @notice Constructs the ERC20Extended contract.
     * @param  name_     The name of the token.
     * @param  symbol_   The symbol of the token.
     * @param  decimals_ The number of decimals the token uses.
     */
    constructor(string memory name_, string memory symbol_, uint8 decimals_) ERC3009(name_) {
        symbol = symbol_;
        decimals = decimals_;
    }

    /******************************************************************************************************************\
    |                                      External/Public Interactive Functions                                       |
    \******************************************************************************************************************/

    /// @inheritdoc IERC20
    function approve(address spender_, uint256 amount_) external returns (bool success_) {
        _approve(msg.sender, spender_, amount_);

        emit Approval(msg.sender, spender_, amount_);

        return true;
    }

    /// @inheritdoc IERC5267
    function eip712Domain()
        external
        view
        virtual
        returns (
            bytes1 fields_,
            string memory name_,
            string memory version_,
            uint256 chainId_,
            address verifyingContract_,
            bytes32 salt_,
            uint256[] memory extensions_
        )
    {
        return (
            hex"0f", // 01111
            _name,
            "1",
            block.chainid,
            address(this),
            bytes32(0),
            new uint256[](0)
        );
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
        // NOTE: `_permit` returns the digest.
        _revertIfInvalidSignature(owner_, _permit(owner_, spender_, value_, deadline_), v_, r_, s_);
    }

    /// @inheritdoc IERC20Extended
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

    /// @inheritdoc IERC20
    function transfer(address recipient_, uint256 amount_) external returns (bool success_) {
        _transfer(msg.sender, recipient_, amount_);
        return true;
    }

    /// @inheritdoc IERC20
    function transferFrom(address sender_, address recipient_, uint256 amount_) external returns (bool success_) {
        uint256 spenderAllowance_ = allowance[sender_][msg.sender]; // Cache `spenderAllowance_` to stack.

        if (spenderAllowance_ != type(uint256).max) {
            _approve(sender_, msg.sender, spenderAllowance_ - amount_);
        }

        _transfer(sender_, recipient_, amount_);

        return true;
    }

    /******************************************************************************************************************\
    |                                       External/Public View/Pure Functions                                        |
    \******************************************************************************************************************/

    /// @inheritdoc IERC20
    function balanceOf(address account_) external view virtual returns (uint256) {}

    /// @inheritdoc IERC20
    function name() external view returns (string memory name_) {
        return _name;
    }

    /// @inheritdoc IERC20
    function totalSupply() external view virtual returns (uint256);

    /******************************************************************************************************************\
    |                                          Internal Interactive Functions                                          |
    \******************************************************************************************************************/

    function _approve(address account_, address spender_, uint256 amount_) internal virtual {
        allowance[account_][spender_] = amount_;
    }

    function _permit(
        address owner_,
        address spender_,
        uint256 amount_,
        uint256 deadline_
    ) internal virtual returns (bytes32 digest_) {
        _revertIfExpired(deadline_);

        uint256 nonce_ = nonces[owner_]; // Cache `nonce_` to stack.

        unchecked {
            nonces[owner_] = nonce_ + 1; // Nonce realistically cannot overflow.
        }

        _approve(owner_, spender_, amount_);

        return _getDigest(keccak256(abi.encode(PERMIT_TYPEHASH, owner_, spender_, amount_, nonce_, deadline_)));
    }
}
