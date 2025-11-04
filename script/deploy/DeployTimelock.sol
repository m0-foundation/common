
// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.20 <0.9.0;

import { Script } from "../../lib/forge-std/src/Script.sol";
import { console2 } from "../../lib/forge-std/src/console2.sol";
import { TimelockController } from "../../lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/governance/TimelockController.sol";

import { DeployHelpers } from "./DeployHelpers.sol";

contract DeployTimelock is Script, DeployHelpers { 

    /// @dev Deploy with native Forge arguments
    function run(
        uint256 minDelay,
        address[] memory proposers,
        address[] memory executors,
        address admin
    ) public returns (address timelockAddress) {
        // Validate parameters
        require(proposers.length > 0, "DeployTimelock: At least one proposer required");
        require(executors.length > 0, "DeployTimelock: At least one executor required");

        console2.log("=== Deploying TimelockController ===");
        console2.log("Min delay:", minDelay);
        console2.log("Number of proposers:", proposers.length);
        console2.log("Number of executors:", executors.length);
        console2.log("Admin:", admin);

        vm.startBroadcast();

        // Deploy TimelockController
        timelockAddress = _deployTimelockController(minDelay, proposers, executors, admin);

        vm.stopBroadcast();

        console2.log("=== Deployment Complete ===");
        console2.log("TimelockController deployed at:", timelockAddress);

        return timelockAddress;
    }

    function _deployTimelockController(
        uint256 minDelay,
        address[] memory proposers,
        address[] memory executors,
        address admin
    ) internal returns (address) {
        // Deploy TimelockController directly using new for simplicity
        TimelockController timelock = new TimelockController(minDelay, proposers, executors, admin);
        
        address timelockAddress = address(timelock);
        
        // Verify deployment
        require(timelockAddress != address(0), "DeployTimelock: Deployment failed");
        require(timelockAddress.code.length > 0, "DeployTimelock: No code at deployed address");

        return timelockAddress;
    }
}
