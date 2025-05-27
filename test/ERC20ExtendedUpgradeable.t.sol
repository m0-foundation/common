// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.20 <0.9.0;

import { Proxy } from "../src/Proxy.sol";

import { ERC20ExtendedUpgradeableHarness } from "./utils/ERC20ExtendedUpgradeableHarness.sol";
import { IERC20ExtendedUpgradeableHarness } from "./utils/IERC20ExtendedUpgradeableHarness.sol";
import { IERC20ExtendedHarness } from "./utils/IERC20ExtendedHarness.sol";

import { BaseERC20ExtendedTests } from "./base/BaseERC20Extended.t.sol";

contract ERC20ExtendedUpgradeableTests is BaseERC20ExtendedTests {
    function setUp() public override {
        super.setUp();

        address implementation_ = address(new ERC20ExtendedUpgradeableHarness());
        address proxy_ = address(new Proxy(implementation_));

        IERC20ExtendedUpgradeableHarness(proxy_).initialize(_TOKEN_NAME, _TOKEN_SYMBOL, _TOKEN_DECIMALS);
        _token = IERC20ExtendedHarness(proxy_);
    }
}
