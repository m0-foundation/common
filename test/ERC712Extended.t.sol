// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.20 <0.9.0;

import { BaseERC712ExtendedTests } from "./base/BaseERC712Extended.t.sol";

import { ERC712ExtendedHarness } from "./utils/ERC712ExtendedHarness.sol";
import { IERC712ExtendedHarness } from "./utils/IERC712ExtendedHarness.sol";

contract ERC712ExtendedTests is BaseERC712ExtendedTests {
    function setUp() public override {
        super.setUp();

        _erc712 = IERC712ExtendedHarness(address(new ERC712ExtendedHarness(_NAME)));
    }
}
