// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.20 <0.9.0;

import { IERC712 } from "./IERC712.sol";

/**
 * @title  EIP-712 extended by EIP-5267.
 * @author M^0 Labs
 * @dev    The additional interface as defined by EIP-5267: https://eips.ethereum.org/EIPS/eip-5267
 */
interface IERC712Extended is IERC712 {
    /* ============ Events ============ */

    /// @notice MAY be emitted to signal that the domain could have changed.
    event EIP712DomainChanged();

    /* ============ View/Pure Functions ============ */

    /// @notice Returns the fields and values that describe the domain separator used by this contract for EIP-712.
    function eip712Domain()
        external
        view
        returns (
            bytes1 fields,
            string memory name,
            string memory version,
            uint256 chainId,
            address verifyingContract,
            bytes32 salt,
            uint256[] memory extensions
        );
}
