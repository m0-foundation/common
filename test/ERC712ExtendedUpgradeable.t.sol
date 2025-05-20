// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.20 <0.9.0;

import { Proxy } from "../src/Proxy.sol";

import { BaseERC712ExtendedTests } from "./base/BaseERC712Extended.t.sol";

import { ERC712ExtendedUpgradeableHarness } from "./utils/ERC712ExtendedUpgradeableHarness.sol";
import { IERC712ExtendedUpgradeableHarness } from "./utils/IERC712ExtendedUpgradeableHarness.sol";
import { IERC712ExtendedHarness } from "./utils/IERC712ExtendedHarness.sol";

contract ERC712ExtendedUpgradeableTests is BaseERC712ExtendedTests {
    function setUp() public override {
        super.setUp();

        address implementation_ = address(new ERC712ExtendedUpgradeableHarness());
        address proxy_ = address(new Proxy(implementation_));

        IERC712ExtendedUpgradeableHarness(proxy_).initialize(_NAME);
        _erc712 = IERC712ExtendedHarness(proxy_);
    }
}
