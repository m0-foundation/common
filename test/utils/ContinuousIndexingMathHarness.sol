// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.20 <0.9.0;

import { ContinuousIndexingMath } from "../../src/libs/ContinuousIndexingMath.sol";

// Note: This harness contract is needed cause internal library functions can be inlined by the compiler
//       and won't be picked up by forge coverage
// See: https://github.com/foundry-rs/foundry/issues/6308#issuecomment-1866878768
contract ContinuousIndexingMathHarness {
    function multiplyIndicesDown(uint128 index, uint48 deltaIndex) external pure returns (uint144) {
        return ContinuousIndexingMath.multiplyIndicesDown(index, deltaIndex);
    }

    function multiplyIndicesUp(uint128 index, uint48 deltaIndex) external pure returns (uint144) {
        return ContinuousIndexingMath.multiplyIndicesUp(index, deltaIndex);
    }

    function getContinuousIndex(uint64 yearlyRate, uint32 time) external pure returns (uint48) {
        return ContinuousIndexingMath.getContinuousIndex(yearlyRate, time);
    }

    function exponent(uint72 x) external pure returns (uint48 y) {
        return ContinuousIndexingMath.exponent(x);
    }

    function convertToBasisPoints(uint64 input) external pure returns (uint40) {
        return ContinuousIndexingMath.convertToBasisPoints(input);
    }

    function convertFromBasisPoints(uint32 input) external pure returns (uint64) {
        return ContinuousIndexingMath.convertFromBasisPoints(input);
    }
}
