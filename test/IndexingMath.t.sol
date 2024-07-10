// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.20 <0.9.0;

import { Test } from "../lib/forge-std/src/Test.sol";

import { IndexingMath } from "../src/libs/IndexingMath.sol";

import { IndexingMathHarness } from "./utils/IndexingMathHarness.sol";

contract ContinuousIndexingMathTests is Test {
    uint56 internal constant _EXP_SCALED_ONE = IndexingMath.EXP_SCALED_ONE;

    IndexingMathHarness public indexingMath;

    function setUp() external {
        indexingMath = new IndexingMathHarness();
    }

    function test_divide240By128Down() external view {
        // Set 1a
        assertEq(indexingMath.divide240By128Down(0, 1), 0);
        assertEq(indexingMath.divide240By128Down(1, 1), _EXP_SCALED_ONE);
        assertEq(indexingMath.divide240By128Down(2, 1), 2 * _EXP_SCALED_ONE);
        assertEq(indexingMath.divide240By128Down(3, 1), 3 * _EXP_SCALED_ONE);

        // Set 1b
        assertEq(indexingMath.divide240By128Down(1, 1), _EXP_SCALED_ONE);
        assertEq(indexingMath.divide240By128Down(1, 2), _EXP_SCALED_ONE / 2);
        assertEq(indexingMath.divide240By128Down(1, 3), _EXP_SCALED_ONE / 3); // Different than divideUp

        // Set 2a
        assertEq(indexingMath.divide240By128Down(0, 10), 0);
        assertEq(indexingMath.divide240By128Down(5, 10), _EXP_SCALED_ONE / 2);
        assertEq(indexingMath.divide240By128Down(10, 10), _EXP_SCALED_ONE);
        assertEq(indexingMath.divide240By128Down(15, 10), _EXP_SCALED_ONE + _EXP_SCALED_ONE / 2);
        assertEq(indexingMath.divide240By128Down(20, 10), 2 * _EXP_SCALED_ONE);
        assertEq(indexingMath.divide240By128Down(25, 10), 2 * _EXP_SCALED_ONE + _EXP_SCALED_ONE / 2);

        // Set 2b
        assertEq(indexingMath.divide240By128Down(10, 5), 2 * _EXP_SCALED_ONE);
        assertEq(indexingMath.divide240By128Down(10, 10), _EXP_SCALED_ONE);
        assertEq(indexingMath.divide240By128Down(10, 15), (2 * _EXP_SCALED_ONE) / 3); // Different than divideUp
        assertEq(indexingMath.divide240By128Down(10, 20), _EXP_SCALED_ONE / 2);
        assertEq(indexingMath.divide240By128Down(10, 25), (2 * _EXP_SCALED_ONE) / 5);

        // Set 3
        assertEq(indexingMath.divide240By128Down(1, _EXP_SCALED_ONE + 1), 0); // Different than divideUp
        assertEq(indexingMath.divide240By128Down(1, _EXP_SCALED_ONE), 1);
        assertEq(indexingMath.divide240By128Down(1, _EXP_SCALED_ONE - 1), 1); // Different than divideUp
        assertEq(indexingMath.divide240By128Down(1, (_EXP_SCALED_ONE / 2) + 1), 1); // Different than divideUp
        assertEq(indexingMath.divide240By128Down(1, (_EXP_SCALED_ONE / 2)), 2);
        assertEq(indexingMath.divide240By128Down(1, (_EXP_SCALED_ONE / 2) - 1), 2); // Different than divideUp
    }

    function test_divide240By128Up() external view {
        // Set 1a
        assertEq(indexingMath.divide240By128Up(0, 1), 0);
        assertEq(indexingMath.divide240By128Up(1, 1), _EXP_SCALED_ONE);
        assertEq(indexingMath.divide240By128Up(2, 1), 2 * _EXP_SCALED_ONE);
        assertEq(indexingMath.divide240By128Up(3, 1), 3 * _EXP_SCALED_ONE);

        // Set 1b
        assertEq(indexingMath.divide240By128Up(1, 1), _EXP_SCALED_ONE);
        assertEq(indexingMath.divide240By128Up(1, 2), _EXP_SCALED_ONE / 2);
        assertEq(indexingMath.divide240By128Up(1, 3), _EXP_SCALED_ONE / 3 + 1); // Different than divideDown

        // Set 2a
        assertEq(indexingMath.divide240By128Up(0, 10), 0);
        assertEq(indexingMath.divide240By128Up(5, 10), _EXP_SCALED_ONE / 2);
        assertEq(indexingMath.divide240By128Up(10, 10), _EXP_SCALED_ONE);
        assertEq(indexingMath.divide240By128Up(15, 10), _EXP_SCALED_ONE + _EXP_SCALED_ONE / 2);
        assertEq(indexingMath.divide240By128Up(20, 10), 2 * _EXP_SCALED_ONE);
        assertEq(indexingMath.divide240By128Up(25, 10), 2 * _EXP_SCALED_ONE + _EXP_SCALED_ONE / 2);

        // Set 2b
        assertEq(indexingMath.divide240By128Up(10, 5), 2 * _EXP_SCALED_ONE);
        assertEq(indexingMath.divide240By128Up(10, 10), _EXP_SCALED_ONE);
        assertEq(indexingMath.divide240By128Up(10, 15), (2 * _EXP_SCALED_ONE) / 3 + 1); // Different than divideDown
        assertEq(indexingMath.divide240By128Up(10, 20), _EXP_SCALED_ONE / 2);
        assertEq(indexingMath.divide240By128Up(10, 25), (2 * _EXP_SCALED_ONE) / 5);

        // Set 3
        assertEq(indexingMath.divide240By128Up(1, _EXP_SCALED_ONE + 1), 1); // Different than divideDown
        assertEq(indexingMath.divide240By128Up(1, _EXP_SCALED_ONE), 1);
        assertEq(indexingMath.divide240By128Up(1, _EXP_SCALED_ONE - 1), 2); // Different than divideDown
        assertEq(indexingMath.divide240By128Up(1, (_EXP_SCALED_ONE / 2) + 1), 2); // Different than divideDown
        assertEq(indexingMath.divide240By128Up(1, (_EXP_SCALED_ONE / 2)), 2);
        assertEq(indexingMath.divide240By128Up(1, (_EXP_SCALED_ONE / 2) - 1), 3); // Different than divideDown
    }

    function test_multiply112By128Down() external view {
        // Set 1a
        assertEq(indexingMath.multiply112By128Down(0, 1), 0);
        assertEq(indexingMath.multiply112By128Down(_EXP_SCALED_ONE, 1), 1);
        assertEq(indexingMath.multiply112By128Down(2 * _EXP_SCALED_ONE, 1), 2);
        assertEq(indexingMath.multiply112By128Down(3 * _EXP_SCALED_ONE, 1), 3);

        // Set 1b
        assertEq(indexingMath.multiply112By128Down(_EXP_SCALED_ONE, 1), 1);
        assertEq(indexingMath.multiply112By128Down(_EXP_SCALED_ONE / 2, 2), 1);
        assertEq(indexingMath.multiply112By128Down(_EXP_SCALED_ONE / 3, 3), 0);
        assertEq(indexingMath.multiply112By128Down(_EXP_SCALED_ONE / 3 + 1, 3), 1);

        // Set 2a
        assertEq(indexingMath.multiply112By128Down(0, 10), 0);
        assertEq(indexingMath.multiply112By128Down(_EXP_SCALED_ONE / 2, 10), 5);
        assertEq(indexingMath.multiply112By128Down(_EXP_SCALED_ONE, 10), 10);
        assertEq(indexingMath.multiply112By128Down(_EXP_SCALED_ONE + _EXP_SCALED_ONE / 2, 10), 15);
        assertEq(indexingMath.multiply112By128Down(2 * _EXP_SCALED_ONE, 10), 20);
        assertEq(indexingMath.multiply112By128Down(2 * _EXP_SCALED_ONE + _EXP_SCALED_ONE / 2, 10), 25);

        // Set 2b
        assertEq(indexingMath.multiply112By128Down(2 * _EXP_SCALED_ONE, 5), 10);
        assertEq(indexingMath.multiply112By128Down(_EXP_SCALED_ONE, 10), 10);
        assertEq(indexingMath.multiply112By128Down((2 * _EXP_SCALED_ONE) / 3, 15), 9);
        assertEq(indexingMath.multiply112By128Down((2 * _EXP_SCALED_ONE) / 3 + 1, 15), 10);
        assertEq(indexingMath.multiply112By128Down(_EXP_SCALED_ONE / 2, 20), 10);
        assertEq(indexingMath.multiply112By128Down((2 * _EXP_SCALED_ONE) / 5, 25), 10);

        // Set 3
        assertEq(indexingMath.multiply112By128Down(1, _EXP_SCALED_ONE + 1), 1);
        assertEq(indexingMath.multiply112By128Down(1, _EXP_SCALED_ONE), 1);
        assertEq(indexingMath.multiply112By128Down(1, _EXP_SCALED_ONE - 1), 0);
        assertEq(indexingMath.multiply112By128Down(1, (_EXP_SCALED_ONE / 2) + 1), 0);
        assertEq(indexingMath.multiply112By128Down(2, (_EXP_SCALED_ONE / 2)), 1);
        assertEq(indexingMath.multiply112By128Down(2, (_EXP_SCALED_ONE / 2) - 1), 0);
    }

    function test_multiply112By128Up() external view {
        // Set 1a
        assertEq(indexingMath.multiply112By128Up(0, 1), 0);
        assertEq(indexingMath.multiply112By128Up(_EXP_SCALED_ONE, 1), 1);
        assertEq(indexingMath.multiply112By128Up(2 * _EXP_SCALED_ONE, 1), 2);
        assertEq(indexingMath.multiply112By128Up(3 * _EXP_SCALED_ONE, 1), 3);

        // Set 1b
        assertEq(indexingMath.multiply112By128Up(_EXP_SCALED_ONE, 1), 1);
        assertEq(indexingMath.multiply112By128Up(_EXP_SCALED_ONE / 2, 2), 1);
        assertEq(indexingMath.multiply112By128Up(_EXP_SCALED_ONE / 3, 3), 1); // Different than multiplyDown
        assertEq(indexingMath.multiply112By128Up(_EXP_SCALED_ONE / 3 + 1, 3), 2); // Different than multiplyDown

        // Set 2a
        assertEq(indexingMath.multiply112By128Up(0, 10), 0);
        assertEq(indexingMath.multiply112By128Up(_EXP_SCALED_ONE / 2, 10), 5);
        assertEq(indexingMath.multiply112By128Up(_EXP_SCALED_ONE, 10), 10);
        assertEq(indexingMath.multiply112By128Up(_EXP_SCALED_ONE + _EXP_SCALED_ONE / 2, 10), 15);
        assertEq(indexingMath.multiply112By128Up(2 * _EXP_SCALED_ONE, 10), 20);
        assertEq(indexingMath.multiply112By128Up(2 * _EXP_SCALED_ONE + _EXP_SCALED_ONE / 2, 10), 25);

        // Set 2b
        assertEq(indexingMath.multiply112By128Up(2 * _EXP_SCALED_ONE, 5), 10);
        assertEq(indexingMath.multiply112By128Up(_EXP_SCALED_ONE, 10), 10);
        assertEq(indexingMath.multiply112By128Up((2 * _EXP_SCALED_ONE) / 3, 15), 10); // Different than multiplyDown
        assertEq(indexingMath.multiply112By128Up((2 * _EXP_SCALED_ONE) / 3 + 1, 15), 11); // Different than multiplyDown
        assertEq(indexingMath.multiply112By128Up(_EXP_SCALED_ONE / 2, 20), 10);
        assertEq(indexingMath.multiply112By128Up((2 * _EXP_SCALED_ONE) / 5, 25), 10);

        // Set 3
        assertEq(indexingMath.multiply112By128Up(1, _EXP_SCALED_ONE + 1), 2); // Different than multiplyDown
        assertEq(indexingMath.multiply112By128Up(1, _EXP_SCALED_ONE), 1);
        assertEq(indexingMath.multiply112By128Up(1, _EXP_SCALED_ONE - 1), 1); // Different than multiplyDown
        assertEq(indexingMath.multiply112By128Up(1, (_EXP_SCALED_ONE / 2) + 1), 1); // Different than multiplyDown
        assertEq(indexingMath.multiply112By128Up(2, (_EXP_SCALED_ONE / 2)), 1);
        assertEq(indexingMath.multiply112By128Up(2, (_EXP_SCALED_ONE / 2) - 1), 1); // Different than multiplyDown
    }
}
