// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.20 <0.9.0;

import { IStatefulERC712 } from "./interfaces/IStatefulERC712.sol";

import { ERC712ExtendedUpgradeable } from "./ERC712ExtendedUpgradeable.sol";

abstract contract StatefulERC712ExtendedUpgradeableStorageLayout {
    /// @custom:storage-location erc7201:M0.storage.StatefulERC712Extended
    struct StatefulERC712ExtendedStorageStruct {
        mapping(address account => uint256 nonce) nonces; // Nonces for all signatures.
    }

    // keccak256(abi.encode(uint256(keccak256("M0.storage.StatefulERC712Extended")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant _STATEFUL_ERC712_EXTENDED_STORAGE_LOCATION =
        0x1b21ba3f0a2135d61c468900b54084f04af8111bce0f8bbb6ab8c46d11afbd00;

    function _getStatefulERC712ExtendedStorageLocation()
        internal
        pure
        returns (StatefulERC712ExtendedStorageStruct storage $)
    {
        assembly {
            $.slot := _STATEFUL_ERC712_EXTENDED_STORAGE_LOCATION
        }
    }
}

/**
 * @title  Stateful and upgradeable extension for EIP-712 typed structured data hashing and signing with nonces.
 * @author M0 Labs
 * @dev    An abstract implementation to satisfy stateful EIP-712 with nonces.
 */
abstract contract StatefulERC712Upgradeable is
    StatefulERC712ExtendedUpgradeableStorageLayout,
    IStatefulERC712,
    ERC712ExtendedUpgradeable
{
    /* ============ Initializer ============ */

    /**
     * @notice Initializes the StatefulERC712Upgradeable contract.
     * @param  name The name of the contract.
     */
    function __StatefulERC712ExtendedUpgradeable_init(string memory name) internal onlyInitializing {
        __ERC712ExtendedUpgradeable_init(name);
    }

    /* ============ View/Pure Functions ============ */

    /// @inheritdoc IStatefulERC712
    function nonces(address account) external view returns (uint256) {
        return _getStatefulERC712ExtendedStorageLocation().nonces[account];
    }
}
