// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.23;

/// @title Extension for EIP-712 to retrieve the EIP-712 domain.
interface IERC5267 {
    /// @notice MAY be emitted to signal that the domain could have changed.
    event EIP712DomainChanged();

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
