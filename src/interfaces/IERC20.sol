// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.26;

/**
 * @title  ERC20 Token Standard.
 * @author M^0 Labs
 * @dev    The interface as defined by EIP-20: https://eips.ethereum.org/EIPS/eip-20
 */
interface IERC20 {
    /* ============ Events ============ */

    /**
     * @notice Emitted when `spender` has been approved for `amount` of the token balance of `account`.
     * @param  account The address of the account.
     * @param  spender The address of the spender being approved for the allowance.
     * @param  amount  The amount of the allowance being approved.
     */
    event Approval(address indexed account, address indexed spender, uint256 amount);

    /**
     * @notice Emitted when `amount` tokens is transferred from `sender` to `recipient`.
     * @param  sender    The address of the sender who's token balance is decremented.
     * @param  recipient The address of the recipient who's token balance is incremented.
     * @param  amount    The amount of tokens being transferred.
     */
    event Transfer(address indexed sender, address indexed recipient, uint256 amount);

    /* ============ Interactive Functions ============ */

    /**
     * @notice Allows a calling account to approve `spender` to spend up to `amount` of its token balance.
     * @dev    MUST emit an `Approval` event.
     * @param  spender The address of the account being allowed to spend up to the allowed amount.
     * @param  amount  The amount of the allowance being approved.
     * @return Whether or not the approval was successful.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @notice Allows a calling account to transfer `amount` tokens to `recipient`.
     * @param  recipient The address of the recipient who's token balance will be incremented.
     * @param  amount    The amount of tokens being transferred.
     * @return Whether or not the transfer was successful.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @notice Allows a calling account to transfer `amount` tokens from `sender`, with allowance, to a `recipient`.
     * @param  sender    The address of the sender who's token balance will be decremented.
     * @param  recipient The address of the recipient who's token balance will be incremented.
     * @param  amount    The amount of tokens being transferred.
     * @return Whether or not the transfer was successful.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /* ============ View/Pure Functions ============ */

    /**
     * @notice Returns the allowance `spender` is allowed to spend on behalf of `account`.
     * @param  account The address of the account who's token balance `spender` is allowed to spend.
     * @param  spender The address of an account allowed to spend on behalf of `account`.
     * @return The amount `spender` can spend on behalf of `account`.
     */
    function allowance(address account, address spender) external view returns (uint256);

    /**
     * @notice Returns the token balance of `account`.
     * @param  account The address of some account.
     * @return The token balance of `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /// @notice Returns the number of decimals UIs should assume all amounts have.
    function decimals() external view returns (uint8);

    /// @notice Returns the name of the contract/token.
    function name() external view returns (string memory);

    /// @notice Returns the symbol of the token.
    function symbol() external view returns (string memory);

    /// @notice Returns the current total supply of the token.
    function totalSupply() external view returns (uint256);
}
