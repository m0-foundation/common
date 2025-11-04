// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.20 <0.9.0;

import { Test } from "../lib/forge-std/src/Test.sol";
import { TimelockController } from "../lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/governance/TimelockController.sol";

import { DeployTimelock } from "../script/deploy/DeployTimelock.sol";

contract DeployTimelockTest is Test {
    DeployTimelock internal _deployer;
    
    address internal _deployerAddress;
    address internal _proposer1;
    address internal _proposer2;
    address internal _executor1;
    address internal _executor2;
    address internal _admin;

    uint256 internal constant _DEFAULT_MIN_DELAY = 3 days;
    uint256 internal constant _CUSTOM_MIN_DELAY = 1 days;

    bytes32 internal constant _PROPOSER_ROLE = keccak256("PROPOSER_ROLE");
    bytes32 internal constant _EXECUTOR_ROLE = keccak256("EXECUTOR_ROLE");
    bytes32 internal constant _CANCELLER_ROLE = keccak256("CANCELLER_ROLE");
    bytes32 internal constant _DEFAULT_ADMIN_ROLE = 0x00;

    function setUp() external {
        _deployer = new DeployTimelock();
        
        _deployerAddress = address(this);
        _proposer1 = makeAddr("proposer1");
        _proposer2 = makeAddr("proposer2");
        _executor1 = makeAddr("executor1");
        _executor2 = makeAddr("executor2");
        _admin = makeAddr("admin");
    }

    function test_run_singleProposerAndExecutor() external {
        address[] memory proposers = new address[](1);
        proposers[0] = _proposer1;
        
        address[] memory executors = new address[](1);
        executors[0] = _executor1;

        address timelockAddress = _deployer.run(_DEFAULT_MIN_DELAY, proposers, executors, _admin);

        // Verify deployment
        assertTrue(timelockAddress != address(0), "Timelock should be deployed");
        assertTrue(timelockAddress.code.length > 0, "Timelock should have code");

        TimelockController timelock = TimelockController(payable(timelockAddress));
        
        // Verify configuration
        assertEq(timelock.getMinDelay(), _DEFAULT_MIN_DELAY, "Min delay should match");
        assertTrue(timelock.hasRole(_PROPOSER_ROLE, _proposer1), "Proposer1 should have proposer role");
        assertTrue(timelock.hasRole(_EXECUTOR_ROLE, _executor1), "Executor1 should have executor role");
        assertTrue(timelock.hasRole(_DEFAULT_ADMIN_ROLE, _admin), "Admin should have admin role");
    }

    function test_run_multipleProposersAndExecutors() external {
        address[] memory proposers = new address[](2);
        proposers[0] = _proposer1;
        proposers[1] = _proposer2;
        
        address[] memory executors = new address[](2);
        executors[0] = _executor1;
        executors[1] = _executor2;

        address timelockAddress = _deployer.run(_CUSTOM_MIN_DELAY, proposers, executors, address(0));

        TimelockController timelock = TimelockController(payable(timelockAddress));
        
        // Verify configuration
        assertEq(timelock.getMinDelay(), _CUSTOM_MIN_DELAY, "Min delay should match");
        assertTrue(timelock.hasRole(_PROPOSER_ROLE, _proposer1), "Proposer1 should have proposer role");
        assertTrue(timelock.hasRole(_PROPOSER_ROLE, _proposer2), "Proposer2 should have proposer role");
        assertTrue(timelock.hasRole(_EXECUTOR_ROLE, _executor1), "Executor1 should have executor role");
        assertTrue(timelock.hasRole(_EXECUTOR_ROLE, _executor2), "Executor2 should have executor role");
        assertFalse(timelock.hasRole(_DEFAULT_ADMIN_ROLE, address(0)), "Zero address should not have admin role");
    }

    function test_run_noAdmin() external {
        address[] memory proposers = new address[](1);
        proposers[0] = _proposer1;
        
        address[] memory executors = new address[](1);
        executors[0] = _executor1;

        address timelockAddress = _deployer.run(_DEFAULT_MIN_DELAY, proposers, executors, address(0));

        TimelockController timelock = TimelockController(payable(timelockAddress));
        
        // Verify no admin role is assigned
        assertFalse(timelock.hasRole(_DEFAULT_ADMIN_ROLE, address(0)), "Zero address should not have admin role");
        assertFalse(timelock.hasRole(_DEFAULT_ADMIN_ROLE, _admin), "Admin should not have admin role");
    }

    function test_run_proposersAlsoHaveCancellerRole() external {
        address[] memory proposers = new address[](1);
        proposers[0] = _proposer1;
        
        address[] memory executors = new address[](1);
        executors[0] = _executor1;

        address timelockAddress = _deployer.run(_DEFAULT_MIN_DELAY, proposers, executors, _admin);

        TimelockController timelock = TimelockController(payable(timelockAddress));
        
        // Proposers should also have canceller role by default in OpenZeppelin TimelockController
        assertTrue(timelock.hasRole(_CANCELLER_ROLE, _proposer1), "Proposer should also have canceller role");
    }

    function test_run_revertsWithEmptyProposers() external {
        address[] memory proposers = new address[](0);
        
        address[] memory executors = new address[](1);
        executors[0] = _executor1;

        vm.expectRevert("DeployTimelock: At least one proposer required");
        _deployer.run(_DEFAULT_MIN_DELAY, proposers, executors, _admin);
    }

    function test_run_revertsWithEmptyExecutors() external {
        address[] memory proposers = new address[](1);
        proposers[0] = _proposer1;
        
        address[] memory executors = new address[](0);

        vm.expectRevert("DeployTimelock: At least one executor required");
        _deployer.run(_DEFAULT_MIN_DELAY, proposers, executors, _admin);
    }

    function test_run_multipleDifferentDeployments() external {
        address[] memory proposers = new address[](1);
        proposers[0] = _proposer1;
        
        address[] memory executors = new address[](1);
        executors[0] = _executor1;

        // First deployment
        address firstAddress = _deployer.run(_DEFAULT_MIN_DELAY, proposers, executors, _admin);
        
        // Second deployment with different parameters should create different address
        address[] memory differentProposers = new address[](1);
        differentProposers[0] = _proposer2;
        
        address secondAddress = _deployer.run(_CUSTOM_MIN_DELAY, differentProposers, executors, address(0));
        
        // Addresses should be different since we're using regular deployment
        assertTrue(firstAddress != secondAddress, "Different deployments should have different addresses");
    }

    function test_run_zeroMinDelay() external {
        address[] memory proposers = new address[](1);
        proposers[0] = _proposer1;
        
        address[] memory executors = new address[](1);
        executors[0] = _executor1;

        address timelockAddress = _deployer.run(0, proposers, executors, _admin);

        TimelockController timelock = TimelockController(payable(timelockAddress));
        
        // Should accept zero min delay
        assertEq(timelock.getMinDelay(), 0, "Min delay should be zero");
    }

    function test_run_largeMinDelay() external {
        address[] memory proposers = new address[](1);
        proposers[0] = _proposer1;
        
        address[] memory executors = new address[](1);
        executors[0] = _executor1;

        uint256 largeDelay = 365 days;
        address timelockAddress = _deployer.run(largeDelay, proposers, executors, _admin);

        TimelockController timelock = TimelockController(payable(timelockAddress));
        
        // Should accept large min delay
        assertEq(timelock.getMinDelay(), largeDelay, "Min delay should match large delay");
    }

    function test_run_sameAddressInMultipleRoles() external {
        address[] memory proposers = new address[](1);
        proposers[0] = _proposer1;
        
        address[] memory executors = new address[](1);
        executors[0] = _proposer1; // Same address as proposer

        address timelockAddress = _deployer.run(_DEFAULT_MIN_DELAY, proposers, executors, _proposer1);

        TimelockController timelock = TimelockController(payable(timelockAddress));
        
        // Verify same address can have multiple roles
        assertTrue(timelock.hasRole(_PROPOSER_ROLE, _proposer1), "Should have proposer role");
        assertTrue(timelock.hasRole(_EXECUTOR_ROLE, _proposer1), "Should have executor role");
        assertTrue(timelock.hasRole(_DEFAULT_ADMIN_ROLE, _proposer1), "Should have admin role");
    }

    function testFuzz_run_validParameters(
        uint256 minDelay,
        uint8 proposerCount,
        uint8 executorCount
    ) external {
        // Bound inputs to reasonable ranges
        minDelay = bound(minDelay, 0, 365 days);
        proposerCount = uint8(bound(proposerCount, 1, 10));
        executorCount = uint8(bound(executorCount, 1, 10));

        // Create proposer and executor arrays
        address[] memory proposers = new address[](proposerCount);
        address[] memory executors = new address[](executorCount);

        for (uint256 i = 0; i < proposerCount; i++) {
            proposers[i] = makeAddr(string(abi.encodePacked("proposer", i)));
        }

        for (uint256 i = 0; i < executorCount; i++) {
            executors[i] = makeAddr(string(abi.encodePacked("executor", i)));
        }

        address timelockAddress = _deployer.run(minDelay, proposers, executors, _admin);

        TimelockController timelock = TimelockController(payable(timelockAddress));
        
        // Verify deployment and basic configuration
        assertTrue(timelockAddress != address(0), "Should deploy timelock");
        assertEq(timelock.getMinDelay(), minDelay, "Should set correct min delay");
        
        // Verify all proposers have role
        for (uint256 i = 0; i < proposerCount; i++) {
            assertTrue(timelock.hasRole(_PROPOSER_ROLE, proposers[i]), "Proposer should have role");
        }
        
        // Verify all executors have role
        for (uint256 i = 0; i < executorCount; i++) {
            assertTrue(timelock.hasRole(_EXECUTOR_ROLE, executors[i]), "Executor should have role");
        }
    }
}
