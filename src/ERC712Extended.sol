// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.23;

import { IERC5267 } from "./interfaces/IERC5267.sol";

import { ERC712 } from "./ERC712.sol";

/// @title Typed structured data hashing and signing via EIP-712,
///        extended with EIP-5267 to describe and retrieve EIP-712 domain.
abstract contract ERC712Extended is ERC712, IERC5267 {
    /**
     * @notice Constructs ERC712Extended.
     * @param  name_ The name of the contract.
     */
    constructor(string memory name_) ERC712(name_) {}

    /******************************************************************************************************************\
    |                                             Public View/Pure Functions                                           |
    \******************************************************************************************************************/

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
}
