// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.20 <0.9.0;

import { IERC712ExtendedHarness } from "./IERC712ExtendedHarness.sol";

interface IERC712ExtendedUpgradeableHarness is IERC712ExtendedHarness {
    function initialize(string memory name_) external;
}
