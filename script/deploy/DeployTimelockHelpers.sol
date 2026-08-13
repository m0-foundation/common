// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.20 <0.9.0;

import { TimelockController } from "@openzeppelin/contracts/governance/TimelockController.sol";

import { DeployHelpers } from "./DeployHelpers.sol";

abstract contract DeployTimelockHelpers is DeployHelpers {
    /// @notice A role to grant on a freshly deployed timelock.
    /// @param  role The role identifier.
    /// @param  account The account to grant the role to.
    struct GrantedRole {
        bytes32 role;
        address account;
    }

    /// @notice Thrown when a role grant would assign the admin role, which survives the admin renounce.
    error AdminRoleGrantNotAllowed();

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

        bytes32 adminRole = timelock.DEFAULT_ADMIN_ROLE();

        for (uint256 i = 0; i < grantedRoles_.length; i++) {
            if (grantedRoles_[i].role == adminRole) revert AdminRoleGrantNotAllowed();
            timelock.grantRole(grantedRoles_[i].role, grantedRoles_[i].account);
        }

        timelock.renounceRole(adminRole, deployer_);

        return timelockAddress;
    }

    /// @notice Verifies a deployed timelock matches the expected configuration on the current chain.
    /// @dev    Reverts on the first mismatch. Intended to be run per chain after deployment to catch an
    ///         interrupted deploy (e.g. the admin role not renounced) or config/bytecode drift across chains,
    ///         which the shared deterministic address does not guarantee on its own.
    /// @param  timelock_ The address of the deployed TimelockController.
    /// @param  minDelay_ The expected minimum delay.
    /// @param  proposers_ The accounts expected to hold the proposer and canceller roles.
    /// @param  executors_ The accounts expected to hold the executor role.
    /// @param  deployer_ The transient admin used during deployment, which must no longer hold the admin role.
    /// @param  codeHash_ The expected runtime code hash, or bytes32(0) to skip the code hash check.
    function _verifyTimelock(
        address timelock_,
        uint256 minDelay_,
        address[] memory proposers_,
        address[] memory executors_,
        address deployer_,
        bytes32 codeHash_
    ) internal view {
        require(timelock_.code.length > 0, "Timelock not deployed");

        if (codeHash_ != bytes32(0)) {
            require(timelock_.codehash == codeHash_, "Unexpected code hash");
        }

        TimelockController timelock = TimelockController(payable(timelock_));

        require(timelock.getMinDelay() == minDelay_, "Unexpected min delay");

        bytes32 proposerRole = timelock.PROPOSER_ROLE();
        bytes32 cancellerRole = timelock.CANCELLER_ROLE();
        for (uint256 i = 0; i < proposers_.length; i++) {
            require(timelock.hasRole(proposerRole, proposers_[i]), "Missing proposer role");
            require(timelock.hasRole(cancellerRole, proposers_[i]), "Missing canceller role");
        }

        bytes32 executorRole = timelock.EXECUTOR_ROLE();
        for (uint256 i = 0; i < executors_.length; i++) {
            require(timelock.hasRole(executorRole, executors_[i]), "Missing executor role");
        }

        bytes32 adminRole = timelock.DEFAULT_ADMIN_ROLE();
        require(timelock.hasRole(adminRole, timelock_), "Timelock not self-administered");
        require(!timelock.hasRole(adminRole, deployer_), "Deployer still admin");
    }
}
