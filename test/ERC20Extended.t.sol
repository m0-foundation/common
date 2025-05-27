// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.20 <0.9.0;

import { ERC20ExtendedHarness } from "./utils/ERC20ExtendedHarness.sol";
import { IERC20ExtendedHarness } from "./utils/IERC20ExtendedHarness.sol";

import { BaseERC20ExtendedTests } from "./base/BaseERC20Extended.t.sol";

contract ERC20ExtendedTests is BaseERC20ExtendedTests {
    function setUp() public override {
        super.setUp();

        _token = IERC20ExtendedHarness(address(new ERC20ExtendedHarness(_TOKEN_NAME, _TOKEN_SYMBOL, _TOKEN_DECIMALS)));
    }
}
