// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.23;

import { IERC3009 } from "../src/interfaces/IERC3009.sol";
import { IERC712 } from "../src/interfaces/IERC712.sol";

import { ERC20ExtendedHarness } from "./utils/ERC20ExtendedHarness.sol";
import { TestUtils } from "./utils/TestUtils.t.sol";

contract ERC3009Tests is TestUtils {
    bytes32 internal constant _SOME_NONCE = bytes32(uint256(1234));

    address internal _alice;
    uint256 internal _aliceKey;

    address internal _bob;
    uint256 internal _bobKey;

    address internal _charlie;
    uint256 internal _charlieKey;

    ERC20ExtendedHarness internal _token;

    function setUp() external {
        (_alice, _aliceKey) = makeAddrAndKey("alice");
        (_bob, _bobKey) = makeAddrAndKey("bob");
        (_charlie, _charlieKey) = makeAddrAndKey("charlie");

        _token = new ERC20ExtendedHarness("ERC3009 Token", "ERC3009_TKN", 0);
    }

    /* ============ Typehashes ============ */
    function test_transferWithAuthorizationTypehash() external {
        assertEq(
            _token.TRANSFER_WITH_AUTHORIZATION_TYPEHASH(),
            keccak256(
                "TransferWithAuthorization(address from,address to,uint256 value,uint256 validAfter,uint256 validBefore,bytes32 nonce)"
            )
        );
    }

    function test_receiveWithAuthorizationTypehash() external {
        assertEq(
            _token.RECEIVE_WITH_AUTHORIZATION_TYPEHASH(),
            keccak256(
                "ReceiveWithAuthorization(address from,address to,uint256 value,uint256 validAfter,uint256 validBefore,bytes32 nonce)"
            )
        );
    }

    function test_cancelAuthorizationTypehash() external {
        assertEq(
            _token.CANCEL_AUTHORIZATION_TYPEHASH(),
            keccak256("CancelAuthorization(address authorizer,bytes32 nonce)")
        );
    }

    /* ============ authorizationState ============ */
    function test_authorizationState() external {
        assertFalse(_token.authorizationState(_alice, _SOME_NONCE));

        _token.setAuthorizationState(_alice, _SOME_NONCE, true);
        assertTrue(_token.authorizationState(_alice, _SOME_NONCE));

        _token.setAuthorizationState(_alice, _SOME_NONCE, false);
        assertFalse(_token.authorizationState(_alice, _SOME_NONCE));
    }

    /* ============ transferWithAuthorization ============ */
    function test_transferWithAuthorization_fullSignature() external {
        uint256 value_ = 100;
        uint256 validAfter_ = 0;
        uint256 validBefore_ = type(uint256).max;

        _token.mint(_alice, value_);

        assertFalse(_token.authorizationState(_alice, _SOME_NONCE));

        (uint8 v_, bytes32 r_, bytes32 s_) = _signDigest(
            _aliceKey,
            _token.getTransferWithAuthorizationDigest(_alice, _bob, value_, validAfter_, validBefore_, _SOME_NONCE)
        );

        vm.expectEmit();
        emit IERC3009.AuthorizationUsed(_alice, _SOME_NONCE);

        vm.prank(_charlie);
        _token.transferWithAuthorization(
            _alice,
            _bob,
            value_,
            validAfter_,
            validBefore_,
            _SOME_NONCE,
            _encodeSignature(v_, r_, s_)
        );

        assertTrue(_token.authorizationState(_alice, _SOME_NONCE));
    }

    function testFuzz_transferWithAuthorization_fullSignature(
        uint256 value_,
        uint256 validAfter_,
        uint256 validBefore_
    ) external {
        validBefore_ = bound(validBefore_, block.timestamp, type(uint256).max);
        validAfter_ = bound(validAfter_, 0, block.timestamp);

        _token.mint(_alice, value_);

        assertFalse(_token.authorizationState(_alice, _SOME_NONCE));

        (uint8 v_, bytes32 r_, bytes32 s_) = _signDigest(
            _aliceKey,
            _token.getTransferWithAuthorizationDigest(_alice, _bob, value_, validAfter_, validBefore_, _SOME_NONCE)
        );

        vm.expectEmit();
        emit IERC3009.AuthorizationUsed(_alice, _SOME_NONCE);

        vm.prank(_charlie);
        _token.transferWithAuthorization(
            _alice,
            _bob,
            value_,
            validAfter_,
            validBefore_,
            _SOME_NONCE,
            _encodeSignature(v_, r_, s_)
        );

        assertTrue(_token.authorizationState(_alice, _SOME_NONCE));
    }

    function test_transferWithAuthorization_rvsSignature() external {
        uint256 value_ = 100;
        uint256 validAfter_ = 0;
        uint256 validBefore_ = type(uint256).max;

        _token.mint(_alice, value_);

        assertFalse(_token.authorizationState(_alice, _SOME_NONCE));

        (uint8 v_, bytes32 r_, bytes32 s_) = _signDigest(
            _aliceKey,
            _token.getTransferWithAuthorizationDigest(_alice, _bob, value_, validAfter_, validBefore_, _SOME_NONCE)
        );

        vm.expectEmit();
        emit IERC3009.AuthorizationUsed(_alice, _SOME_NONCE);

        vm.prank(_charlie);
        _token.transferWithAuthorization(
            _alice,
            _bob,
            value_,
            validAfter_,
            validBefore_,
            _SOME_NONCE,
            r_,
            _getVS(v_, s_)
        );

        assertTrue(_token.authorizationState(_alice, _SOME_NONCE));
    }

    function testFuzz_transferWithAuthorization_rvsSignature(
        uint256 value_,
        uint256 validAfter_,
        uint256 validBefore_
    ) external {
        validBefore_ = bound(validBefore_, block.timestamp, type(uint256).max);
        validAfter_ = bound(validAfter_, 0, block.timestamp);

        _token.mint(_alice, value_);

        assertFalse(_token.authorizationState(_alice, _SOME_NONCE));

        (uint8 v_, bytes32 r_, bytes32 s_) = _signDigest(
            _aliceKey,
            _token.getTransferWithAuthorizationDigest(_alice, _bob, value_, validAfter_, validBefore_, _SOME_NONCE)
        );

        vm.expectEmit();
        emit IERC3009.AuthorizationUsed(_alice, _SOME_NONCE);

        vm.prank(_charlie);
        _token.transferWithAuthorization(
            _alice,
            _bob,
            value_,
            validAfter_,
            validBefore_,
            _SOME_NONCE,
            r_,
            _getVS(v_, s_)
        );

        assertTrue(_token.authorizationState(_alice, _SOME_NONCE));
    }

    function test_transferWithAuthorization_vrsSignature() external {
        uint256 value_ = 100;
        uint256 validAfter_ = 0;
        uint256 validBefore_ = type(uint256).max;

        _token.mint(_alice, value_);

        assertFalse(_token.authorizationState(_alice, _SOME_NONCE));

        (uint8 v_, bytes32 r_, bytes32 s_) = _signDigest(
            _aliceKey,
            _token.getTransferWithAuthorizationDigest(_alice, _bob, value_, validAfter_, validBefore_, _SOME_NONCE)
        );

        vm.expectEmit();
        emit IERC3009.AuthorizationUsed(_alice, _SOME_NONCE);

        vm.prank(_charlie);
        _token.transferWithAuthorization(_alice, _bob, value_, validAfter_, validBefore_, _SOME_NONCE, v_, r_, s_);

        assertTrue(_token.authorizationState(_alice, _SOME_NONCE));
    }

    function testFuzz_transferWithAuthorization_vrsSignature(
        uint256 value_,
        uint256 validAfter_,
        uint256 validBefore_
    ) external {
        validBefore_ = bound(validBefore_, block.timestamp, type(uint256).max);
        validAfter_ = bound(validAfter_, 0, block.timestamp);

        _token.mint(_alice, value_);

        assertFalse(_token.authorizationState(_alice, _SOME_NONCE));

        (uint8 v_, bytes32 r_, bytes32 s_) = _signDigest(
            _aliceKey,
            _token.getTransferWithAuthorizationDigest(_alice, _bob, value_, validAfter_, validBefore_, _SOME_NONCE)
        );

        vm.expectEmit();
        emit IERC3009.AuthorizationUsed(_alice, _SOME_NONCE);

        vm.prank(_charlie);
        _token.transferWithAuthorization(_alice, _bob, value_, validAfter_, validBefore_, _SOME_NONCE, v_, r_, s_);

        assertTrue(_token.authorizationState(_alice, _SOME_NONCE));
    }

    function test_transferWithAuthorization_invalidParameter() external {
        uint256 value_ = 100;
        uint256 validAfter_ = 0;
        uint256 validBefore_ = type(uint256).max;

        (uint8 v_, bytes32 r_, bytes32 s_) = _signDigest(
            _aliceKey,
            _token.getTransferWithAuthorizationDigest(_alice, _bob, value_, validAfter_, validBefore_, _SOME_NONCE)
        );

        vm.expectRevert(IERC712.SignerMismatch.selector);
        vm.prank(_charlie);
        _token.transferWithAuthorization(address(0), _bob, value_, validAfter_, validBefore_, _SOME_NONCE, v_, r_, s_);

        vm.expectRevert(IERC712.SignerMismatch.selector);
        vm.prank(_charlie);
        _token.transferWithAuthorization(
            _alice,
            address(0),
            value_,
            validAfter_,
            validBefore_,
            _SOME_NONCE,
            v_,
            r_,
            s_
        );

        vm.expectRevert(IERC712.SignerMismatch.selector);
        vm.prank(_charlie);
        _token.transferWithAuthorization(_alice, _bob, value_ + 1, validAfter_, validBefore_, _SOME_NONCE, v_, r_, s_);

        vm.expectRevert(IERC712.SignerMismatch.selector);
        vm.prank(_charlie);
        _token.transferWithAuthorization(_alice, _bob, value_, validAfter_ + 1, validBefore_, _SOME_NONCE, v_, r_, s_);

        vm.expectRevert(IERC712.SignerMismatch.selector);
        vm.prank(_charlie);
        _token.transferWithAuthorization(_alice, _bob, value_, validAfter_, validBefore_ - 1, _SOME_NONCE, v_, r_, s_);

        vm.expectRevert(IERC712.SignerMismatch.selector);
        vm.prank(_charlie);
        _token.transferWithAuthorization(_alice, _bob, value_, validAfter_, validBefore_, bytes32(0), v_, r_, s_);
    }

    function test_transferWithAuthorization_invalidSigner() external {
        uint256 value_ = 100;
        uint256 validAfter_ = 0;
        uint256 validBefore_ = type(uint256).max;

        (uint8 v_, bytes32 r_, bytes32 s_) = _signDigest(
            _bobKey, // Wrong signer.
            _token.getTransferWithAuthorizationDigest(_alice, _bob, value_, validAfter_, validBefore_, _SOME_NONCE)
        );

        vm.expectRevert(IERC712.SignerMismatch.selector);

        vm.prank(_charlie);
        _token.transferWithAuthorization(_alice, _bob, value_, validAfter_, validBefore_, _SOME_NONCE, v_, r_, s_);
    }

    function test_transferWithAuthorization_authorizationNotYetValid() external {
        uint256 value_ = 100;
        uint256 validAfter_ = block.timestamp + 1; // Not yet valid.
        uint256 validBefore_ = type(uint256).max;

        (uint8 v_, bytes32 r_, bytes32 s_) = _signDigest(
            _aliceKey,
            _token.getTransferWithAuthorizationDigest(_alice, _bob, value_, validAfter_, validBefore_, _SOME_NONCE)
        );

        vm.expectRevert(
            abi.encodeWithSelector(IERC3009.AuthorizationNotYetValid.selector, block.timestamp, validAfter_)
        );

        vm.prank(_charlie);
        _token.transferWithAuthorization(_alice, _bob, value_, validAfter_, validBefore_, _SOME_NONCE, v_, r_, s_);
    }

    function test_transferWithAuthorization_authorizationExpired() external {
        uint256 value_ = 100;
        uint256 validAfter_ = 0;
        uint256 validBefore_ = block.timestamp - 1; // Already expired.

        (uint8 v_, bytes32 r_, bytes32 s_) = _signDigest(
            _aliceKey,
            _token.getTransferWithAuthorizationDigest(_alice, _bob, value_, validAfter_, validBefore_, _SOME_NONCE)
        );

        vm.expectRevert(abi.encodeWithSelector(IERC3009.AuthorizationExpired.selector, block.timestamp, validBefore_));

        vm.prank(_charlie);
        _token.transferWithAuthorization(_alice, _bob, value_, validAfter_, validBefore_, _SOME_NONCE, v_, r_, s_);
    }

    function test_transferWithAuthorization_authorizationAlreadyUsed() external {
        uint256 value_ = 100;
        uint256 validAfter_ = 0;
        uint256 validBefore_ = type(uint256).max;

        (uint8 v_, bytes32 r_, bytes32 s_) = _signDigest(
            _aliceKey,
            _token.getTransferWithAuthorizationDigest(_alice, _bob, value_, validAfter_, validBefore_, _SOME_NONCE)
        );

        _token.setAuthorizationState(_alice, _SOME_NONCE, true);

        vm.expectRevert(abi.encodeWithSelector(IERC3009.AuthorizationAlreadyUsed.selector, _alice, _SOME_NONCE));

        vm.prank(_charlie);
        _token.transferWithAuthorization(_alice, _bob, value_, validAfter_, validBefore_, _SOME_NONCE, v_, r_, s_);
    }

    function test_transferWithAuthorization_cannotUseReceiveAuthorization() external {
        uint256 value_ = 100;
        uint256 validAfter_ = 0;
        uint256 validBefore_ = type(uint256).max;

        (uint8 v_, bytes32 r_, bytes32 s_) = _signDigest(
            _aliceKey,
            _token.getReceiveWithAuthorizationDigest(_alice, _bob, value_, validAfter_, validBefore_, _SOME_NONCE)
        );

        vm.expectRevert(IERC712.SignerMismatch.selector);

        vm.prank(_charlie);
        _token.transferWithAuthorization(_alice, _bob, value_, validAfter_, validBefore_, _SOME_NONCE, v_, r_, s_);
    }

    /* ============ receiveWithAuthorization ============ */
    function test_receiveWithAuthorization_fullSignature() external {
        uint256 value_ = 100;
        uint256 validAfter_ = 0;
        uint256 validBefore_ = type(uint256).max;

        _token.mint(_alice, value_);

        assertFalse(_token.authorizationState(_alice, _SOME_NONCE));

        (uint8 v_, bytes32 r_, bytes32 s_) = _signDigest(
            _aliceKey,
            _token.getReceiveWithAuthorizationDigest(_alice, _bob, value_, validAfter_, validBefore_, _SOME_NONCE)
        );

        vm.expectEmit();
        emit IERC3009.AuthorizationUsed(_alice, _SOME_NONCE);

        vm.prank(_bob);
        _token.receiveWithAuthorization(
            _alice,
            _bob,
            value_,
            validAfter_,
            validBefore_,
            _SOME_NONCE,
            abi.encodePacked(r_, s_, v_)
        );

        assertTrue(_token.authorizationState(_alice, _SOME_NONCE));
    }

    function testFuzz_receiveWithAuthorization_fullSignature(
        uint256 value_,
        uint256 validAfter_,
        uint256 validBefore_
    ) external {
        validBefore_ = bound(validBefore_, block.timestamp, type(uint256).max);
        validAfter_ = bound(validAfter_, 0, block.timestamp);

        _token.mint(_alice, value_);

        assertFalse(_token.authorizationState(_alice, _SOME_NONCE));

        (uint8 v_, bytes32 r_, bytes32 s_) = _signDigest(
            _aliceKey,
            _token.getReceiveWithAuthorizationDigest(_alice, _bob, value_, validAfter_, validBefore_, _SOME_NONCE)
        );

        vm.expectEmit();
        emit IERC3009.AuthorizationUsed(_alice, _SOME_NONCE);

        vm.prank(_bob);
        _token.receiveWithAuthorization(
            _alice,
            _bob,
            value_,
            validAfter_,
            validBefore_,
            _SOME_NONCE,
            _encodeSignature(v_, r_, s_)
        );

        assertTrue(_token.authorizationState(_alice, _SOME_NONCE));
    }

    function test_receiveWithAuthorization_rvsSignature() external {
        uint256 value_ = 100;
        uint256 validAfter_ = 0;
        uint256 validBefore_ = type(uint256).max;

        _token.mint(_alice, value_);

        assertFalse(_token.authorizationState(_alice, _SOME_NONCE));

        (uint8 v_, bytes32 r_, bytes32 s_) = _signDigest(
            _aliceKey,
            _token.getReceiveWithAuthorizationDigest(_alice, _bob, value_, validAfter_, validBefore_, _SOME_NONCE)
        );

        vm.expectEmit();
        emit IERC3009.AuthorizationUsed(_alice, _SOME_NONCE);

        vm.prank(_bob);
        _token.receiveWithAuthorization(
            _alice,
            _bob,
            value_,
            validAfter_,
            validBefore_,
            _SOME_NONCE,
            r_,
            _getVS(v_, s_)
        );

        assertTrue(_token.authorizationState(_alice, _SOME_NONCE));
    }

    function testFuzz_receiveWithAuthorization_rvsSignature(
        uint256 value_,
        uint256 validAfter_,
        uint256 validBefore_
    ) external {
        validBefore_ = bound(validBefore_, block.timestamp, type(uint256).max);
        validAfter_ = bound(validAfter_, 0, block.timestamp);

        _token.mint(_alice, value_);

        assertFalse(_token.authorizationState(_alice, _SOME_NONCE));

        (uint8 v_, bytes32 r_, bytes32 s_) = _signDigest(
            _aliceKey,
            _token.getReceiveWithAuthorizationDigest(_alice, _bob, value_, validAfter_, validBefore_, _SOME_NONCE)
        );

        vm.expectEmit();
        emit IERC3009.AuthorizationUsed(_alice, _SOME_NONCE);

        vm.prank(_bob);
        _token.receiveWithAuthorization(
            _alice,
            _bob,
            value_,
            validAfter_,
            validBefore_,
            _SOME_NONCE,
            r_,
            _getVS(v_, s_)
        );

        assertTrue(_token.authorizationState(_alice, _SOME_NONCE));
    }

    function test_receiveWithAuthorization_vrsSignature() external {
        uint256 value_ = 100;
        uint256 validAfter_ = 0;
        uint256 validBefore_ = type(uint256).max;

        _token.mint(_alice, value_);

        assertFalse(_token.authorizationState(_alice, _SOME_NONCE));

        (uint8 v_, bytes32 r_, bytes32 s_) = _signDigest(
            _aliceKey,
            _token.getReceiveWithAuthorizationDigest(_alice, _bob, value_, validAfter_, validBefore_, _SOME_NONCE)
        );

        vm.expectEmit();
        emit IERC3009.AuthorizationUsed(_alice, _SOME_NONCE);

        vm.prank(_bob);
        _token.receiveWithAuthorization(_alice, _bob, value_, validAfter_, validBefore_, _SOME_NONCE, v_, r_, s_);

        assertTrue(_token.authorizationState(_alice, _SOME_NONCE));
    }

    function testFuzz_receiveWithAuthorization_vrsSignature(
        uint256 value_,
        uint256 validAfter_,
        uint256 validBefore_
    ) external {
        validBefore_ = bound(validBefore_, block.timestamp, type(uint256).max);
        validAfter_ = bound(validAfter_, 0, block.timestamp);

        _token.mint(_alice, value_);

        assertFalse(_token.authorizationState(_alice, _SOME_NONCE));

        (uint8 v_, bytes32 r_, bytes32 s_) = _signDigest(
            _aliceKey,
            _token.getReceiveWithAuthorizationDigest(_alice, _bob, value_, validAfter_, validBefore_, _SOME_NONCE)
        );

        vm.expectEmit();
        emit IERC3009.AuthorizationUsed(_alice, _SOME_NONCE);

        vm.prank(_bob);
        _token.receiveWithAuthorization(_alice, _bob, value_, validAfter_, validBefore_, _SOME_NONCE, v_, r_, s_);

        assertTrue(_token.authorizationState(_alice, _SOME_NONCE));
    }

    function test_receiveWithAuthorization_callerMustBePayee() external {
        uint256 value_ = 100;
        uint256 validAfter_ = 0;
        uint256 validBefore_ = type(uint256).max;

        (uint8 v_, bytes32 r_, bytes32 s_) = _signDigest(
            _aliceKey,
            _token.getReceiveWithAuthorizationDigest(_alice, _bob, value_, validAfter_, validBefore_, _SOME_NONCE)
        );

        vm.expectRevert(abi.encodeWithSelector(IERC3009.CallerMustBePayee.selector, _charlie, _bob));

        vm.prank(_charlie);
        _token.receiveWithAuthorization(_alice, _bob, value_, validAfter_, validBefore_, _SOME_NONCE, v_, r_, s_);
    }

    function test_receiveWithAuthorization_invalidParameter() external {
        uint256 value_ = 100;
        uint256 validAfter_ = 0;
        uint256 validBefore_ = type(uint256).max;

        (uint8 v_, bytes32 r_, bytes32 s_) = _signDigest(
            _aliceKey,
            _token.getReceiveWithAuthorizationDigest(_alice, _bob, value_, validAfter_, validBefore_, _SOME_NONCE)
        );

        vm.expectRevert(IERC712.SignerMismatch.selector);
        vm.prank(_bob);
        _token.receiveWithAuthorization(address(0), _bob, value_, validAfter_, validBefore_, _SOME_NONCE, v_, r_, s_);

        vm.expectRevert(IERC712.SignerMismatch.selector);
        vm.prank(_bob);
        _token.receiveWithAuthorization(_alice, address(0), value_, validAfter_, validBefore_, _SOME_NONCE, v_, r_, s_);

        vm.expectRevert(IERC712.SignerMismatch.selector);
        vm.prank(_bob);
        _token.receiveWithAuthorization(_alice, _bob, value_ + 1, validAfter_, validBefore_, _SOME_NONCE, v_, r_, s_);

        vm.expectRevert(IERC712.SignerMismatch.selector);
        vm.prank(_bob);
        _token.receiveWithAuthorization(_alice, _bob, value_, validAfter_ + 1, validBefore_, _SOME_NONCE, v_, r_, s_);

        vm.expectRevert(IERC712.SignerMismatch.selector);
        vm.prank(_bob);
        _token.receiveWithAuthorization(_alice, _bob, value_, validAfter_, validBefore_ - 1, _SOME_NONCE, v_, r_, s_);

        vm.expectRevert(IERC712.SignerMismatch.selector);
        vm.prank(_bob);
        _token.receiveWithAuthorization(_alice, _bob, value_, validAfter_, validBefore_, bytes32(0), v_, r_, s_);
    }

    function test_receiveWithAuthorization_invalidSigner() external {
        uint256 value_ = 100;
        uint256 validAfter_ = 0;
        uint256 validBefore_ = type(uint256).max;

        (uint8 v_, bytes32 r_, bytes32 s_) = _signDigest(
            _bobKey, // Wrong signer.
            _token.getReceiveWithAuthorizationDigest(_alice, _bob, value_, validAfter_, validBefore_, _SOME_NONCE)
        );

        vm.expectRevert(IERC712.SignerMismatch.selector);

        vm.prank(_bob);
        _token.receiveWithAuthorization(_alice, _bob, value_, validAfter_, validBefore_, _SOME_NONCE, v_, r_, s_);
    }

    function test_receiveWithAuthorization_authorizationNotYetValid() external {
        uint256 value_ = 100;
        uint256 validAfter_ = block.timestamp + 10; // Not yet valid.
        uint256 validBefore_ = type(uint256).max;

        (uint8 v_, bytes32 r_, bytes32 s_) = _signDigest(
            _aliceKey,
            _token.getReceiveWithAuthorizationDigest(_alice, _bob, value_, validAfter_, validBefore_, _SOME_NONCE)
        );

        vm.expectRevert(
            abi.encodeWithSelector(IERC3009.AuthorizationNotYetValid.selector, block.timestamp, validAfter_)
        );

        vm.prank(_bob);
        _token.receiveWithAuthorization(_alice, _bob, value_, validAfter_, validBefore_, _SOME_NONCE, v_, r_, s_);
    }

    function test_receiveWithAuthorization_authorizationExpired() external {
        uint256 value_ = 100;
        uint256 validAfter_ = 0;
        uint256 validBefore_ = block.timestamp - 10; // Already expired.

        (uint8 v_, bytes32 r_, bytes32 s_) = _signDigest(
            _aliceKey,
            _token.getReceiveWithAuthorizationDigest(_alice, _bob, value_, validAfter_, validBefore_, _SOME_NONCE)
        );

        vm.expectRevert(abi.encodeWithSelector(IERC3009.AuthorizationExpired.selector, block.timestamp, validBefore_));

        vm.prank(_bob);
        _token.receiveWithAuthorization(_alice, _bob, value_, validAfter_, validBefore_, _SOME_NONCE, v_, r_, s_);
    }

    function test_receiveWithAuthorization_authorizationAlreadyUsed() external {
        uint256 value_ = 100;
        uint256 validAfter_ = 0;
        uint256 validBefore_ = type(uint256).max;

        (uint8 v_, bytes32 r_, bytes32 s_) = _signDigest(
            _aliceKey,
            _token.getReceiveWithAuthorizationDigest(_alice, _bob, value_, validAfter_, validBefore_, _SOME_NONCE)
        );

        _token.setAuthorizationState(_alice, _SOME_NONCE, true);

        vm.expectRevert(abi.encodeWithSelector(IERC3009.AuthorizationAlreadyUsed.selector, _alice, _SOME_NONCE));

        vm.prank(_bob);
        _token.receiveWithAuthorization(_alice, _bob, value_, validAfter_, validBefore_, _SOME_NONCE, v_, r_, s_);
    }

    function test_receiveWithAuthorization_cannotUseTransferAuthorization() external {
        uint256 value_ = 100;
        uint256 validAfter_ = 0;
        uint256 validBefore_ = type(uint256).max;

        (uint8 v_, bytes32 r_, bytes32 s_) = _signDigest(
            _aliceKey,
            _token.getTransferWithAuthorizationDigest(_alice, _bob, value_, validAfter_, validBefore_, _SOME_NONCE)
        );

        vm.expectRevert(IERC712.SignerMismatch.selector);

        vm.prank(_bob);
        _token.receiveWithAuthorization(_alice, _bob, value_, validAfter_, validBefore_, _SOME_NONCE, v_, r_, s_);
    }

    /* ============ cancelAuthorization ============ */
    function test_cancelAuthorization_cancelTransferAuthorization_fullSignature() external {
        assertFalse(_token.authorizationState(_alice, _SOME_NONCE));

        bytes32 digest_ = _token.getCancelAuthorizationDigest({ authorizer_: _alice, nonce_: _SOME_NONCE });
        (uint8 v_, bytes32 r_, bytes32 s_) = _signDigest(_aliceKey, digest_);

        vm.expectEmit();
        emit IERC3009.AuthorizationCanceled(_alice, _SOME_NONCE);

        vm.prank(_alice);
        _token.cancelAuthorization(_alice, _SOME_NONCE, abi.encodePacked(r_, s_, v_));

        assertTrue(_token.authorizationState(_alice, _SOME_NONCE));
    }

    function test_cancelAuthorization_cancelTransferAuthorization_rvsSignature() external {
        assertFalse(_token.authorizationState(_alice, _SOME_NONCE));

        bytes32 digest_ = _token.getCancelAuthorizationDigest({ authorizer_: _alice, nonce_: _SOME_NONCE });
        (uint8 v_, bytes32 r_, bytes32 s_) = _signDigest(_aliceKey, digest_);

        vm.expectEmit();
        emit IERC3009.AuthorizationCanceled(_alice, _SOME_NONCE);

        vm.prank(_alice);
        _token.cancelAuthorization(_alice, _SOME_NONCE, r_, _getVS(v_, s_));

        assertTrue(_token.authorizationState(_alice, _SOME_NONCE));
    }

    function test_cancelAuthorization_cancelTransferAuthorization_vrsSignature() external {
        assertFalse(_token.authorizationState(_alice, _SOME_NONCE));

        bytes32 digest_ = _token.getCancelAuthorizationDigest({ authorizer_: _alice, nonce_: _SOME_NONCE });
        (uint8 v_, bytes32 r_, bytes32 s_) = _signDigest(_aliceKey, digest_);

        vm.expectEmit();
        emit IERC3009.AuthorizationCanceled(_alice, _SOME_NONCE);

        vm.prank(_alice);
        _token.cancelAuthorization(_alice, _SOME_NONCE, v_, r_, s_);

        assertTrue(_token.authorizationState(_alice, _SOME_NONCE));
    }

    function test_cancelAuthorization_authorizationAlreadyCanceled() external {
        assertFalse(_token.authorizationState(_alice, _SOME_NONCE));

        bytes32 digest_ = _token.getCancelAuthorizationDigest({ authorizer_: _alice, nonce_: _SOME_NONCE });
        (uint8 v_, bytes32 r_, bytes32 s_) = _signDigest(_aliceKey, digest_);

        _token.setAuthorizationState(_alice, _SOME_NONCE, true);

        vm.expectRevert(abi.encodeWithSelector(IERC3009.AuthorizationAlreadyUsed.selector, _alice, _SOME_NONCE));

        vm.prank(_alice);
        _token.cancelAuthorization(_alice, _SOME_NONCE, v_, r_, s_);
    }
}
