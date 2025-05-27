// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.20 <0.9.0;

import { IERC20ExtendedHarness } from "./IERC20ExtendedHarness.sol";

interface IERC20ExtendedUpgradeableHarness is IERC20ExtendedHarness {
    function initialize(string memory name_, string memory symbol_, uint8 decimals_) external;
}
