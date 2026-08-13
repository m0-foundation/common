// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.20 <0.9.0;

import { Test } from "forge-std/Test.sol";

import { TimelockController } from "@openzeppelin/contracts/governance/TimelockController.sol";

import { DeployTimelockHelpers } from "../script/deploy/DeployTimelockHelpers.sol";

import { CREATEX_RUNTIME_CODE } from "./utils/CreateXRuntimeCode.sol";
import { DeployTimelockHelpersHarness } from "./utils/DeployTimelockHelpersHarness.sol";

contract DeployTimelockHelpersTests is Test {
    uint256 internal constant _MIN_DELAY = 1 days;

    DeployTimelockHelpersHarness internal _harness;

    address internal _proposerSafe = makeAddr("proposerSafe");
    address internal _cancellerSafe = makeAddr("cancellerSafe");

    address[] internal _proposers;
    address[] internal _executors;

    bytes32 internal _salt;

    function setUp() external {
        _harness = new DeployTimelockHelpersHarness();

        vm.etch(_harness.CREATE_X_FACTORY(), CREATEX_RUNTIME_CODE);

        _proposers.push(_proposerSafe);
        _executors.push(address(0)); // open executor

        // CreateX permissioned deploy protection requires the salt to embed the caller of the factory.
        _salt = _harness.computeSalt(address(_harness), "M0Timelock");
    }

    function test_deployCreate3Timelock() external {
        address expected = _harness.getCreate3Address(address(_harness), _salt);

        address deployed = _harness.deployTimelock(_salt, _MIN_DELAY, _proposers, _executors, address(0));

        assertEq(deployed, expected);
        assertGt(deployed.code.length, 0);

        TimelockController timelock = TimelockController(payable(deployed));

        assertEq(timelock.getMinDelay(), _MIN_DELAY);
        assertTrue(timelock.hasRole(timelock.PROPOSER_ROLE(), _proposerSafe));
        assertTrue(timelock.hasRole(timelock.CANCELLER_ROLE(), _proposerSafe));
        assertTrue(timelock.hasRole(timelock.EXECUTOR_ROLE(), address(0)));

        // Self-administered, no external admin.
        assertTrue(timelock.hasRole(timelock.DEFAULT_ADMIN_ROLE(), deployed));
        assertFalse(timelock.hasRole(timelock.DEFAULT_ADMIN_ROLE(), address(_harness)));
    }

    function test_deployCreate3TimelockWithRolesGranted() external {
        address expected = _harness.getCreate3Address(address(_harness), _salt);

        DeployTimelockHelpers.GrantedRole[] memory grantedRoles = new DeployTimelockHelpers.GrantedRole[](1);
        grantedRoles[0] = DeployTimelockHelpers.GrantedRole({
            role: keccak256("CANCELLER_ROLE"),
            account: _cancellerSafe
        });

        address deployed = _harness.deployTimelockWithRolesGranted(
            _salt,
            _MIN_DELAY,
            _proposers,
            _executors,
            grantedRoles
        );

        assertEq(deployed, expected);

        TimelockController timelock = TimelockController(payable(deployed));

        // Additional role was granted.
        assertTrue(timelock.hasRole(timelock.CANCELLER_ROLE(), _cancellerSafe));
        assertFalse(timelock.hasRole(timelock.PROPOSER_ROLE(), _cancellerSafe));

        // Constructor-assigned roles are unaffected.
        assertTrue(timelock.hasRole(timelock.PROPOSER_ROLE(), _proposerSafe));
        assertTrue(timelock.hasRole(timelock.CANCELLER_ROLE(), _proposerSafe));
        assertTrue(timelock.hasRole(timelock.EXECUTOR_ROLE(), address(0)));

        // Transient admin was renounced; only the timelock administers itself.
        assertFalse(timelock.hasRole(timelock.DEFAULT_ADMIN_ROLE(), address(_harness)));
        assertTrue(timelock.hasRole(timelock.DEFAULT_ADMIN_ROLE(), deployed));
    }

    function test_deployCreate3TimelockWithRolesGranted_revertsOnAdminRole() external {
        DeployTimelockHelpers.GrantedRole[] memory grantedRoles = new DeployTimelockHelpers.GrantedRole[](1);
        // Admin role is bytes32(0), which is also the default value of an unset role field.
        grantedRoles[0] = DeployTimelockHelpers.GrantedRole({ role: bytes32(0), account: _cancellerSafe });

        vm.expectRevert(DeployTimelockHelpers.AdminRoleGrantNotAllowed.selector);
        _harness.deployTimelockWithRolesGranted(_salt, _MIN_DELAY, _proposers, _executors, grantedRoles);
    }

    function test_verifyTimelock() external {
        address deployed = _harness.deployTimelock(_salt, _MIN_DELAY, _proposers, _executors, address(0));

        _harness.verifyTimelock(deployed, _MIN_DELAY, _proposers, _executors, address(_harness), deployed.codehash);
    }

    function test_verifyTimelock_revertsIfDeployerStillAdmin() external {
        // Deploy with the harness kept as admin (interrupted-run scenario: renounce never happened).
        address deployed = _harness.deployTimelock(_salt, _MIN_DELAY, _proposers, _executors, address(_harness));

        vm.expectRevert("Deployer still admin");
        _harness.verifyTimelock(deployed, _MIN_DELAY, _proposers, _executors, address(_harness), bytes32(0));
    }
}
