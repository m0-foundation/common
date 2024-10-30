// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.20 <0.9.0;

import { TestUtils } from "./utils/TestUtils.t.sol";

import { SignatureChecker } from "../src/libs/SignatureChecker.sol";
import { SignatureCheckerHarness } from "./utils/SignatureCheckerHarness.sol";

contract AccountWithFallback {
    fallback() external {}
}

contract AccountWithoutFallback {}

contract AccountWithEmptyFunction {
    function isValidSignature(bytes32, bytes memory) external pure returns (bytes4) {}
}

contract AccountWithRevertingFunction {
    function isValidSignature(bytes32, bytes memory) external pure returns (bytes4) {
        revert();
    }
}

contract AccountWithFunctionReturningTrue {
    function isValidSignature(bytes32, bytes memory) external pure returns (bool) {
        return true;
    }
}

contract AccountWithFunctionReturningNothing {
    function isValidSignature(bytes32, bytes memory) external pure {}
}

contract AccountWithFunctionReturningInvalidData {
    function isValidSignature(bytes32, bytes memory) external pure returns (bytes4) {
        return bytes4(0xFFFFFFFF);
    }
}

contract AccountWithValidFunction {
    function isValidSignature(bytes32, bytes memory) external pure returns (bytes4) {
        return 0x1626ba7e;
    }
}

