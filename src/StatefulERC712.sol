// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.20 <0.9.0;

import { IStatefulERC712 } from "./interfaces/IStatefulERC712.sol";

import { ERC712Extended } from "./ERC712Extended.sol";

/**
 * @title  Stateful Extension for EIP-712 typed structured data hashing and signing with nonces.
 * @author M^0 Labs
 * @dev    An abstract implementation to satisfy stateful EIP-712 with nonces.
 */
abstract contract StatefulERC712 is IStatefulERC712, ERC712Extended {
    /// @inheritdoc IStatefulERC712
    mapping(address account => uint256 nonce) public nonces; // Nonces for all signatures.

    /**
     * @notice Construct the StatefulERC712 contract.
     * @param  name_ The name of the contract.
     */
    constructor(string memory name_) ERC712Extended(name_) {}
}
