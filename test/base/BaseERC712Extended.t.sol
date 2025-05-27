// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.20 <0.9.0;

import { IERC712 } from "../../src/interfaces/IERC712.sol";

import { TestUtils } from "../utils/TestUtils.t.sol";

import { ERC1271WalletMock, ERC1271MaliciousWalletMock } from "../utils/ERC1271WalletMock.sol";
import { ERC712ExtendedHarness } from "../utils/ERC712ExtendedHarness.sol";
import { IERC712ExtendedHarness } from "../utils/IERC712ExtendedHarness.sol";

contract BaseERC712ExtendedTests is TestUtils {
    ERC1271MaliciousWalletMock internal _erc1271MaliciousWallet;
    ERC1271WalletMock internal _erc1271Wallet;
    IERC712ExtendedHarness internal _erc712;

    string internal _NAME = "ERC712Contract";

    address internal _owner;
    uint256 internal _ownerKey;

    address internal _spender;
    uint256 internal _spenderKey;

    bytes32 internal _permitDigest;
    uint256 internal _powChainId = 10001;

    uint8 internal _invalidV = 26;
    bytes32 internal _invalidS = bytes32(_MAX_S + 1);

    function setUp() public virtual {
        (_owner, _ownerKey) = makeAddrAndKey("owner");
        (_spender, _spenderKey) = makeAddrAndKey("spender");

        _erc1271MaliciousWallet = new ERC1271MaliciousWalletMock();
        _erc1271Wallet = new ERC1271WalletMock(_owner);
        _permitDigest = _getPermitHash(_owner, _spender, 1e18, 0, 1 days);
    }

    /* ============ constructor ============ */
    function test_constructor() external view {
        assertEq(_erc712.DOMAIN_SEPARATOR(), _computeDomainSeparator(_NAME, block.chainid, address(_erc712)));
    }

    /* ============ DOMAIN_SEPARATOR ============ */
    function test_domainSeparator() external {
        assertEq(_erc712.DOMAIN_SEPARATOR(), _computeDomainSeparator(_NAME, block.chainid, address(_erc712)));

        vm.chainId(_powChainId);

        assertEq(block.chainid, _powChainId);
        assertEq(_erc712.DOMAIN_SEPARATOR(), _computeDomainSeparator(_NAME, _powChainId, address(_erc712)));
    }

    function test_getDomainSeparator() external {
        assertEq(_erc712.getDomainSeparator(), _erc712.DOMAIN_SEPARATOR());
        assertEq(_erc712.getDomainSeparator(), _computeDomainSeparator(_NAME, block.chainid, address(_erc712)));

        vm.chainId(_powChainId);

        assertEq(block.chainid, _powChainId);
        assertEq(_erc712.getDomainSeparator(), _erc712.DOMAIN_SEPARATOR());
        assertEq(_erc712.getDomainSeparator(), _computeDomainSeparator(_NAME, _powChainId, address(_erc712)));
    }

    /* ============ digest ============ */
    function test_digest() external view {
        assertEq(
            _erc712.getDigest(_permitDigest),
            keccak256(abi.encodePacked("\x19\x01", _erc712.DOMAIN_SEPARATOR(), _permitDigest))
        );
    }

    /* ============ getSignerAndRevertIfInvalidSignature ============ */
    function test_getSigner() external view {
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
    function test_revertIfExpired_maxExpiry() external view {
        _erc712.revertIfExpired(type(uint256).max);
    }

    function test_revertIfExpired_expiryUnreached() external view {
        _erc712.revertIfExpired(block.timestamp + 1);
    }

    function test_revertIfExpired_signatureExpired() external {
        uint256 expiry_ = block.timestamp - 1;

        vm.expectRevert(abi.encodeWithSelector(IERC712.SignatureExpired.selector, expiry_, block.timestamp));
        _erc712.revertIfExpired(expiry_);
    }

    /* ============ _revertIfInvalidSignature ============ */
    function test_revertIfInvalidSignature_validSignature() external view {
        (uint8 v_, bytes32 r_, bytes32 s_) = vm.sign(_ownerKey, _permitDigest);

        _erc712.revertIfInvalidSignature(address(_erc1271Wallet), _permitDigest, _encodeSignature(v_, r_, s_));
        _erc712.revertIfInvalidSignature(_owner, _permitDigest, _encodeSignature(v_, r_, s_));
        _erc712.revertIfInvalidSignature(_owner, _permitDigest, r_, _getVS(v_, s_));
        _erc712.revertIfInvalidSignature(_owner, _permitDigest, v_, r_, s_);
    }

    function test_revertIfInvalidSignature_invalidERC1271Signature() external {
        (uint8 v_, bytes32 r_, bytes32 s_) = vm.sign(_ownerKey, _permitDigest);

        vm.expectRevert(IERC712.SignerMismatch.selector);
        _erc712.revertIfInvalidSignature(address(_erc1271Wallet), "DIFF", _encodeSignature(v_, r_, s_));

        vm.expectRevert(IERC712.SignerMismatch.selector);
        _erc712.revertIfInvalidSignature(address(_erc1271MaliciousWallet), _permitDigest, _encodeSignature(v_, r_, s_));

        vm.expectRevert(IERC712.InvalidSignatureV.selector);
        _erc712.revertIfInvalidSignature(address(_erc1271Wallet), _permitDigest, _encodeSignature(_invalidV, r_, s_));

        vm.expectRevert(IERC712.InvalidSignature.selector);
        _erc712.revertIfInvalidSignature(address(_erc1271Wallet), _permitDigest, _encodeSignature(v_, 0, s_));

        vm.expectRevert(IERC712.InvalidSignatureS.selector);
        _erc712.revertIfInvalidSignature(address(_erc1271Wallet), _permitDigest, _encodeSignature(v_, r_, _invalidS));
    }

    function test_revertIfInvalidSignature_invalidECDSASignature() external {
        (uint8 v_, bytes32 r_, bytes32 s_) = vm.sign(_ownerKey, _permitDigest);

        vm.expectRevert(IERC712.SignerMismatch.selector);
        _erc712.revertIfInvalidSignature(address(1), _permitDigest, _encodeSignature(v_, r_, s_));

        vm.expectRevert(IERC712.SignerMismatch.selector);
        _erc712.revertIfInvalidSignature(_owner, "DIFF", _encodeSignature(v_, r_, s_));

        vm.expectRevert(IERC712.InvalidSignatureV.selector);
        _erc712.revertIfInvalidSignature(_owner, _permitDigest, _encodeSignature(_invalidV, r_, s_));

        vm.expectRevert(IERC712.InvalidSignature.selector);
        _erc712.revertIfInvalidSignature(_owner, _permitDigest, _encodeSignature(v_, 0, s_));

        vm.expectRevert(IERC712.InvalidSignatureS.selector);
        _erc712.revertIfInvalidSignature(_owner, _permitDigest, _encodeSignature(v_, r_, _invalidS));
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

    /* ============ eip712Domain ============ */
    function test_eip712Domain() external view {
        (
            bytes1 fields_,
            string memory name_,
            string memory version_,
            uint256 chainId_,
            address verifyingContract_,
            bytes32 salt_,
            uint256[] memory extensions_
        ) = _erc712.eip712Domain();

        assertEq(fields_, hex"0f");
        assertEq(name_, _NAME);
        assertEq(version_, "1");
        assertEq(chainId_, block.chainid);
        assertEq(verifyingContract_, address(_erc712));
        assertEq(salt_, bytes32(0));
        assertEq(extensions_, new uint256[](0));
    }

    function _computeDomainSeparator(
        string memory name_,
        uint256 chainId_,
        address contract_
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name_)),
                    keccak256("1"),
                    chainId_,
                    contract_
                )
            );
    }

    function _getPermitHash(
        address owner_,
        address spender_,
        uint256 value_,
        uint256 nonce_,
        uint256 deadline_
    ) internal pure returns (bytes32) {
        // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
        bytes32 PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

        return keccak256(abi.encode(PERMIT_TYPEHASH, owner_, spender_, value_, nonce_, deadline_));
    }
}
