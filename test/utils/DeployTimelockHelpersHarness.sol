// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

import { DeployTimelockHelpers } from "../../script/deploy/DeployTimelockHelpers.sol";

contract DeployTimelockHelpersHarness is DeployTimelockHelpers {
    function deployTimelock(
        bytes32 salt_,
        uint256 minDelay_,
        address[] memory proposers_,
        address[] memory executors_,
        address admin_
    ) external returns (address) {
        return _deployCreate3Timelock(salt_, minDelay_, proposers_, executors_, admin_);
    }

    function deployTimelockWithRolesGranted(
        bytes32 salt_,
        uint256 minDelay_,
        address[] memory proposers_,
        address[] memory executors_,
        GrantedRole[] memory grantedRoles_
    ) external returns (address) {
        return
            _deployCreate3TimelockWithRolesGranted(
                salt_,
                minDelay_,
                proposers_,
                executors_,
                address(this),
                grantedRoles_
            );
    }

    function verifyTimelock(
        address timelock_,
        uint256 minDelay_,
        address[] memory proposers_,
        address[] memory executors_,
        address deployer_,
        bytes32 codeHash_
    ) external view {
        _verifyTimelock(timelock_, minDelay_, proposers_, executors_, deployer_, codeHash_);
    }

    function getCreate3Address(address deployer_, bytes32 salt_) external view returns (address) {
        return _getCreate3Address(deployer_, salt_);
    }

    function computeSalt(address deployer_, string memory contractName_) external pure returns (bytes32) {
        return _computeSalt(deployer_, contractName_);
    }
}
