// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.23;

import { UIntMath } from "../../src/libs/UIntMath.sol";

/// @title UIntMath harness used to correctly display test coverage.
contract UIntMathHarness {
    function safe16(uint256 n) external pure returns (uint16) {
        return UIntMath.safe16(n);
    }

    function safe40(uint256 n) external pure returns (uint40) {
        return UIntMath.safe40(n);
    }

    function safe48(uint256 n) external pure returns (uint48) {
        return UIntMath.safe48(n);
    }

    function safe112(uint256 n) external pure returns (uint112) {
        return UIntMath.safe112(n);
    }

    function safe128(uint256 n) external pure returns (uint128) {
        return UIntMath.safe128(n);
    }

    function safe240(uint256 n) external pure returns (uint240) {
        return UIntMath.safe240(n);
    }

    function bound32(uint256 n) external pure returns (uint32) {
        return UIntMath.bound32(n);
    }

    function bound112(uint256 n) external pure returns (uint112) {
        return UIntMath.bound112(n);
    }

    function bound128(uint256 n) external pure returns (uint128) {
        return UIntMath.bound128(n);
    }

    function bound240(uint256 n) external pure returns (uint240) {
        return UIntMath.bound240(n);
    }

    function max40(uint40 a_, uint40 b_) external pure returns (uint40) {
        return UIntMath.max40(a_, b_);
    }

    function min32(uint32 a_, uint32 b_) external pure returns (uint32) {
        return UIntMath.min32(a_, b_);
    }

    function min40(uint40 a_, uint40 b_) external pure returns (uint40) {
        return UIntMath.min40(a_, b_);
    }

    function min112(uint112 a_, uint112 b_) external pure returns (uint112) {
        return UIntMath.min112(a_, b_);
    }

    function min240(uint240 a_, uint240 b_) external pure returns (uint240) {
        return UIntMath.min240(a_, b_);
    }

    function min256(uint256 a_, uint256 b_) external pure returns (uint256) {
        return UIntMath.min256(a_, b_);
    }
}
