// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.23;

import { IERC3009 } from "../src/interfaces/IERC3009.sol";
import { SignatureChecker } from "../src/libs/SignatureChecker.sol";

import { ERC20ExtendedHarness } from "./utils/ERC20ExtendedHarness.sol";
import { TestUtils } from "./utils/TestUtils.t.sol";

contract ERC3009Tests is TestUtils {
    ERC20ExtendedHarness internal _token;
    string internal constant _NAME = "ERC3009 Token";
    string internal constant _SYMBOL = "ERC3009_TKN";
    uint8 internal constant _DECIMALS = 6;

    address _alice;
    uint256 _aliceKey;

    address _bob;
    uint256 _bobKey;

    address _charlie;
    uint256 _charlieKey;

    bytes32 _transferAuthorizationDigest;
    bytes32 _receiveAuthorizationDigest;
    bytes32 _cancelAuthorizationDigest;

    function setUp() external {
        (_alice, _aliceKey) = makeAddrAndKey("alice");
        (_bob, _bobKey) = makeAddrAndKey("bob");
        (_charlie, _charlieKey) = makeAddrAndKey("charlie");

        _token = new ERC20ExtendedHarness(_NAME, _SYMBOL, _DECIMALS);

        (
            address from_,
            ,
            address to_,
            uint256 value_,
            uint256 validAfter_,
            uint256 validBefore_,
            bytes32 fromNonce_
        ) = _getTransferParams();

        _receiveAuthorizationDigest = _getReceiveWithAuthorizationDigest(
            _token,
            from_,
            to_,
            value_,
            validAfter_,
            validBefore_,
            fromNonce_
        );

        _transferAuthorizationDigest = _getTransferWithAuthorizationDigest(
            _token,
            from_,
            to_,
            value_,
            validAfter_,
            validBefore_,
            fromNonce_
        );

        _cancelAuthorizationDigest = _getCancelAuthorizationDigest(_token, from_, fromNonce_);
    }

    /* ============ Typehashes ============ */
    function test_TransferWithAuthorizationTypehash() external {
        assertEq(
            _token.TRANSFER_WITH_AUTHORIZATION_TYPEHASH(),
            keccak256(
                "TransferWithAuthorization(address from,address to,uint256 value,uint256 validAfter,uint256 validBefore,bytes32 nonce)"
            )
        );
    }

    function test_ReceiveWithAuthorizationTypehash() external {
        assertEq(
            _token.RECEIVE_WITH_AUTHORIZATION_TYPEHASH(),
            keccak256(
                "ReceiveWithAuthorization(address from,address to,uint256 value,uint256 validAfter,uint256 validBefore,bytes32 nonce)"
            )
        );
    }

    function test_CancelAuthorizationTypehash() external {
        assertEq(
            _token.CANCEL_AUTHORIZATION_TYPEHASH(),
            keccak256("CancelAuthorization(address authorizer,bytes32 nonce)")
        );
    }

    /* ============ authorizationState ============ */
    function test_authorizationState() external {
        bytes32 nonce_ = bytes32(uint256(1));

        assertFalse(_token.authorizationState(_alice, nonce_));

        _token.setAuthorizationState(_alice, nonce_, true);
        assertTrue(_token.authorizationState(_alice, nonce_));

        _token.setAuthorizationState(_alice, nonce_, false);
        assertFalse(_token.authorizationState(_alice, nonce_));
    }

    /* ============ transferWithAuthorization ============ */
    function test_transferWithAuthorization() external {
        (
            address from_,
            uint256 fromPrivateKey_,
            address to_,
            uint256 value_,
            uint256 validAfter_,
            uint256 validBefore_,
            bytes32 fromNonce_
        ) = _getTransferParams();

        assertFalse(_token.authorizationState(from_, fromNonce_));

        (uint8 v_, bytes32 r_, bytes32 s_) = _signPermit(fromPrivateKey_, _transferAuthorizationDigest);

        vm.expectEmit();
        emit IERC3009.AuthorizationUsed(from_, fromNonce_);

        vm.prank(_charlie);
        _token.transferWithAuthorization(from_, to_, value_, validAfter_, validBefore_, fromNonce_, v_, r_, s_);

        assertTrue(_token.authorizationState(from_, fromNonce_));
    }

    function test_transferWithAuthorization_invalidParameter() external {
        (
            address from_,
            uint256 fromPrivateKey_,
            address to_,
            uint256 value_,
            uint256 validAfter_,
            uint256 validBefore_,
            bytes32 fromNonce_
        ) = _getTransferParams();

        (uint8 v_, bytes32 r_, bytes32 s_) = _signPermit(fromPrivateKey_, _transferAuthorizationDigest);

        // TODO: should not revert with SignerMismatch error
        vm.expectRevert();

        vm.prank(_charlie);
        _token.transferWithAuthorization(from_, to_, value_ * 2, validAfter_, validBefore_, fromNonce_, v_, r_, s_);
    }

    function test_transferWithAuthorization_invalidSigner() external {
        (
            address from_,
            ,
            address to_,
            uint256 value_,
            uint256 validAfter_,
            uint256 validBefore_,
            bytes32 fromNonce_
        ) = _getTransferParams();

        (uint8 v_, bytes32 r_, bytes32 s_) = _signPermit(_bobKey, _transferAuthorizationDigest);

        vm.expectRevert();

        vm.prank(_charlie);
        _token.transferWithAuthorization(from_, to_, value_, validAfter_, validBefore_, fromNonce_, v_, r_, s_);
    }

    function test_transferWithAuthorization_authorizationNotYetValid() external {
        (
            address from_,
            uint256 fromPrivateKey_,
            address to_,
            uint256 value_,
            uint256 validAfter_,
            uint256 validBefore_,
            bytes32 fromNonce_
        ) = _getTransferParams();

        validAfter_ = block.timestamp + 10;

        (uint8 v_, bytes32 r_, bytes32 s_) = _signPermit(fromPrivateKey_, _transferAuthorizationDigest);

        vm.expectRevert(
            abi.encodeWithSelector(IERC3009.AuthorizationNotYetValid.selector, block.timestamp, validAfter_)
        );

        vm.prank(_charlie);
        _token.transferWithAuthorization(from_, to_, value_, validAfter_, validBefore_, fromNonce_, v_, r_, s_);
    }

    function test_transferWithAuthorization_authorizationExpired() external {
        (
            address from_,
            uint256 fromPrivateKey_,
            address to_,
            uint256 value_,
            uint256 validAfter_,
            uint256 validBefore_,
            bytes32 fromNonce_
        ) = _getTransferParams();

        validBefore_ = block.timestamp - 10;

        (uint8 v_, bytes32 r_, bytes32 s_) = _signPermit(fromPrivateKey_, _transferAuthorizationDigest);

        vm.expectRevert(abi.encodeWithSelector(IERC3009.AuthorizationExpired.selector, block.timestamp, validBefore_));

        vm.prank(_charlie);
        _token.transferWithAuthorization(from_, to_, value_, validAfter_, validBefore_, fromNonce_, v_, r_, s_);
    }

    function test_transferWithAuthorization_authorizationAlreadyUsed() external {
        (
            address from_,
            uint256 fromPrivateKey_,
            address to_,
            uint256 value_,
            uint256 validAfter_,
            uint256 validBefore_,
            bytes32 fromNonce_
        ) = _getTransferParams();

        (uint8 v_, bytes32 r_, bytes32 s_) = _signPermit(fromPrivateKey_, _transferAuthorizationDigest);

        vm.prank(_charlie);
        _token.transferWithAuthorization(from_, to_, value_, validAfter_, validBefore_, fromNonce_, v_, r_, s_);

        vm.expectRevert(abi.encodeWithSelector(IERC3009.AuthorizationAlreadyUsed.selector, _alice, fromNonce_));

        vm.prank(_charlie);
        _token.transferWithAuthorization(from_, to_, value_, validAfter_, validBefore_, fromNonce_, v_, r_, s_);
    }

    function test_transferWithAuthorization_nonceAlreadyUsed() external {
        (
            address from_,
            uint256 fromPrivateKey_,
            address to_,
            uint256 value_,
            uint256 validAfter_,
            uint256 validBefore_,
            bytes32 fromNonce_
        ) = _getTransferParams();

        (uint8 v_, bytes32 r_, bytes32 s_) = _signPermit(fromPrivateKey_, _transferAuthorizationDigest);

        vm.prank(_charlie);
        _token.transferWithAuthorization(from_, to_, value_, validAfter_, validBefore_, fromNonce_, v_, r_, s_);

        (v_, r_, s_) = _signPermit(
            fromPrivateKey_,
            _getTransferWithAuthorizationDigest(_token, from_, to_, value_ * 2, validAfter_, validBefore_, fromNonce_)
        );

        vm.expectRevert(abi.encodeWithSelector(IERC3009.AuthorizationAlreadyUsed.selector, _alice, fromNonce_));

        vm.prank(_charlie);
        _token.transferWithAuthorization(from_, to_, value_ * 2, validAfter_, validBefore_, fromNonce_, v_, r_, s_);
    }

    function test_transferWithAuthorization_invalidSignature() external {
        (
            address from_,
            uint256 fromPrivateKey_,
            address to_,
            uint256 value_,
            uint256 validAfter_,
            uint256 validBefore_,
            bytes32 fromNonce_
        ) = _getTransferParams();

        (uint8 v_, bytes32 r_, bytes32 s_) = _signPermit(
            fromPrivateKey_,
            _getReceiveWithAuthorizationDigest(_token, from_, to_, value_, validAfter_, validBefore_, fromNonce_)
        );

        // TODO: should not revert with SignerMismatch error
        vm.expectRevert();

        vm.prank(_charlie);
        _token.transferWithAuthorization(from_, to_, value_, validAfter_, validBefore_, fromNonce_, v_, r_, s_);
    }

    /* ============ receiveWithAuthorization ============ */
    function test_receiveWithAuthorization() external {
        (
            address from_,
            uint256 fromPrivateKey_,
            address to_,
            uint256 value_,
            uint256 validAfter_,
            uint256 validBefore_,
            bytes32 fromNonce_
        ) = _getTransferParams();

        assertFalse(_token.authorizationState(from_, fromNonce_));

        (uint8 v_, bytes32 r_, bytes32 s_) = _signPermit(
            fromPrivateKey_,
            _getReceiveWithAuthorizationDigest(_token, from_, to_, value_, validAfter_, validBefore_, fromNonce_)
        );

        vm.expectEmit();
        emit IERC3009.AuthorizationUsed(from_, fromNonce_);

        vm.prank(_bob);
        _token.receiveWithAuthorization(from_, to_, value_, validAfter_, validBefore_, fromNonce_, v_, r_, s_);

        assertTrue(_token.authorizationState(from_, fromNonce_));
    }

    function test_receiveWithAuthorization_callerMustBePayee() external {
        (
            address from_,
            uint256 fromPrivateKey_,
            address to_,
            uint256 value_,
            uint256 validAfter_,
            uint256 validBefore_,
            bytes32 fromNonce_
        ) = _getTransferParams();

        (uint8 v_, bytes32 r_, bytes32 s_) = _signPermit(
            fromPrivateKey_,
            _getReceiveWithAuthorizationDigest(_token, from_, to_, value_, validAfter_, validBefore_, fromNonce_)
        );

        vm.expectRevert(abi.encodeWithSelector(IERC3009.CallerMustBePayee.selector, _charlie, to_));

        vm.prank(_charlie);
        _token.receiveWithAuthorization(from_, to_, value_, validAfter_, validBefore_, fromNonce_, v_, r_, s_);
    }

    function test_receiveWithAuthorization_invalidParameter() external {
        (
            address from_,
            uint256 fromPrivateKey_,
            address to_,
            uint256 value_,
            uint256 validAfter_,
            uint256 validBefore_,
            bytes32 fromNonce_
        ) = _getTransferParams();

        (uint8 v_, bytes32 r_, bytes32 s_) = _signPermit(
            fromPrivateKey_,
            _getReceiveWithAuthorizationDigest(_token, from_, to_, value_, validAfter_, validBefore_, fromNonce_)
        );

        // TODO: should not revert with SignerMismatch error
        vm.expectRevert();

        vm.prank(_bob);
        _token.receiveWithAuthorization(from_, to_, value_ * 2, validAfter_, validBefore_, fromNonce_, v_, r_, s_);
    }

    function test_receiveWithAuthorization_invalidSigner() external {
        (
            address from_,
            ,
            address to_,
            uint256 value_,
            uint256 validAfter_,
            uint256 validBefore_,
            bytes32 fromNonce_
        ) = _getTransferParams();

        (uint8 v_, bytes32 r_, bytes32 s_) = _signPermit(
            _bobKey,
            _getReceiveWithAuthorizationDigest(_token, from_, to_, value_, validAfter_, validBefore_, fromNonce_)
        );

        vm.expectRevert();

        vm.prank(_bob);
        _token.receiveWithAuthorization(from_, to_, value_, validAfter_, validBefore_, fromNonce_, v_, r_, s_);
    }

    function test_receiveWithAuthorization_authorizationNotYetValid() external {
        (
            address from_,
            uint256 fromPrivateKey_,
            address to_,
            uint256 value_,
            uint256 validAfter_,
            uint256 validBefore_,
            bytes32 fromNonce_
        ) = _getTransferParams();

        validAfter_ = block.timestamp + 10;

        (uint8 v_, bytes32 r_, bytes32 s_) = _signPermit(
            fromPrivateKey_,
            _getReceiveWithAuthorizationDigest(_token, from_, to_, value_, validAfter_, validBefore_, fromNonce_)
        );

        vm.expectRevert(
            abi.encodeWithSelector(IERC3009.AuthorizationNotYetValid.selector, block.timestamp, validAfter_)
        );

        vm.prank(_bob);
        _token.receiveWithAuthorization(from_, to_, value_, validAfter_, validBefore_, fromNonce_, v_, r_, s_);
    }

    function test_receiveWithAuthorization_authorizationExpired() external {
        (
            address from_,
            uint256 fromPrivateKey_,
            address to_,
            uint256 value_,
            uint256 validAfter_,
            uint256 validBefore_,
            bytes32 fromNonce_
        ) = _getTransferParams();

        validBefore_ = block.timestamp - 10;

        (uint8 v_, bytes32 r_, bytes32 s_) = _signPermit(
            fromPrivateKey_,
            _getReceiveWithAuthorizationDigest(_token, from_, to_, value_, validAfter_, validBefore_, fromNonce_)
        );

        vm.expectRevert(abi.encodeWithSelector(IERC3009.AuthorizationExpired.selector, block.timestamp, validBefore_));

        vm.prank(_bob);
        _token.receiveWithAuthorization(from_, to_, value_, validAfter_, validBefore_, fromNonce_, v_, r_, s_);
    }

    function test_receiveWithAuthorization_authorizationAlreadyUsed() external {
        (
            address from_,
            uint256 fromPrivateKey_,
            address to_,
            uint256 value_,
            uint256 validAfter_,
            uint256 validBefore_,
            bytes32 fromNonce_
        ) = _getTransferParams();

        (uint8 v_, bytes32 r_, bytes32 s_) = _signPermit(
            fromPrivateKey_,
            _getReceiveWithAuthorizationDigest(_token, from_, to_, value_, validAfter_, validBefore_, fromNonce_)
        );

        vm.prank(_bob);
        _token.receiveWithAuthorization(from_, to_, value_, validAfter_, validBefore_, fromNonce_, v_, r_, s_);

        vm.expectRevert(abi.encodeWithSelector(IERC3009.AuthorizationAlreadyUsed.selector, _alice, fromNonce_));

        vm.prank(_bob);
        _token.receiveWithAuthorization(from_, to_, value_, validAfter_, validBefore_, fromNonce_, v_, r_, s_);
    }

    function test_receiveWithAuthorization_nonceAlreadyUsed() external {
        (
            address from_,
            uint256 fromPrivateKey_,
            address to_,
            uint256 value_,
            uint256 validAfter_,
            uint256 validBefore_,
            bytes32 fromNonce_
        ) = _getTransferParams();

        (uint8 v_, bytes32 r_, bytes32 s_) = _signPermit(fromPrivateKey_, _receiveAuthorizationDigest);

        vm.prank(_bob);
        _token.receiveWithAuthorization(from_, to_, value_, validAfter_, validBefore_, fromNonce_, v_, r_, s_);

        (v_, r_, s_) = _signPermit(
            fromPrivateKey_,
            _getReceiveWithAuthorizationDigest(_token, from_, to_, value_ * 2, validAfter_, validBefore_, fromNonce_)
        );

        vm.expectRevert(abi.encodeWithSelector(IERC3009.AuthorizationAlreadyUsed.selector, _alice, fromNonce_));

        vm.prank(_bob);
        _token.receiveWithAuthorization(from_, to_, value_ * 2, validAfter_, validBefore_, fromNonce_, v_, r_, s_);
    }

    function test_receiveWithAuthorization_invalidSignature() external {
        (
            address from_,
            uint256 fromPrivateKey_,
            address to_,
            uint256 value_,
            uint256 validAfter_,
            uint256 validBefore_,
            bytes32 fromNonce_
        ) = _getTransferParams();

        (uint8 v_, bytes32 r_, bytes32 s_) = _signPermit(fromPrivateKey_, _transferAuthorizationDigest);

        // TODO: should not revert with SignerMismatch error
        vm.expectRevert();

        vm.prank(_bob);
        _token.receiveWithAuthorization(from_, to_, value_, validAfter_, validBefore_, fromNonce_, v_, r_, s_);
    }

    /* ============ cancelAuthorization ============ */
    function test_cancelAuthorization_cancelTransferAuthorization() external {
        (
            address from_,
            uint256 fromPrivateKey_,
            address to_,
            uint256 value_,
            uint256 validAfter_,
            uint256 validBefore_,
            bytes32 fromNonce_
        ) = _getTransferParams();

        assertFalse(_token.authorizationState(from_, fromNonce_));

        (uint8 transferV_, bytes32 transferR_, bytes32 transferS_) = _signPermit(
            fromPrivateKey_,
            _transferAuthorizationDigest
        );

        (uint8 v_, bytes32 r_, bytes32 s_) = _signPermit(fromPrivateKey_, _cancelAuthorizationDigest);

        vm.expectEmit();
        emit IERC3009.AuthorizationCanceled(from_, fromNonce_);

        vm.prank(_alice);
        _token.cancelAuthorization(from_, fromNonce_, v_, r_, s_);

        assertTrue(_token.authorizationState(from_, fromNonce_));

        vm.expectRevert(abi.encodeWithSelector(IERC3009.AuthorizationAlreadyUsed.selector, _alice, fromNonce_));

        vm.prank(_charlie);
        _token.transferWithAuthorization(
            from_,
            to_,
            value_,
            validAfter_,
            validBefore_,
            fromNonce_,
            transferV_,
            transferR_,
            transferS_
        );
    }

    function test_cancelAuthorization_cancelReceiveAuthorization() external {
        (
            address from_,
            uint256 fromPrivateKey_,
            address to_,
            uint256 value_,
            uint256 validAfter_,
            uint256 validBefore_,
            bytes32 fromNonce_
        ) = _getTransferParams();

        assertFalse(_token.authorizationState(from_, fromNonce_));

        (uint8 receiveV_, bytes32 receiveR_, bytes32 receiveS_) = _signPermit(
            fromPrivateKey_,
            _receiveAuthorizationDigest
        );

        (uint8 v_, bytes32 r_, bytes32 s_) = _signPermit(fromPrivateKey_, _cancelAuthorizationDigest);

        vm.expectEmit();
        emit IERC3009.AuthorizationCanceled(from_, fromNonce_);

        vm.prank(_alice);
        _token.cancelAuthorization(from_, fromNonce_, v_, r_, s_);

        assertTrue(_token.authorizationState(from_, fromNonce_));

        vm.expectRevert(abi.encodeWithSelector(IERC3009.AuthorizationAlreadyUsed.selector, _alice, fromNonce_));

        vm.prank(_bob);
        _token.receiveWithAuthorization(
            from_,
            to_,
            value_,
            validAfter_,
            validBefore_,
            fromNonce_,
            receiveV_,
            receiveR_,
            receiveS_
        );
    }

    function test_cancelAuthorization_authorizationAlreadyCanceled() external {
        (address from_, uint256 fromPrivateKey_, , , , , bytes32 fromNonce_) = _getTransferParams();

        assertFalse(_token.authorizationState(from_, fromNonce_));

        (uint8 v_, bytes32 r_, bytes32 s_) = _signPermit(fromPrivateKey_, _cancelAuthorizationDigest);

        _token.setAuthorizationState(_alice, fromNonce_, true);
        assertTrue(_token.authorizationState(_alice, fromNonce_));

        vm.expectRevert(abi.encodeWithSelector(IERC3009.AuthorizationAlreadyUsed.selector, _alice, fromNonce_));

        vm.prank(_alice);
        _token.cancelAuthorization(from_, fromNonce_, v_, r_, s_);
    }

    function _getTransferParams()
        internal
        view
        returns (
            address from_,
            uint256 fromPrivateKey_,
            address to_,
            uint256 value_,
            uint256 validAfter_,
            uint256 validBefore_,
            bytes32 fromNonce_
        )
    {
        from_ = _alice;
        fromPrivateKey_ = _aliceKey;
        to_ = _bob;
        value_ = 100e6;
        validAfter_ = 0;
        validBefore_ = type(uint256).max;

        // Should actually be a random bytes32 nonce but this is enough for our test case
        fromNonce_ = bytes32(_token.nonces(from_));
    }
}
