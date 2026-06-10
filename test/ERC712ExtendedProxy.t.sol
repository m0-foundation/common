// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.20 <0.9.0;

import { Proxy } from "../src/Proxy.sol";

import { BaseERC712ExtendedTests } from "./base/BaseERC712Extended.t.sol";

import { ERC712ExtendedHarness } from "./utils/ERC712ExtendedHarness.sol";
import { IERC712ExtendedHarness } from "./utils/IERC712ExtendedHarness.sol";

/// @dev Runs the full `BaseERC712ExtendedTests` suite against a non-upgradeable `ERC712Extended` deployed behind a
///      `Proxy`, ensuring the EIP-712 domain separator binds to the proxy (not the implementation) and is stable
///      across upgrades.
contract ERC712ExtendedProxyTests is BaseERC712ExtendedTests {
    /// @dev `keccak256('eip1967.proxy.implementation') - 1`.
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    function setUp() public override {
        super.setUp();

        address implementation_ = address(new ERC712ExtendedHarness(_NAME));
        _erc712 = IERC712ExtendedHarness(address(new Proxy(implementation_)));
    }

    /* ============ proxy domain separator ============ */
    function test_proxyDomainDiffersFromStandaloneImplementation() external {
        address standaloneImplementation_ = address(new ERC712ExtendedHarness(_NAME));

        assertEq(_erc712.DOMAIN_SEPARATOR(), _computeDomainSeparator(_NAME, block.chainid, address(_erc712)));
        assertTrue(
            _erc712.DOMAIN_SEPARATOR() != IERC712ExtendedHarness(standaloneImplementation_).DOMAIN_SEPARATOR(),
            "proxy domain must differ from the standalone implementation"
        );
    }

    function test_proxyDomainStableAcrossUpgrade() external {
        bytes32 domainSeparatorBefore_ = _erc712.DOMAIN_SEPARATOR();

        assertEq(domainSeparatorBefore_, _computeDomainSeparator(_NAME, block.chainid, address(_erc712)));

        address newImplementation_ = address(new ERC712ExtendedHarness(_NAME));
        vm.store(address(_erc712), _IMPLEMENTATION_SLOT, bytes32(uint256(uint160(newImplementation_))));

        assertEq(_erc712.DOMAIN_SEPARATOR(), domainSeparatorBefore_, "domain must be stable across an upgrade");
        assertEq(_erc712.DOMAIN_SEPARATOR(), _computeDomainSeparator(_NAME, block.chainid, address(_erc712)));
    }
}
