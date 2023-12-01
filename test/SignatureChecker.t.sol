// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import { Test } from "../lib/forge-std/src/Test.sol";

import { SignatureChecker } from "../src/SignatureChecker.sol";

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

contract SignatureCheckerTests is Test {
    uint256 internal constant _MAX_S = uint256(0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0);

    function test_decodeECDSASignature() external {
        (uint8 v_, bytes32 r_, bytes32 s_) = SignatureChecker.decodeECDSASignature(
            _encodeSignature(18, "TEST_R", "TEST_S")
        );

        assertEq(v_, uint8(18));
        assertEq(r_, bytes32("TEST_R"));
        assertEq(s_, bytes32("TEST_S"));
    }

    function test_recoverECDSASigner_vrs_invalidSignatureS() external {
        (SignatureChecker.Error error_, address signer) = SignatureChecker.recoverECDSASigner(
            0x00,
            0x00,
            0x00,
            bytes32(_MAX_S + 1)
        );

        assertEq(uint8(error_), uint8(SignatureChecker.Error.InvalidSignatureS));
        assertEq(signer, address(0));
    }

    function test_recoverECDSASigner_vrs_invalidSignatureV() external {
        (SignatureChecker.Error error_, address signer) = SignatureChecker.recoverECDSASigner(0x00, 26, 0x00, 0x00);

        assertEq(uint8(error_), uint8(SignatureChecker.Error.InvalidSignatureV));
        assertEq(signer, address(0));
    }

    function test_recoverECDSASigner_vrs_invalidSignature() external {
        (SignatureChecker.Error error_, address signer) = SignatureChecker.recoverECDSASigner(0x00, 27, 0x00, 0x00);

        assertEq(uint8(error_), uint8(SignatureChecker.Error.InvalidSignature));
        assertEq(signer, address(0));
    }

    function test_recoverECDSASigner_vrs() external {
        bytes32 digest_ = "TEST_DIGEST";
        (address account_, uint256 privateKey_) = makeAddrAndKey("account");
        (uint8 v_, bytes32 r_, bytes32 s_) = vm.sign(privateKey_, digest_);

        (SignatureChecker.Error error_, address signer_) = SignatureChecker.recoverECDSASigner(digest_, v_, r_, s_);

        assertEq(uint8(error_), uint8(SignatureChecker.Error.NoError));
        assertEq(signer_, account_);
    }

    function test_recoverECDSASigner_bytes_invalidSignatureS() external {
        (SignatureChecker.Error error_, address signer) = SignatureChecker.recoverECDSASigner(
            0x00,
            _encodeSignature(0x00, 0x00, bytes32(_MAX_S + 1))
        );

        assertEq(uint8(error_), uint8(SignatureChecker.Error.InvalidSignatureS));
        assertEq(signer, address(0));
    }

    function test_recoverECDSASigner_bytes_invalidSignatureV() external {
        (SignatureChecker.Error error_, address signer) = SignatureChecker.recoverECDSASigner(
            0x00,
            _encodeSignature(26, 0x00, 0x00)
        );

        assertEq(uint8(error_), uint8(SignatureChecker.Error.InvalidSignatureV));
        assertEq(signer, address(0));
    }

    function test_recoverECDSASigner_bytes_invalidSignature() external {
        (SignatureChecker.Error error_, address signer) = SignatureChecker.recoverECDSASigner(
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

        (SignatureChecker.Error error_, address signer_) = SignatureChecker.recoverECDSASigner(
            digest_,
            _encodeSignature(v_, r_, s_)
        );

        assertEq(uint8(error_), uint8(SignatureChecker.Error.NoError));
        assertEq(signer_, account_);
    }

    function test_validateRecoveredSigner_mismatch() external {
        assertEq(
            uint8(SignatureChecker.validateRecoveredSigner(address(0), address(1))),
            uint8(SignatureChecker.Error.SignerMismatch)
        );
    }

    function test_validateRecoveredSigner() external {
        assertEq(
            uint8(SignatureChecker.validateRecoveredSigner(address(1), address(1))),
            uint8(SignatureChecker.Error.NoError)
        );
    }

    function test_validateECDSASignature_vrs_invalid() external {
        bytes32 invalidS_ = bytes32(_MAX_S + 1);
        bytes32 digest_ = "TEST_DIGEST";
        (address account_, uint256 privateKey_) = makeAddrAndKey("account");
        (uint8 v_, bytes32 r_, bytes32 s_) = vm.sign(privateKey_, digest_);

        assertNotEq(
            uint8(SignatureChecker.validateECDSASignature(address(1), digest_, v_, r_, s_)),
            uint8(SignatureChecker.Error.NoError)
        );

        assertNotEq(
            uint8(SignatureChecker.validateECDSASignature(account_, "DIFF", v_, r_, s_)),
            uint8(SignatureChecker.Error.NoError)
        );

        assertNotEq(
            uint8(SignatureChecker.validateECDSASignature(account_, "digest_", 26, r_, s_)),
            uint8(SignatureChecker.Error.NoError)
        );

        assertNotEq(
            uint8(SignatureChecker.validateECDSASignature(account_, "digest_", v_, 0, s_)),
            uint8(SignatureChecker.Error.NoError)
        );

        assertNotEq(
            uint8(SignatureChecker.validateECDSASignature(account_, "digest_", v_, r_, invalidS_)),
            uint8(SignatureChecker.Error.NoError)
        );
    }

    function test_validateECDSASignature_vrs() external {
        bytes32 digest_ = "TEST_DIGEST";
        (address account_, uint256 privateKey_) = makeAddrAndKey("account");
        (uint8 v_, bytes32 r_, bytes32 s_) = vm.sign(privateKey_, digest_);

        assertEq(
            uint8(SignatureChecker.validateECDSASignature(account_, digest_, v_, r_, s_)),
            uint8(SignatureChecker.Error.NoError)
        );
    }

    function test_validateECDSASignature_bytes_invalid() external {
        bytes32 invalidS_ = bytes32(_MAX_S + 1);
        bytes32 digest_ = "TEST_DIGEST";
        (address account_, uint256 privateKey_) = makeAddrAndKey("account");
        (uint8 v_, bytes32 r_, bytes32 s_) = vm.sign(privateKey_, digest_);

        assertNotEq(
            uint8(SignatureChecker.validateECDSASignature(address(1), digest_, _encodeSignature(v_, r_, s_))),
            uint8(SignatureChecker.Error.NoError)
        );

        assertNotEq(
            uint8(SignatureChecker.validateECDSASignature(account_, "DIFF", _encodeSignature(v_, r_, s_))),
            uint8(SignatureChecker.Error.NoError)
        );

        assertNotEq(
            uint8(SignatureChecker.validateECDSASignature(account_, "digest_", _encodeSignature(26, r_, s_))),
            uint8(SignatureChecker.Error.NoError)
        );

        assertNotEq(
            uint8(SignatureChecker.validateECDSASignature(account_, "digest_", _encodeSignature(v_, 0, s_))),
            uint8(SignatureChecker.Error.NoError)
        );

        assertNotEq(
            uint8(SignatureChecker.validateECDSASignature(account_, "digest_", _encodeSignature(v_, r_, invalidS_))),
            uint8(SignatureChecker.Error.NoError)
        );
    }

    function test_validateECDSASignature_bytes() external {
        bytes32 digest_ = "TEST_DIGEST";
        (address account_, uint256 privateKey_) = makeAddrAndKey("account");
        (uint8 v_, bytes32 r_, bytes32 s_) = vm.sign(privateKey_, digest_);

        assertEq(
            uint8(SignatureChecker.validateECDSASignature(account_, digest_, _encodeSignature(v_, r_, s_))),
            uint8(SignatureChecker.Error.NoError)
        );
    }

    function test_isValidECDSASignature_vrs_invalid() external {
        bytes32 digest_ = "TEST_DIGEST";
        (address account_, uint256 privateKey_) = makeAddrAndKey("account");
        (uint8 v_, bytes32 r_, bytes32 s_) = vm.sign(privateKey_, digest_);

        assertFalse(SignatureChecker.isValidECDSASignature(address(1), digest_, v_, r_, s_));
        assertFalse(SignatureChecker.isValidECDSASignature(account_, "DIFF", v_, r_, s_));
        assertFalse(SignatureChecker.isValidECDSASignature(account_, digest_, 26, r_, s_));
        assertFalse(SignatureChecker.isValidECDSASignature(account_, digest_, v_, 0, s_));
        assertFalse(SignatureChecker.isValidECDSASignature(account_, digest_, v_, r_, bytes32(_MAX_S + 1)));
    }

    function test_isValidECDSASignature_vrs() external {
        bytes32 digest_ = "TEST_DIGEST";
        (address account_, uint256 privateKey_) = makeAddrAndKey("account");

        (uint8 v_, bytes32 r_, bytes32 s_) = vm.sign(privateKey_, digest_);

        assertTrue(SignatureChecker.isValidECDSASignature(account_, digest_, v_, r_, s_));
    }

    function test_isValidECDSASignature_bytes_invalid() external {
        bytes32 invalidS_ = bytes32(_MAX_S + 1);
        bytes32 digest_ = "TEST_DIGEST";
        (address account_, uint256 privateKey_) = makeAddrAndKey("account");
        (uint8 v_, bytes32 r_, bytes32 s_) = vm.sign(privateKey_, digest_);

        assertFalse(SignatureChecker.isValidECDSASignature(address(1), digest_, _encodeSignature(v_, r_, s_)));
        assertFalse(SignatureChecker.isValidECDSASignature(account_, "DIFF", _encodeSignature(v_, r_, s_)));
        assertFalse(SignatureChecker.isValidECDSASignature(account_, digest_, _encodeSignature(26, r_, s_)));
        assertFalse(SignatureChecker.isValidECDSASignature(account_, digest_, _encodeSignature(v_, 0, s_)));
        assertFalse(SignatureChecker.isValidECDSASignature(account_, digest_, _encodeSignature(v_, r_, invalidS_)));
    }

    function test_isValidECDSASignature_bytes() external {
        bytes32 digest_ = "TEST_DIGEST";
        (address account_, uint256 privateKey_) = makeAddrAndKey("account");

        (uint8 v_, bytes32 r_, bytes32 s_) = vm.sign(privateKey_, digest_);

        assertTrue(SignatureChecker.isValidECDSASignature(account_, digest_, _encodeSignature(v_, r_, s_)));
    }

    function test_isValidERC1271Signature_emptyAccount() external {
        assertFalse(SignatureChecker.isValidERC1271Signature(makeAddr("account"), "DIGEST", ""));
    }

    function test_isValidERC1271Signature_accountWithFallback() external {
        assertFalse(SignatureChecker.isValidERC1271Signature(address(new AccountWithFallback()), "DIGEST", ""));
    }

    function test_isValidERC1271Signature_accountWithoutFallback() external {
        assertFalse(SignatureChecker.isValidERC1271Signature(address(new AccountWithoutFallback()), "DIGEST", ""));
    }

    function test_isValidERC1271Signature_accountFailsSilently() external {
        assertFalse(SignatureChecker.isValidERC1271Signature(address(new AccountWithEmptyFunction()), "DIGEST", ""));
    }

    function test_isValidERC1271Signature_accountReverts() external {
        assertFalse(
            SignatureChecker.isValidERC1271Signature(address(new AccountWithRevertingFunction()), "DIGEST", "")
        );
    }

    function test_isValidERC1271Signature_accountReturnsTrue() external {
        assertFalse(
            SignatureChecker.isValidERC1271Signature(address(new AccountWithFunctionReturningTrue()), "DIGEST", "")
        );
    }

    function test_isValidERC1271Signature_accountReturnsNothing() external {
        assertFalse(
            SignatureChecker.isValidERC1271Signature(address(new AccountWithFunctionReturningNothing()), "DIGEST", "")
        );
    }

    function test_isValidERC1271Signature_accountReturnsInvalidData() external {
        assertFalse(
            SignatureChecker.isValidERC1271Signature(
                address(new AccountWithFunctionReturningInvalidData()),
                "DIGEST",
                ""
            )
        );
    }

    function test_isValidERC1271Signature() external {
        assertTrue(SignatureChecker.isValidERC1271Signature(address(new AccountWithValidFunction()), "DIGEST", ""));
    }

    function test_isValidSignature_invalid() external {
        bytes32 invalidS_ = bytes32(_MAX_S + 1);
        bytes32 digest_ = "TEST_DIGEST";
        (address account_, uint256 privateKey_) = makeAddrAndKey("account");
        (uint8 v_, bytes32 r_, bytes32 s_) = vm.sign(privateKey_, digest_);

        assertFalse(SignatureChecker.isValidSignature(address(1), digest_, _encodeSignature(v_, r_, s_)));
        assertFalse(SignatureChecker.isValidSignature(account_, "DIFF", _encodeSignature(v_, r_, s_)));
        assertFalse(SignatureChecker.isValidSignature(account_, digest_, _encodeSignature(26, r_, s_)));
        assertFalse(SignatureChecker.isValidSignature(account_, digest_, _encodeSignature(v_, 0, s_)));
        assertFalse(SignatureChecker.isValidSignature(account_, digest_, _encodeSignature(v_, r_, invalidS_)));

        assertFalse(SignatureChecker.isValidSignature(makeAddr("account"), "DIGEST", ""));
        assertFalse(SignatureChecker.isValidSignature(address(new AccountWithFallback()), "DIGEST", ""));
        assertFalse(SignatureChecker.isValidSignature(address(new AccountWithoutFallback()), "DIGEST", ""));
        assertFalse(SignatureChecker.isValidSignature(address(new AccountWithEmptyFunction()), "DIGEST", ""));
        assertFalse(SignatureChecker.isValidSignature(address(new AccountWithRevertingFunction()), "DIGEST", ""));
        assertFalse(SignatureChecker.isValidSignature(address(new AccountWithFunctionReturningTrue()), "DIGEST", ""));
        assertFalse(
            SignatureChecker.isValidSignature(address(new AccountWithFunctionReturningNothing()), "DIGEST", "")
        );
        assertFalse(
            SignatureChecker.isValidSignature(address(new AccountWithFunctionReturningInvalidData()), "DIGEST", "")
        );
    }

    function test_isValidSignature_ecdsa() external {
        bytes32 digest_ = "TEST_DIGEST";
        (address account_, uint256 privateKey_) = makeAddrAndKey("account");

        (uint8 v_, bytes32 r_, bytes32 s_) = vm.sign(privateKey_, digest_);

        assertTrue(SignatureChecker.isValidSignature(account_, digest_, _encodeSignature(v_, r_, s_)));
    }

    function test_isValidSignature_erc1271() external {
        assertTrue(SignatureChecker.isValidSignature(address(new AccountWithValidFunction()), "DIGEST", ""));
    }

    function _encodeSignature(uint8 v_, bytes32 r_, bytes32 s_) internal pure returns (bytes memory signature_) {
        return abi.encodePacked(r_, s_, v_);
    }
}
