// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.20 <0.9.0;

import { IndexingMath } from "../../src/libs/IndexingMath.sol";

// Note: This harness contract is needed cause internal library functions can be inlined by the compiler
//       and won't be picked up by forge coverage
// See: https://github.com/foundry-rs/foundry/issues/6308#issuecomment-1866878768
contract IndexingMathHarness {
    function divide240By128Down(uint240 x, uint128 index) external pure returns (uint112 z) {
        return IndexingMath.divide240By128Down(x, index);
    }

    function divide240By128Up(uint240 x, uint128 index) external pure returns (uint112 z) {
        return IndexingMath.divide240By128Up(x, index);
    }

    function multiply112By128Down(uint112 x, uint128 index) external pure returns (uint240 z) {
        return IndexingMath.multiply112By128Down(x, index);
    }

    function multiply112By128Up(uint112 x, uint128 index) external pure returns (uint240 z) {
        return IndexingMath.multiply112By128Up(x, index);
    }
}
