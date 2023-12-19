// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.23;

import { IERC712Domain } from "./interfaces/IERC712Domain.sol";
import { ERC712 } from "./libs/ERC712.sol";

/// @title EIP-712 domain separator.
/// @dev   The domain separator as defined by EIP-712: https://eips.ethereum.org/EIPS/eip-712
abstract contract ERC712Domain is IERC712Domain {
    /// @dev Initial Chain ID set at deployment.
    uint256 internal immutable INITIAL_CHAIN_ID;

    /// @dev Initial EIP-712 domain separator set at deployment.
    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    /// @dev The name of the contract.
    string internal _name;

    /**
     * @notice Constructs the EIP-712 domain separator.
     * @param  name_ The name of the contract.
     */
    constructor(string memory name_) {
        _name = name_;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = ERC712.computeDomainSeparator(name_);
    }

    /******************************************************************************************************************\
    |                                             Public View/Pure Functions                                           |
    \******************************************************************************************************************/

    /// @inheritdoc IERC712Domain
    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : ERC712.computeDomainSeparator(_name);
    }
}
