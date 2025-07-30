// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.20 <0.9.0;

import { TransparentUpgradeableProxy } from "../../lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import { ICreateXLike } from "./interfaces/ICreateXLike.sol";

abstract contract DeployHelpers {
    /// @dev Same address across all supported mainnet and testnets networks.
    address public constant CREATE_X_FACTORY = 0xba5Ed099633D3B313e4D5F7bdc1305d3c28ba5Ed;

    function _deployCreate3(bytes memory initCode, bytes32 salt) internal returns (address) {
        return ICreateXLike(CREATE_X_FACTORY).deployCreate3(salt, initCode);
    }

    function _deployCreate3TransparentProxy(
        address implementation,
        address initialOwner,
        bytes memory initializerData,
        bytes32 salt
    ) internal returns (address) {
        return
            ICreateXLike(CREATE_X_FACTORY).deployCreate3(
                salt,
                abi.encodePacked(
                    type(TransparentUpgradeableProxy).creationCode,
                    abi.encode(implementation, initialOwner, initializerData)
                )
            );
    }

    function _computeSalt(address deployer, string memory contractName) internal pure returns (bytes32) {
        return
            bytes32(
                abi.encodePacked(
                    bytes20(deployer), // used to implement permissioned deploy protection
                    bytes1(0), // disable cross-chain redeploy protection
                    bytes11(keccak256(bytes(contractName)))
                )
            );
    }

    function _computeGuardedSalt(address deployer, bytes32 salt) internal pure returns (bytes32) {
        return _efficientHash({ a: bytes32(uint256(uint160(deployer))), b: salt });
    }

    /**
     * @dev Returns the `keccak256` hash of `a` and `b` after concatenation.
     * @param a The first 32-byte value to be concatenated and hashed.
     * @param b The second 32-byte value to be concatenated and hashed.
     * @return hash The 32-byte `keccak256` hash of `a` and `b`.
     */
    function _efficientHash(bytes32 a, bytes32 b) internal pure returns (bytes32 hash) {
        assembly ("memory-safe") {
            mstore(0x00, a)
            mstore(0x20, b)
            hash := keccak256(0x00, 0x40)
        }
    }

    function _getCreate3Address(address deployer, bytes32 salt) internal view virtual returns (address) {
        return ICreateXLike(CREATE_X_FACTORY).computeCreate3Address(_computeGuardedSalt(deployer, salt));
    }
}
