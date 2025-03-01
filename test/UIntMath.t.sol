// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.20 <0.9.0;

import { Test } from "../lib/forge-std/src/Test.sol";

import { UIntMath } from "../src/libs/UIntMath.sol";

import { UIntMathHarness } from "./utils/UIntMathHarness.sol";

contract UIntMathTests is Test {
    UIntMathHarness internal _uintMath = new UIntMathHarness();

    function test_safe16() external {
        assertEq(_uintMath.safe16(uint256(type(uint16).max)), type(uint16).max);

        vm.expectRevert(UIntMath.InvalidUInt16.selector);
        _uintMath.safe16(uint256(type(uint16).max) + 1);
    }

    function test_safe40() external {
        assertEq(_uintMath.safe40(uint256(type(uint40).max)), type(uint40).max);

        vm.expectRevert(UIntMath.InvalidUInt40.selector);
        _uintMath.safe40(uint256(type(uint40).max) + 1);
    }

    function test_safe48() external {
        assertEq(_uintMath.safe48(uint256(type(uint48).max)), type(uint48).max);

        vm.expectRevert(UIntMath.InvalidUInt48.selector);
        _uintMath.safe48(uint256(type(uint48).max) + 1);
    }

    function test_safe112() external {
        assertEq(_uintMath.safe112(uint256(type(uint112).max)), type(uint112).max);

        vm.expectRevert(UIntMath.InvalidUInt112.selector);
        _uintMath.safe112(uint256(type(uint112).max) + 1);
    }

    function test_safe128() external {
        assertEq(_uintMath.safe128(uint256(type(uint128).max)), type(uint128).max);

        vm.expectRevert(UIntMath.InvalidUInt128.selector);
        _uintMath.safe128(uint256(type(uint128).max) + 1);
    }

    function test_safe240() external {
        assertEq(_uintMath.safe240(uint256(type(uint240).max)), type(uint240).max);

        vm.expectRevert(UIntMath.InvalidUInt240.selector);
        _uintMath.safe240(uint256(type(uint240).max) + 1);
    }

    function test_bound32() external view {
        assertEq(_uintMath.bound32(uint256(type(uint32).max) + 1), type(uint32).max);
    }

    function test_bound112() external view {
        assertEq(_uintMath.bound112(uint256(type(uint112).max) + 1), type(uint112).max);
    }

    function test_bound128() external view {
        assertEq(_uintMath.bound128(uint256(type(uint128).max) + 1), type(uint128).max);
    }

    function test_bound240() external view {
        assertEq(_uintMath.bound240(uint256(type(uint240).max) + 1), type(uint240).max);
    }

    function test_max32() external view {
        assertEq(_uintMath.max32(1, 2), 2);
        assertEq(_uintMath.max32(2, 1), 2);
    }

    function test_max40() external view {
        assertEq(_uintMath.max40(1, 2), 2);
        assertEq(_uintMath.max40(2, 1), 2);
    }

    function test_max128() external view {
        assertEq(_uintMath.max128(1, 2), 2);
        assertEq(_uintMath.max128(2, 1), 2);
    }

    function test_max240() external view {
        assertEq(_uintMath.max240(1, 2), 2);
        assertEq(_uintMath.max240(2, 1), 2);
    }

    function test_min32() external view {
        assertEq(_uintMath.min32(1, 2), 1);
        assertEq(_uintMath.min32(2, 1), 1);
    }

    function test_min40() external view {
        assertEq(_uintMath.min40(1, 2), 1);
        assertEq(_uintMath.min40(2, 1), 1);
    }

    function test_min112() external view {
        assertEq(_uintMath.min112(1, 2), 1);
        assertEq(_uintMath.min112(2, 1), 1);
    }

    function test_min240() external view {
        assertEq(_uintMath.min240(1, 2), 1);
        assertEq(_uintMath.min240(2, 1), 1);
    }

    function test_min256() external view {
        assertEq(_uintMath.min256(1, 2), 1);
        assertEq(_uintMath.min256(2, 1), 1);
    }
}
