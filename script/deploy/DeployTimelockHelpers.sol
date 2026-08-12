// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.20 <0.9.0;

import { TimelockController } from "../../lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/governance/TimelockController.sol";

import { DeployHelpers } from "./DeployHelpers.sol";

abstract contract DeployTimelockHelpers is DeployHelpers {
    /// @notice A role to grant on a freshly deployed timelock.
    /// @param  role The role identifier.
    /// @param  account The account to grant the role to.
    struct GrantedRole {
        bytes32 role;
        address account;
    }

    /// @notice Deploys a TimelockController at a deterministic address via the CreateX factory (CREATE3).
    /// @dev    The resulting address depends only on the caller and the salt — not on the constructor arguments.
    /// @param  salt_ The salt used for the deterministic deployment.
    /// @param  minDelay_ The minimum delay for timelock operations.
    /// @param  proposers_ The accounts to grant proposer and canceller roles to.
    /// @param  executors_ The accounts to grant executor role to (use address(0) for open execution).
    /// @param  admin_ Optional admin with instant role powers, or address(0) for self-administration only.
    function _deployCreate3Timelock(
        bytes32 salt_,
        uint256 minDelay_,
        address[] memory proposers_,
        address[] memory executors_,
        address admin_
    ) internal returns (address) {
        return
            _deployCreate3(
                abi.encodePacked(
                    type(TimelockController).creationCode,
                    abi.encode(minDelay_, proposers_, executors_, admin_)
                ),
                salt_
            );
    }

    /// @notice Deploys a TimelockController via CREATE3, granting additional roles through a transient admin.
    /// @dev    Deploys with the deployer as admin, applies the given role grants, then renounces the admin role,
    ///         leaving the timelock self-administered. Must be called with `deployer_` as the message sender
    ///         (e.g. inside its broadcast).
    /// @param  salt_ The salt used for the deterministic deployment.
    /// @param  minDelay_ The minimum delay for timelock operations.
    /// @param  proposers_ The accounts to grant proposer and canceller roles to.
    /// @param  executors_ The accounts to grant executor role to (use address(0) for open execution).
    /// @param  deployer_ The deploying account, used as transient admin.
    /// @param  grantedRoles_ The additional roles to grant before renouncing the admin role.
    function _deployCreate3TimelockWithRolesGranted(
        bytes32 salt_,
        uint256 minDelay_,
        address[] memory proposers_,
        address[] memory executors_,
        address deployer_,
        GrantedRole[] memory grantedRoles_
    ) internal returns (address) {
        address timelockAddress = _deployCreate3Timelock(salt_, minDelay_, proposers_, executors_, deployer_);
        TimelockController timelock = TimelockController(payable(timelockAddress));

        for (uint256 i = 0; i < grantedRoles_.length; i++) {
            timelock.grantRole(grantedRoles_[i].role, grantedRoles_[i].account);
        }

        timelock.renounceRole(timelock.DEFAULT_ADMIN_ROLE(), deployer_);

        return timelockAddress;
    }
}