contract SignatureCheckerTests is TestUtils {
    SignatureCheckerHarness internal _signatureChecker;

    function setUp() external {
        _signatureChecker = new SignatureCheckerHarness();
    }

    function test_decodeECDSASignature() external {
        (uint8 v_, bytes32 r_, bytes32 s_) = _signatureChecker.decodeECDSASignature(
            _encodeSignature(18, "TEST_R", "TEST_S")
        );

        assertEq(v_, uint8(18));
        assertEq(r_, bytes32("TEST_R"));
        assertEq(s_, bytes32("TEST_S"));
    }

    function testFuzz_decodeECDSASignature(uint256 v, uint256 r, uint256 s) external {
        (uint8 v_, bytes32 r_, bytes32 s_) = _signatureChecker.decodeECDSASignature(
            _encodeSignature(uint8(v), bytes32(r), bytes32(s))
        );

        assertEq(v_, uint8(v));
        assertEq(r_, bytes32(r));
        assertEq(s_, bytes32(s));
    }

    function test_recoverECDSASigner_vrs_invalidSignatureS() external {
        (SignatureChecker.Error error_, address signer) = _signatureChecker.recoverECDSASigner(
            0x00,
            0x00,
            0x00,
            bytes32(_MAX_S + 1)
        );

        assertEq(uint8(error_), uint8(SignatureChecker.Error.InvalidSignatureS));
        assertEq(signer, address(0));
    }

    function test_recoverECDSASigner_vrs_invalidSignatureV() external {
        (SignatureChecker.Error error_, address signer) = _signatureChecker.recoverECDSASigner(0x00, 26, 0x00, 0x00);

        assertEq(uint8(error_), uint8(SignatureChecker.Error.InvalidSignatureV));
        assertEq(signer, address(0));
    }

    function test_recoverECDSASigner_vrs_invalidSignature() external {
        (SignatureChecker.Error error_, address signer) = _signatureChecker.recoverECDSASigner(0x00, 27, 0x00, 0x00);

        assertEq(uint8(error_), uint8(SignatureChecker.Error.InvalidSignature));
        assertEq(signer, address(0));
    }

    function test_recoverECDSASigner_vrs() external {
        bytes32 digest_ = "TEST_DIGEST";
        (address account_, uint256 privateKey_) = makeAddrAndKey("account");
        (uint8 v_, bytes32 r_, bytes32 s_) = vm.sign(privateKey_, digest_);

        (SignatureChecker.Error error_, address signer_) = _signatureChecker.recoverECDSASigner(digest_, v_, r_, s_);

        assertEq(uint8(error_), uint8(SignatureChecker.Error.NoError));
        assertEq(signer_, account_);
    }

    function testFuzz_recoverECDSASigner_vrs(uint256 digest) external {
        bytes32 digest_ = bytes32(digest);
        (address account_, uint256 privateKey_) = makeAddrAndKey(string(abi.encode("account", digest)));
        (uint8 v_, bytes32 r_, bytes32 s_) = vm.sign(privateKey_, digest_);

        (SignatureChecker.Error error_, address signer_) = _signatureChecker.recoverECDSASigner(digest_, v_, r_, s_);

        assertEq(uint8(error_), uint8(SignatureChecker.Error.NoError));
        assertEq(signer_, account_);
    }

    function test_recoverECDSASigner_rvs_invalidSignatureS() external {
        (SignatureChecker.Error error_, address signer) = _signatureChecker.recoverECDSASigner(
            0x00,
            0x00,
            bytes32(_MAX_S + 1)
        );

        assertEq(uint8(error_), uint8(SignatureChecker.Error.InvalidSignatureS));
        assertEq(signer, address(0));
    }

    function test_recoverECDSASigner_rvs_invalidSignature() external {
        (SignatureChecker.Error error_, address signer) = _signatureChecker.recoverECDSASigner(0x00, 0x00, 0x00);

        assertEq(uint8(error_), uint8(SignatureChecker.Error.InvalidSignature));
        assertEq(signer, address(0));
    }

    function test_recoverECDSASigner_rvs() external {
        bytes32 digest_ = "TEST_DIGEST";
        (address account_, uint256 privateKey_) = makeAddrAndKey("account");
        (uint8 v_, bytes32 r_, bytes32 s_) = vm.sign(privateKey_, digest_);

        (SignatureChecker.Error error_, address signer_) = _signatureChecker.recoverECDSASigner(
            digest_,
            r_,
            _getVS(v_, s_)
        );

        assertEq(uint8(error_), uint8(SignatureChecker.Error.NoError));
        assertEq(signer_, account_);
    }

    function testFuzz_recoverECDSASigner_rvs(uint256 digest) external {
        bytes32 digest_ = bytes32(digest);
        (address account_, uint256 privateKey_) = makeAddrAndKey(string(abi.encode("account", digest)));
        (uint8 v_, bytes32 r_, bytes32 s_) = vm.sign(privateKey_, digest_);

        (SignatureChecker.Error error_, address signer_) = _signatureChecker.recoverECDSASigner(
            digest_,
            r_,
            _getVS(v_, s_)
        );

        assertEq(uint8(error_), uint8(SignatureChecker.Error.NoError));
        assertEq(signer_, account_);
    }

    function test_recoverECDSASigner_bytes_invalidSignatureS() external {
        (SignatureChecker.Error error_, address signer) = _signatureChecker.recoverECDSASigner(
            0x00,
            _encodeSignature(0x00, 0x00, bytes32(_MAX_S + 1))
        );

        assertEq(uint8(error_), uint8(SignatureChecker.Error.InvalidSignatureS));
        assertEq(signer, address(0));
    }

    function test_recoverECDSASigner_bytes_invalidSignatureV() external {
        (SignatureChecker.Error error_, address signer) = _signatureChecker.recoverECDSASigner(
            0x00,
            _encodeSignature(26, 0x00, 0x00)
        );

        assertEq(uint8(error_), uint8(SignatureChecker.Error.InvalidSignatureV));
        assertEq(signer, address(0));
    }

    function test_recoverECDSASigner_bytes_invalidSignature() external {
        (SignatureChecker.Error error_, address signer) = _signatureChecker.recoverECDSASigner(
            0x00,
            _encodeSignature(27, 0x00, 0x00)
        );

        assertEq(uint8(error_), uint8(SignatureChecker.Error.InvalidSignature));
        assertEq(signer, address(0));
    }

    function test_recoverECDSASigner_bytes() external {
        bytes32 digest_ = "TEST_DIGEST";
        (address account_, uint256 privateKey_) = makeAddrAndKey("account");
        (uint8 v_, bytes32 r_, bytes32 s_) = vm.sign(privateKey_, digest_);

        (SignatureChecker.Error error_, address signer_) = _signatureChecker.recoverECDSASigner(
            digest_,
            _encodeSignature(v_, r_, s_)
        );

        assertEq(uint8(error_), uint8(SignatureChecker.Error.NoError));
        assertEq(signer_, account_);
    }

    function testFuzz_recoverECDSASigner_fullSignature(uint256 digest) external {
        bytes32 digest_ = bytes32(digest);
        (address account_, uint256 privateKey_) = makeAddrAndKey(string(abi.encode("account", digest)));
        (uint8 v_, bytes32 r_, bytes32 s_) = vm.sign(privateKey_, digest_);

        (SignatureChecker.Error error_, address signer_) = _signatureChecker.recoverECDSASigner(
            digest_,
            _encodeSignature(v_, r_, s_)
        );

        assertEq(uint8(error_), uint8(SignatureChecker.Error.NoError));
        assertEq(signer_, account_);
    }

    function test_validateRecoveredSigner_mismatch() external {
        assertEq(
            uint8(_signatureChecker.validateRecoveredSigner(address(0), address(1))),
            uint8(SignatureChecker.Error.SignerMismatch)
        );
    }

    function test_validateRecoveredSigner() external {
        assertEq(
            uint8(_signatureChecker.validateRecoveredSigner(address(1), address(1))),
            uint8(SignatureChecker.Error.NoError)
        );
    }

    function test_validateECDSASignature_vrs_invalid() external {
        bytes32 digest_ = "TEST_DIGEST";
        (address account_, uint256 privateKey_) = makeAddrAndKey("account");
        (uint8 v_, bytes32 r_, bytes32 s_) = vm.sign(privateKey_, digest_);

        assertNotEq(
            uint8(_signatureChecker.validateECDSASignature(address(1), digest_, v_, r_, s_)),
            uint8(SignatureChecker.Error.NoError)
        );

        assertNotEq(
            uint8(_signatureChecker.validateECDSASignature(account_, "DIFF", v_, r_, s_)),
            uint8(SignatureChecker.Error.NoError)
        );

        assertNotEq(
            uint8(_signatureChecker.validateECDSASignature(account_, digest_, 26, r_, s_)),
            uint8(SignatureChecker.Error.NoError)
        );

        assertNotEq(
            uint8(_signatureChecker.validateECDSASignature(account_, digest_, v_, 0, s_)),
            uint8(SignatureChecker.Error.NoError)
        );

        assertNotEq(
            uint8(_signatureChecker.validateECDSASignature(account_, digest_, v_, r_, bytes32(_MAX_S + 1))),
            uint8(SignatureChecker.Error.NoError)
        );
    }

    function test_validateECDSASignature_rvs() external {
        bytes32 digest_ = "TEST_DIGEST";
        (address account_, uint256 privateKey_) = makeAddrAndKey("account");
        (uint8 v_, bytes32 r_, bytes32 s_) = vm.sign(privateKey_, digest_);

        assertEq(
            uint8(_signatureChecker.validateECDSASignature(account_, digest_, r_, _getVS(v_, s_))),
            uint8(SignatureChecker.Error.NoError)
        );
    }

    function testFuzz_validateECDSASignature_rvs(uint256 digest) external {
        bytes32 digest_ = bytes32(digest);
        (address account_, uint256 privateKey_) = makeAddrAndKey(string(abi.encode("account", digest)));
        (uint8 v_, bytes32 r_, bytes32 s_) = vm.sign(privateKey_, digest_);

        assertEq(
            uint8(_signatureChecker.validateECDSASignature(account_, digest_, r_, _getVS(v_, s_))),
            uint8(SignatureChecker.Error.NoError)
        );
    }

    function test_validateECDSASignature_rvs_invalid() external {
        bytes32 digest_ = "TEST_DIGEST";
        (address account_, uint256 privateKey_) = makeAddrAndKey("account");
        (uint8 v_, bytes32 r_, bytes32 s_) = vm.sign(privateKey_, digest_);

        bytes32 vs_ = _getVS(v_, s_);

        assertNotEq(
            uint8(_signatureChecker.validateECDSASignature(address(1), digest_, v_, r_, vs_)),
            uint8(SignatureChecker.Error.NoError)
        );

        assertNotEq(
            uint8(_signatureChecker.validateECDSASignature(account_, "DIFF", r_, vs_)),
            uint8(SignatureChecker.Error.NoError)
        );

        assertNotEq(
            uint8(_signatureChecker.validateECDSASignature(account_, digest_, r_, _getVS(26, s_))),
            uint8(SignatureChecker.Error.NoError)
        );

        assertNotEq(
            uint8(_signatureChecker.validateECDSASignature(account_, digest_, 0, vs_)),
            uint8(SignatureChecker.Error.NoError)
        );

        assertNotEq(
            uint8(_signatureChecker.validateECDSASignature(account_, digest_, r_, _getVS(v_, bytes32(_MAX_S + 1)))),
            uint8(SignatureChecker.Error.NoError)
        );
    }

    function test_validateECDSASignature_vrs() external {
        bytes32 digest_ = "TEST_DIGEST";
        (address account_, uint256 privateKey_) = makeAddrAndKey("account");
        (uint8 v_, bytes32 r_, bytes32 s_) = vm.sign(privateKey_, digest_);

        assertEq(
            uint8(_signatureChecker.validateECDSASignature(account_, digest_, r_, _getVS(v_, s_))),
            uint8(SignatureChecker.Error.NoError)
        );
    }

    function testFuzz_validateECDSASignature_vrs(uint256 digest) external {
        bytes32 digest_ = bytes32(digest);
        (address account_, uint256 privateKey_) = makeAddrAndKey(string(abi.encode("account", digest)));
        (uint8 v_, bytes32 r_, bytes32 s_) = vm.sign(privateKey_, digest_);

        assertEq(
            uint8(_signatureChecker.validateECDSASignature(account_, digest_, r_, _getVS(v_, s_))),
            uint8(SignatureChecker.Error.NoError)
        );
    }

    function test_validateECDSASignature_bytes_invalid() external {
        bytes32 invalidS_ = bytes32(_MAX_S + 1);
        bytes32 digest_ = "TEST_DIGEST";
        (address account_, uint256 privateKey_) = makeAddrAndKey("account");
        (uint8 v_, bytes32 r_, bytes32 s_) = vm.sign(privateKey_, digest_);

        assertNotEq(
            uint8(_signatureChecker.validateECDSASignature(address(1), digest_, _encodeSignature(v_, r_, s_))),
            uint8(SignatureChecker.Error.NoError)
        );

        assertNotEq(
            uint8(_signatureChecker.validateECDSASignature(account_, "DIFF", _encodeSignature(v_, r_, s_))),
            uint8(SignatureChecker.Error.NoError)
        );

        assertNotEq(
            uint8(_signatureChecker.validateECDSASignature(account_, digest_, _encodeSignature(26, r_, s_))),
            uint8(SignatureChecker.Error.NoError)
        );

        assertNotEq(
            uint8(_signatureChecker.validateECDSASignature(account_, digest_, _encodeSignature(v_, 0, s_))),
            uint8(SignatureChecker.Error.NoError)
        );

        assertNotEq(
            uint8(_signatureChecker.validateECDSASignature(account_, digest_, _encodeSignature(v_, r_, invalidS_))),
            uint8(SignatureChecker.Error.NoError)
        );
    }

    function test_validateECDSASignature_bytes() external {
        bytes32 digest_ = "TEST_DIGEST";
        (address account_, uint256 privateKey_) = makeAddrAndKey("account");
        (uint8 v_, bytes32 r_, bytes32 s_) = vm.sign(privateKey_, digest_);

        assertEq(
            uint8(_signatureChecker.validateECDSASignature(account_, digest_, _encodeSignature(v_, r_, s_))),
            uint8(SignatureChecker.Error.NoError)
        );
    }

    function testFuzz_validateECDSASignature_fullSignature(uint256 digest) external {
        bytes32 digest_ = bytes32(digest);
        (address account_, uint256 privateKey_) = makeAddrAndKey(string(abi.encode("account", digest)));
        (uint8 v_, bytes32 r_, bytes32 s_) = vm.sign(privateKey_, digest_);

        assertEq(
            uint8(_signatureChecker.validateECDSASignature(account_, digest_, _encodeSignature(v_, r_, s_))),
            uint8(SignatureChecker.Error.NoError)
        );
    }

    function test_isValidECDSASignature_rvs_invalid() external {
        bytes32 digest_ = "TEST_DIGEST";
        (address account_, uint256 privateKey_) = makeAddrAndKey("account");
        (uint8 v_, bytes32 r_, bytes32 s_) = vm.sign(privateKey_, digest_);

        bytes32 vs_ = _getVS(v_, s_);

        assertFalse(_signatureChecker.isValidECDSASignature(address(1), digest_, r_, vs_));
        assertFalse(_signatureChecker.isValidECDSASignature(account_, "DIFF", r_, vs_));
        assertFalse(_signatureChecker.isValidECDSASignature(account_, digest_, r_, _getVS(26, s_)));
        assertFalse(_signatureChecker.isValidECDSASignature(account_, digest_, 0, vs_));
        assertFalse(_signatureChecker.isValidECDSASignature(account_, digest_, r_, _getVS(v_, bytes32(_MAX_S + 1))));
    }

    function test_isValidECDSASignature_rvs() external {
        bytes32 digest_ = "TEST_DIGEST";
        (address account_, uint256 privateKey_) = makeAddrAndKey("account");

        (uint8 v_, bytes32 r_, bytes32 s_) = vm.sign(privateKey_, digest_);

        assertTrue(_signatureChecker.isValidECDSASignature(account_, digest_, r_, _getVS(v_, s_)));
    }

    function testFuzz_isValidECDSASignature_rvs(uint256 digest) external {
        bytes32 digest_ = bytes32(digest);
        (address account_, uint256 privateKey_) = makeAddrAndKey(string(abi.encode("account", digest)));

        (uint8 v_, bytes32 r_, bytes32 s_) = vm.sign(privateKey_, digest_);

        assertTrue(_signatureChecker.isValidECDSASignature(account_, digest_, r_, _getVS(v_, s_)));
    }

    function test_isValidECDSASignature_bytes_invalid() external {
        bytes32 invalidS_ = bytes32(_MAX_S + 1);
        bytes32 digest_ = "TEST_DIGEST";
        (address account_, uint256 privateKey_) = makeAddrAndKey("account");
        (uint8 v_, bytes32 r_, bytes32 s_) = vm.sign(privateKey_, digest_);

        assertFalse(_signatureChecker.isValidECDSASignature(address(1), digest_, _encodeSignature(v_, r_, s_)));
        assertFalse(_signatureChecker.isValidECDSASignature(account_, "DIFF", _encodeSignature(v_, r_, s_)));
        assertFalse(_signatureChecker.isValidECDSASignature(account_, digest_, _encodeSignature(26, r_, s_)));
        assertFalse(_signatureChecker.isValidECDSASignature(account_, digest_, _encodeSignature(v_, 0, s_)));
        assertFalse(_signatureChecker.isValidECDSASignature(account_, digest_, _encodeSignature(v_, r_, invalidS_)));
    }

    function test_isValidECDSASignature_bytes() external {
        bytes32 digest_ = "TEST_DIGEST";
        (address account_, uint256 privateKey_) = makeAddrAndKey("account");

        (uint8 v_, bytes32 r_, bytes32 s_) = vm.sign(privateKey_, digest_);

        assertTrue(_signatureChecker.isValidECDSASignature(account_, digest_, _encodeSignature(v_, r_, s_)));
    }

    function testFuzz_isValidECDSASignature_fullSignature(uint256 digest) external {
        bytes32 digest_ = bytes32(digest);
        (address account_, uint256 privateKey_) = makeAddrAndKey(string(abi.encode("account", digest)));

        (uint8 v_, bytes32 r_, bytes32 s_) = vm.sign(privateKey_, digest_);

        assertTrue(_signatureChecker.isValidECDSASignature(account_, digest_, _encodeSignature(v_, r_, s_)));
    }

    function test_isValidERC1271Signature_emptyAccount() external {
        assertFalse(_signatureChecker.isValidERC1271Signature(makeAddr("account"), "DIGEST", ""));
    }

    function test_isValidERC1271Signature_accountWithFallback() external {
        assertFalse(_signatureChecker.isValidERC1271Signature(address(new AccountWithFallback()), "DIGEST", ""));
    }

    function test_isValidERC1271Signature_accountWithoutFallback() external {
        assertFalse(_signatureChecker.isValidERC1271Signature(address(new AccountWithoutFallback()), "DIGEST", ""));
    }

    function test_isValidERC1271Signature_accountFailsSilently() external {
        assertFalse(_signatureChecker.isValidERC1271Signature(address(new AccountWithEmptyFunction()), "DIGEST", ""));
    }

    function test_isValidERC1271Signature_accountReverts() external {
        assertFalse(
            _signatureChecker.isValidERC1271Signature(address(new AccountWithRevertingFunction()), "DIGEST", "")
        );
    }

    function test_isValidERC1271Signature_accountReturnsTrue() external {
        assertFalse(
            _signatureChecker.isValidERC1271Signature(address(new AccountWithFunctionReturningTrue()), "DIGEST", "")
        );
    }

    function test_isValidERC1271Signature_accountReturnsNothing() external {
        assertFalse(
            _signatureChecker.isValidERC1271Signature(address(new AccountWithFunctionReturningNothing()), "DIGEST", "")
        );
    }

    function test_isValidERC1271Signature_accountReturnsInvalidData() external {
        assertFalse(
            _signatureChecker.isValidERC1271Signature(
                address(new AccountWithFunctionReturningInvalidData()),
                "DIGEST",
                ""
            )
        );
    }

    function test_isValidERC1271Signature() external {
        assertTrue(_signatureChecker.isValidERC1271Signature(address(new AccountWithValidFunction()), "DIGEST", ""));
    }

    function test_isValidSignature_invalid() external {
        bytes32 invalidS_ = bytes32(_MAX_S + 1);
        bytes32 digest_ = "TEST_DIGEST";
        (address account_, uint256 privateKey_) = makeAddrAndKey("account");
        (uint8 v_, bytes32 r_, bytes32 s_) = vm.sign(privateKey_, digest_);
        bytes32 vs_ = _getVS(v_, s_);

        assertFalse(_signatureChecker.isValidSignature(address(1), digest_, _encodeSignature(v_, r_, s_)));
        assertFalse(_signatureChecker.isValidSignature(account_, "DIFF", _encodeSignature(v_, r_, s_)));
        assertFalse(_signatureChecker.isValidSignature(account_, digest_, _encodeSignature(26, r_, s_)));
        assertFalse(_signatureChecker.isValidSignature(account_, digest_, _encodeSignature(v_, 0, s_)));
        assertFalse(_signatureChecker.isValidSignature(account_, digest_, _encodeSignature(v_, r_, invalidS_)));

        assertFalse(_signatureChecker.isValidSignature(address(1), digest_, _encodeShortSignature(r_, vs_)));
        assertFalse(_signatureChecker.isValidSignature(account_, "DIFF", _encodeShortSignature(r_, vs_)));
        assertFalse(_signatureChecker.isValidSignature(account_, digest_, _encodeShortSignature(0, vs_)));
        assertFalse(_signatureChecker.isValidSignature(account_, digest_, _encodeShortSignature(r_, invalidS_)));

        assertFalse(_signatureChecker.isValidSignature(makeAddr("account"), "DIGEST", ""));
        assertFalse(_signatureChecker.isValidSignature(address(new AccountWithFallback()), "DIGEST", ""));
        assertFalse(_signatureChecker.isValidSignature(address(new AccountWithoutFallback()), "DIGEST", ""));
        assertFalse(_signatureChecker.isValidSignature(address(new AccountWithEmptyFunction()), "DIGEST", ""));
        assertFalse(_signatureChecker.isValidSignature(address(new AccountWithRevertingFunction()), "DIGEST", ""));
        assertFalse(_signatureChecker.isValidSignature(address(new AccountWithFunctionReturningTrue()), "DIGEST", ""));
        assertFalse(
            _signatureChecker.isValidSignature(address(new AccountWithFunctionReturningNothing()), "DIGEST", "")
        );
        assertFalse(
            _signatureChecker.isValidSignature(address(new AccountWithFunctionReturningInvalidData()), "DIGEST", "")
        );
    }

    function test_isValidSignature_ecdsa() external {
        bytes32 digest_ = "TEST_DIGEST";
        (address account_, uint256 privateKey_) = makeAddrAndKey("account");

        (uint8 v_, bytes32 r_, bytes32 s_) = vm.sign(privateKey_, digest_);

        assertTrue(_signatureChecker.isValidSignature(account_, digest_, _encodeSignature(v_, r_, s_)));
        assertTrue(_signatureChecker.isValidSignature(account_, digest_, _encodeShortSignature(r_, _getVS(v_, s_))));
    }

    function testFuzz_isValidSignature_ecdsa(uint256 digest) external {
        bytes32 digest_ = bytes32(digest);
        (address account_, uint256 privateKey_) = makeAddrAndKey(string(abi.encode("account", digest)));

        (uint8 v_, bytes32 r_, bytes32 s_) = vm.sign(privateKey_, digest_);

        assertTrue(_signatureChecker.isValidSignature(account_, digest_, _encodeSignature(v_, r_, s_)));
        assertTrue(_signatureChecker.isValidSignature(account_, digest_, _encodeShortSignature(r_, _getVS(v_, s_))));
    }

    function test_isValidSignature_erc1271() external {
        assertTrue(_signatureChecker.isValidSignature(address(new AccountWithValidFunction()), "DIGEST", ""));
    }
}
