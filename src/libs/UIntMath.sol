// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.23;

/**
 * @title  Library to perform safe math operations on uint types
 * @author M^0 Labs
 */
library UIntMath {
    /* ============ Custom Errors ============ */

    /// @notice Emitted when a passed value is greater than the maximum value of uint16.
    error InvalidUInt16();

    /// @notice Emitted when a passed value is greater than the maximum value of uint40.
    error InvalidUInt40();

    /// @notice Emitted when a passed value is greater than the maximum value of uint48.
    error InvalidUInt48();

    /// @notice Emitted when a passed value is greater than the maximum value of uint112.
    error InvalidUInt112();

    /// @notice Emitted when a passed value is greater than the maximum value of uint128.
    error InvalidUInt128();

    /// @notice Emitted when a passed value is greater than the maximum value of uint240.
    error InvalidUInt240();

    /* ============ Internal View/Pure Functions ============ */

    /**
     * @notice Casts a given uint256 value to a uint16,
     *         ensuring that it is less than or equal to the maximum uint16 value.
     * @param  n The value to check.
     * @return The value casted to uint16.
     */
    function safe16(uint256 n) internal pure returns (uint16) {
        if (n > type(uint16).max) revert InvalidUInt16();
        return uint16(n);
    }

    /**
     * @notice Casts a given uint256 value to a uint40,
     *         ensuring that it is less than or equal to the maximum uint40 value.
     * @param  n The value to check.
     * @return The value casted to uint40.
     */
    function safe40(uint256 n) internal pure returns (uint40) {
        if (n > type(uint40).max) revert InvalidUInt40();
        return uint40(n);
    }

    /**
     * @notice Casts a given uint256 value to a uint48,
     *         ensuring that it is less than or equal to the maximum uint48 value.
     * @param  n The value to check.
     * @return The value casted to uint48.
     */
    function safe48(uint256 n) internal pure returns (uint48) {
        if (n > type(uint48).max) revert InvalidUInt48();
        return uint48(n);
    }

    /**
     * @notice Casts a given uint256 value to a uint112,
     *         ensuring that it is less than or equal to the maximum uint112 value.
     * @param  n The value to check.
     * @return The value casted to uint112.
     */
    function safe112(uint256 n) internal pure returns (uint112) {
        if (n > type(uint112).max) revert InvalidUInt112();
        return uint112(n);
    }

    /**
     * @notice Casts a given uint256 value to a uint128,
     *         ensuring that it is less than or equal to the maximum uint128 value.
     * @param  n The value to check.
     * @return The value casted to uint128.
     */
    function safe128(uint256 n) internal pure returns (uint128) {
        if (n > type(uint128).max) revert InvalidUInt128();
        return uint128(n);
    }

    /**
     * @notice Casts a given uint256 value to a uint240,
     *         ensuring that it is less than or equal to the maximum uint240 value.
     * @param  n The value to check.
     * @return The value casted to uint240.
     */
    function safe240(uint256 n) internal pure returns (uint240) {
        if (n > type(uint240).max) revert InvalidUInt240();
        return uint240(n);
    }

    /**
     * @notice Limits a given uint256 value to the maximum uint32 value.
     * @param  n The value to check.
     * @return The value limited to within uint32 bounds.
     */
    function bound32(uint256 n) internal pure returns (uint32) {
        return uint32(min256(n, uint256(type(uint32).max)));
    }

    /**
     * @notice Limits a given uint256 value to the maximum uint112 value.
     * @param  n The value to check.
     * @return The value limited to within uint112 bounds.
     */
    function bound112(uint256 n) internal pure returns (uint112) {
        return uint112(min256(n, uint256(type(uint112).max)));
    }

    /**
     * @notice Limits a given uint256 value to the maximum uint128 value.
     * @param  n The value to check.
     * @return The value limited to within uint128 bounds.
     */
    function bound128(uint256 n) internal pure returns (uint128) {
        return uint128(min256(n, uint256(type(uint128).max)));
    }

    /**
     * @notice Limits a given uint256 value to the maximum uint240 value.
     * @param  n The value to check.
     * @return The value limited to within uint240 bounds.
     */
    function bound240(uint256 n) internal pure returns (uint240) {
        return uint240(min256(n, uint256(type(uint240).max)));
    }

    /**
     * @notice Compares two uint32 values and returns the larger one.
     * @param  a_  Value to check.
     * @param  b_  Value to check.
     * @return The larger value.
     */
    function max32(uint32 a_, uint32 b_) internal pure returns (uint32) {
        return a_ > b_ ? a_ : b_;
    }

    /**
     * @notice Compares two uint40 values and returns the larger one.
     * @param  a_  Value to check.
     * @param  b_  Value to check.
     * @return The larger value.
     */
    function max40(uint40 a_, uint40 b_) internal pure returns (uint40) {
        return a_ > b_ ? a_ : b_;
    }

    /**
     * @notice Compares two uint240 values and returns the larger one.
     * @param  a_  Value to check.
     * @param  b_  Value to check.
     * @return The larger value.
     */
    function max240(uint240 a_, uint240 b_) internal pure returns (uint240) {
        return a_ > b_ ? a_ : b_;
    }

    /**
     * @notice Compares two uint32 values and returns the lesser one.
     * @param  a_  Value to check.
     * @param  b_  Value to check.
     * @return The lesser value.
     */
    function min32(uint32 a_, uint32 b_) internal pure returns (uint32) {
        return a_ < b_ ? a_ : b_;
    }

    /**
     * @notice Compares two uint40 values and returns the lesser one.
     * @param  a_  Value to check.
     * @param  b_  Value to check.
     * @return The lesser value.
     */
    function min40(uint40 a_, uint40 b_) internal pure returns (uint40) {
        return a_ < b_ ? a_ : b_;
    }

    /**
     * @notice Compares two uint240 values and returns the lesser one.
     * @param  a_  Value to check.
     * @param  b_  Value to check.
     * @return The lesser value.
     */
    function min240(uint240 a_, uint240 b_) internal pure returns (uint240) {
        return a_ < b_ ? a_ : b_;
    }

    /**
     * @notice Compares two uint112 values and returns the lesser one.
     * @param  a_  Value to check.
     * @param  b_  Value to check.
     * @return The lesser value.
     */
    function min112(uint112 a_, uint112 b_) internal pure returns (uint112) {
        return a_ < b_ ? a_ : b_;
    }

    /**
     * @notice Compares two uint256 values and returns the lesser one.
     * @param  a_  Value to check.
     * @param  b_  Value to check.
     * @return The lesser value.
     */
    function min256(uint256 a_, uint256 b_) internal pure returns (uint256) {
        return a_ < b_ ? a_ : b_;
    }
}
