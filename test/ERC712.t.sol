// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.23;

import { TestUtils } from "./utils/TestUtils.t.sol";

import { SignatureChecker } from "../src/libs/SignatureChecker.sol";
import { SignatureCheckerHarness } from "./utils/SignatureCheckerHarness.sol";
import { ERC712Harness } from "./utils/ERC712Harness.sol";

import { IERC712 } from "../src/interfaces/IERC712.sol";
import { ERC712 } from "../src/ERC712.sol";

contract ERC712Tests is TestUtils {
    ERC712Harness internal _erc712;

    string internal _name = "ERC712Contract";

    address internal _owner;
    uint256 internal _ownerKey;

    address internal _spender;
    uint256 internal _spenderKey;

    bytes32 internal _permitDigest;
    uint256 internal _powChainId = 10001;

    uint8 internal _invalidV = 26;
    bytes32 internal _invalidS = bytes32(_MAX_S + 1);

    function setUp() external {
        (_owner, _ownerKey) = makeAddrAndKey("owner");
        (_spender, _spenderKey) = makeAddrAndKey("spender");

        _erc712 = new ERC712Harness(_name);
        _permitDigest = _erc712.getPermitHash(
            ERC712Harness.Permit({ owner: _owner, spender: _spender, value: 1e18, nonce: 0, deadline: 1 days })
        );
    }

    /* ============ constructor ============ */
    function test_constructor() external {
        assertEq(_erc712.name(), _name);
        assertEq(_erc712.DOMAIN_SEPARATOR(), _erc712.computeDomainSeparator(_name, block.chainid));
    }

    /* ============ DOMAIN_SEPARATOR ============ */
    function test_domainSeparator() external {
        assertEq(_erc712.DOMAIN_SEPARATOR(), _erc712.computeDomainSeparator(_name, block.chainid));

        vm.chainId(_powChainId);

        assertEq(block.chainid, _powChainId);
        assertEq(_erc712.DOMAIN_SEPARATOR(), _erc712.computeDomainSeparator(_name, _powChainId));
    }

    function test_getDomainSeparator() external {
        assertEq(_erc712.getDomainSeparator(), _erc712.DOMAIN_SEPARATOR());
        assertEq(_erc712.getDomainSeparator(), _erc712.computeDomainSeparator(_name, block.chainid));

        vm.chainId(_powChainId);

        assertEq(block.chainid, _powChainId);
        assertEq(_erc712.getDomainSeparator(), _erc712.DOMAIN_SEPARATOR());
        assertEq(_erc712.getDomainSeparator(), _erc712.computeDomainSeparator(_name, _powChainId));
    }

    /* ============ digest ============ */
    function test_digest() external {
        assertEq(
            _erc712.getDigest(_permitDigest),
            keccak256(abi.encodePacked("\x19\x01", _erc712.DOMAIN_SEPARATOR(), _permitDigest))
        );
    }

    /* ============ getSignerAndRevertIfInvalidSignature ============ */
    function test_getSigner() external {
        (uint8 v_, bytes32 r_, bytes32 s_) = vm.sign(_ownerKey, _permitDigest);

        assertEq(_erc712.getSignerAndRevertIfInvalidSignature(_permitDigest, v_, r_, s_), address(_owner));
    }

    function test_getSigner_invalidSignature() external {
        vm.expectRevert(IERC712.InvalidSignature.selector);
        _erc712.getSignerAndRevertIfInvalidSignature(0x00, 27, 0x00, 0x00);
    }

    function test_getSigner_invalidSignatureS() external {
        vm.expectRevert(IERC712.InvalidSignatureS.selector);
        _erc712.getSignerAndRevertIfInvalidSignature(0x00, 0x00, 0x00, _invalidS);
    }

    function test_getSigner_invalidSignatureV() external {
        vm.expectRevert(IERC712.InvalidSignatureV.selector);
        _erc712.getSignerAndRevertIfInvalidSignature(0x00, _invalidV, 0x00, 0x00);
    }

    /* ============ revertIfExpired ============ */
    function test_revertIfExpired_maxExpiry() external {
        assertTrue(_erc712.revertIfExpired(type(uint256).max));
    }

    function test_revertIfExpired_expiryUnreached() external {
        assertTrue(_erc712.revertIfExpired(block.timestamp + 1));
    }

    function test_revertIfExpired_signatureExpired() external {
        uint256 expiry_ = block.timestamp - 1;

        vm.expectRevert(abi.encodeWithSelector(IERC712.SignatureExpired.selector, expiry_, block.timestamp));
        _erc712.revertIfExpired(expiry_);
    }

    /* ============ _revertIfInvalidSignature ============ */
    function test_revertIfInvalidSignature_validSignature() external {
        (uint8 v_, bytes32 r_, bytes32 s_) = vm.sign(_ownerKey, _permitDigest);

        assertTrue(_erc712.revertIfInvalidSignature(_owner, _permitDigest, _encodeSignature(v_, r_, s_)));
        assertTrue(_erc712.revertIfInvalidSignature(_owner, _permitDigest, r_, _getVS(v_, s_)));
        assertTrue(_erc712.revertIfInvalidSignature(_owner, _permitDigest, v_, r_, s_));
    }

    function test_revertIfInvalidSignature_invalidSignature() external {
        (uint8 v_, bytes32 r_, bytes32 s_) = vm.sign(_ownerKey, _permitDigest);

        vm.expectRevert(IERC712.InvalidSignature.selector);
        _erc712.revertIfInvalidSignature(address(1), _permitDigest, _encodeSignature(v_, r_, s_));

        vm.expectRevert(IERC712.InvalidSignature.selector);
        _erc712.revertIfInvalidSignature(address(1), _permitDigest, _encodeShortSignature(r_, _getVS(v_, s_)));
    }

    function test_revertIfInvalidSignature_invalidRVS() external {
        (uint8 v_, bytes32 r_, bytes32 s_) = vm.sign(_ownerKey, _permitDigest);
        bytes32 vs_ = _getVS(v_, s_);

        vm.expectRevert(IERC712.SignerMismatch.selector);
        _erc712.revertIfInvalidSignature(address(1), _permitDigest, r_, vs_);

        vm.expectRevert(IERC712.SignerMismatch.selector);
        _erc712.revertIfInvalidSignature(_owner, "DIFF", r_, vs_);

        vm.expectRevert(IERC712.InvalidSignature.selector);
        _erc712.revertIfInvalidSignature(_owner, _permitDigest, 0, vs_);

        vm.expectRevert(IERC712.SignerMismatch.selector);
        _erc712.revertIfInvalidSignature(_owner, _permitDigest, r_, _getVS(28, s_));

        vm.expectRevert(IERC712.InvalidSignatureS.selector);
        _erc712.revertIfInvalidSignature(_owner, _permitDigest, r_, _getVS(v_, _invalidS));
    }

    function test_revertIfInvalidSignature_invalidVRS() external {
        (uint8 v_, bytes32 r_, bytes32 s_) = vm.sign(_ownerKey, _permitDigest);

        vm.expectRevert(IERC712.SignerMismatch.selector);
        _erc712.revertIfInvalidSignature(address(1), _permitDigest, v_, r_, s_);

        vm.expectRevert(IERC712.SignerMismatch.selector);
        _erc712.revertIfInvalidSignature(_owner, "DIFF", v_, r_, s_);

        vm.expectRevert(IERC712.InvalidSignatureV.selector);
        _erc712.revertIfInvalidSignature(_owner, _permitDigest, _invalidV, r_, s_);

        vm.expectRevert(IERC712.InvalidSignature.selector);
        _erc712.revertIfInvalidSignature(_owner, _permitDigest, v_, 0, s_);

        vm.expectRevert(IERC712.InvalidSignatureS.selector);
        _erc712.revertIfInvalidSignature(_owner, _permitDigest, v_, r_, _invalidS);
    }
}
