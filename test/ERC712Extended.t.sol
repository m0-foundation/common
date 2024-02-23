// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.23;

import { TestUtils } from "./utils/TestUtils.t.sol";

import { ERC712ExtendedHarness } from "./utils/ERC712ExtendedHarness.sol";

contract ERC712ExtendedTests is TestUtils {
    ERC712ExtendedHarness internal _ERC712Extended;

    string internal _name = "ERC712Contract";

    function setUp() external {
        _ERC712Extended = new ERC712ExtendedHarness(_name);
    }

    /* ============ eip712Domain ============ */
    function test_eip712Domain() external {
        (
            bytes1 fields_,
            string memory name_,
            string memory version_,
            uint256 chainId_,
            address verifyingContract_,
            bytes32 salt_,
            uint256[] memory extensions_
        ) = _ERC712Extended.eip712Domain();

        assertEq(fields_, hex"0f");
        assertEq(name_, _name);
        assertEq(version_, "1");
        assertEq(chainId_, block.chainid);
        assertEq(verifyingContract_, address(_ERC712Extended));
        assertEq(salt_, bytes32(0));
        assertEq(extensions_, new uint256[](0));
    }
}
