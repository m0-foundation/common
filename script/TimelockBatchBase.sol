// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.20 <0.9.0;

import {
    TimelockController
} from "../lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/governance/TimelockController.sol";
import { Script } from "../lib/forge-std/src/Script.sol";

abstract contract TimelockBatchBase is Script {
    address[] internal _timelockTargets;
    uint256[] internal _timelockValues;
    bytes[] internal _timelockPayloads;

    function _addToTimelockBatch(address target_, bytes memory payload_) internal {
        _timelockTargets.push(target_);
        _timelockValues.push(0);
        _timelockPayloads.push(payload_);
    }

    function _addToTimelockBatch(address target_, uint256 value_, bytes memory payload_) internal {
        _timelockTargets.push(target_);
        _timelockValues.push(value_);
        _timelockPayloads.push(payload_);
    }

    function _getScheduleBatchCallData(
        bytes32 predecessor,
        bytes32 salt,
        uint256 delay
    ) internal view returns (bytes memory) {
        return abi.encodeCall(
            TimelockController.scheduleBatch,
            (_timelockTargets, _timelockValues, _timelockPayloads, predecessor, salt, delay)
        );
    }

    function _simulateBatch(address timelock_) internal {
        vm.startPrank(timelock_);

        for (uint256 i = 0; i < _timelockTargets.length; i++) {
            (bool success, ) = _timelockTargets[i].call{ value: _timelockValues[i] }(_timelockPayloads[i]);
            require(success, "Simulation failed");
        }

        vm.stopPrank();
    }
}
