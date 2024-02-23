// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.23;

import { ERC712Extended } from "../../src/ERC712Extended.sol";

contract ERC712ExtendedHarness is ERC712Extended {
    constructor(string memory name_) ERC712Extended(name_) {}
}
