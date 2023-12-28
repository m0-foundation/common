// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.23;

import { ContractHelper } from "../../src/ContractHelper.sol";

/// @title ContractHelper harness used to correctly display test coverage.
contract ContractHelperHarness {
    function getContractFrom(address account_, uint256 nonce_) external pure returns (address contract_) {
        return ContractHelper.getContractFrom(account_, nonce_);
    }
}
