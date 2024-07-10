// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.20 <0.9.0;

import { IERC20 } from "../src/interfaces/IERC20.sol";
import { IERC20Extended } from "../src/interfaces/IERC20Extended.sol";
import { IERC712 } from "../src/interfaces/IERC712.sol";

import { ERC20ExtendedHarness } from "./utils/ERC20ExtendedHarness.sol";
import { TestUtils } from "./utils/TestUtils.t.sol";

contract ERC20ExtendedTests is TestUtils {
    string internal constant _TOKEN_NAME = "ERC20Extended Token";
    string internal constant _TOKEN_SYMBOL = "ERC20E_TKN";
    uint8 internal constant _TOKEN_DECIMALS = 18;

    address internal _alice;
    uint256 internal _aliceKey;

    address internal _bob;
    uint256 internal _bobKey;

    ERC20ExtendedHarness internal _token;

    function setUp() external {
        (_alice, _aliceKey) = makeAddrAndKey("alice");
        (_bob, _bobKey) = makeAddrAndKey("bob");

        _token = new ERC20ExtendedHarness(_TOKEN_NAME, _TOKEN_SYMBOL, _TOKEN_DECIMALS);
    }

    /* ============ constructor ============ */
    function test_constructor() external view {
        assertEq(_token.name(), _TOKEN_NAME);
        assertEq(_token.symbol(), _TOKEN_SYMBOL);
        assertEq(_token.decimals(), _TOKEN_DECIMALS);
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
        ) = _token.eip712Domain();

        assertEq(fields_, hex"0f");
        assertEq(name_, _TOKEN_NAME);
        assertEq(version_, "1");
        assertEq(chainId_, block.chainid);
        assertEq(verifyingContract_, address(_token));
        assertEq(salt_, bytes32(0));
        assertEq(extensions_, new uint256[](0));
    }

    /* ============ mint ============ */
    function test_mint() external {
        uint256 amount_ = 1e18;

        vm.expectEmit();
        emit IERC20.Transfer(address(0), _alice, amount_);

        _token.mint(_alice, amount_);

        assertEq(_token.totalSupply(), amount_);
        assertEq(_token.balanceOf(_alice), amount_);
    }

    function testFuzz_mint(address from_, uint256 amount_) external {
        vm.assume(from_ != address(0));

        amount_ = bound(amount_, 1, type(uint256).max);

        _token.mint(from_, amount_);

        assertEq(_token.totalSupply(), amount_);
        assertEq(_token.balanceOf(from_), amount_);
    }

    /* ============ burn ============ */
    function test_burn() external {
        uint256 mintAmount_ = 1e18;
        uint256 burnAmount_ = 0.9e18;

        _token.mint(_alice, mintAmount_);

        vm.expectEmit();
        emit IERC20.Transfer(_alice, address(0), burnAmount_);

        _token.burn(_alice, burnAmount_);

        assertEq(_token.totalSupply(), mintAmount_ - burnAmount_);
        assertEq(_token.balanceOf(_alice), mintAmount_ - burnAmount_);
    }

    function testFuzz_burn(address from_, uint256 mintAmount_, uint256 burnAmount_) external {
        vm.assume(from_ != address(0));
        vm.assume(mintAmount_ != 0);

        burnAmount_ = bound(burnAmount_, 0, mintAmount_);

        _token.mint(from_, mintAmount_);
        _token.burn(from_, burnAmount_);

        assertEq(_token.totalSupply(), mintAmount_ - burnAmount_);
        assertEq(_token.balanceOf(from_), mintAmount_ - burnAmount_);
    }

    function testFuzz_burn_insufficientBalance(address from_, uint256 mintAmount_, uint256 burnAmount_) external {
        vm.assume(from_ != address(0));
        vm.assume(mintAmount_ != 0);
        vm.assume(mintAmount_ != type(uint256).max);

        burnAmount_ = bound(burnAmount_, mintAmount_ + 1, type(uint256).max);

        _token.mint(from_, mintAmount_);

        vm.expectRevert();
        _token.burn(from_, burnAmount_);
    }

    /* ============ approve ============ */
    function test_approve() external {
        uint256 amount_ = 1e18;

        vm.expectEmit();
        emit IERC20.Approval(address(this), _alice, amount_);

        assertTrue(_token.approve(_alice, amount_));

        assertEq(_token.allowance(address(this), _alice), amount_);
    }

    function testFuzz_approve(address to_, uint256 amount_) external {
        assertTrue(_token.approve(to_, amount_));

        assertEq(_token.allowance(address(this), to_), amount_);
    }

    /* ============ transfer ============ */
    function test_transfer() external {
        uint256 amount_ = 1e18;

        _token.mint(address(this), amount_);

        vm.expectEmit();
        emit IERC20.Transfer(address(this), _alice, amount_);

        assertTrue(_token.transfer(_alice, amount_));
        assertEq(_token.totalSupply(), amount_);

        assertEq(_token.balanceOf(address(this)), 0);
        assertEq(_token.balanceOf(_alice), amount_);
    }

    function testFuzz_transfer(address from_, uint256 amount_) external {
        vm.assume(from_ != address(0));
        vm.assume(amount_ != 0);

        _token.mint(address(this), amount_);

        assertTrue(_token.transfer(from_, amount_));
        assertEq(_token.totalSupply(), amount_);

        if (address(this) == from_) {
            assertEq(_token.balanceOf(address(this)), amount_);
        } else {
            assertEq(_token.balanceOf(address(this)), 0);
            assertEq(_token.balanceOf(from_), amount_);
        }
    }

    function test_transfer_insufficientBalance() external {
        _token.mint(address(this), 0.9e18);

        vm.expectRevert();
        _token.transfer(_alice, 1e18);
    }

    function testFuzz_transfer_insufficientBalance(address to_, uint256 mintAmount_, uint256 sendAmount_) external {
        vm.assume(mintAmount_ != type(uint256).max);

        sendAmount_ = bound(sendAmount_, mintAmount_ + 1, type(uint256).max);

        _token.mint(address(this), mintAmount_);

        vm.expectRevert();
        _token.transfer(to_, sendAmount_);
    }

    /* ============ transferFrom ============ */
    function test_transferFrom() external {
        uint256 amount_ = 1e18;

        _token.mint(_alice, amount_);

        vm.prank(_alice);
        _token.approve(address(this), amount_);

        assertTrue(_token.transferFrom(_alice, _bob, amount_));
        assertEq(_token.totalSupply(), amount_);

        assertEq(_token.allowance(_alice, address(this)), 0);

        assertEq(_token.balanceOf(_alice), 0);
        assertEq(_token.balanceOf(_bob), amount_);
    }

    function testFuzz_transferFrom(address to_, uint256 approval_, uint256 amount_) external {
        vm.assume(to_ != address(0));

        amount_ = bound(amount_, 0, approval_);

        _token.mint(_alice, amount_);

        vm.prank(_alice);
        _token.approve(address(this), approval_);

        assertTrue(_token.transferFrom(_alice, to_, amount_));
        assertEq(_token.totalSupply(), amount_);

        assertEq(
            _token.allowance(_alice, address(this)),
            _alice == address(this) || approval_ == type(uint256).max ? approval_ : approval_ - amount_
        );

        if (_alice == to_) {
            assertEq(_token.balanceOf(_alice), amount_);
        } else {
            assertEq(_token.balanceOf(_alice), 0);
            assertEq(_token.balanceOf(to_), amount_);
        }
    }

    function test_transferFrom_infiniteApprove() external {
        uint256 amount_ = 1e18;

        _token.mint(_alice, amount_);

        vm.prank(_alice);
        _token.approve(address(this), type(uint256).max);

        assertTrue(_token.transferFrom(_alice, _bob, amount_));
        assertEq(_token.totalSupply(), amount_);

        assertEq(_token.allowance(_alice, address(this)), type(uint256).max);

        assertEq(_token.balanceOf(_alice), 0);
        assertEq(_token.balanceOf(_bob), amount_);
    }

    function test_transferFrom_insufficientAllowance() external {
        uint256 amount_ = 1e18;

        _token.mint(_alice, amount_);

        vm.prank(_alice);
        _token.approve(_bob, 0.9e18);

        vm.prank(_bob);

        vm.expectRevert(abi.encodeWithSelector(IERC20Extended.InsufficientAllowance.selector, _bob, 0.9e18, amount_));
        _token.transferFrom(_alice, _bob, amount_);
    }

    function testFuzz_transferFrom_insufficientAllowance(address to_, uint256 approval_, uint256 amount_) external {
        vm.assume(approval_ != type(uint256).max);

        amount_ = bound(amount_, approval_ + 1, type(uint256).max);

        _token.mint(_alice, amount_);

        vm.prank(_alice);
        _token.approve(address(this), approval_);

        vm.expectRevert(
            abi.encodeWithSelector(IERC20Extended.InsufficientAllowance.selector, address(this), approval_, amount_)
        );
        _token.transferFrom(_alice, to_, amount_);
    }

    function test_transferFrom_insufficientBalance() external {
        uint256 amount_ = 1e18;

        _token.mint(_alice, 0.9e18);

        vm.prank(_alice);
        _token.approve(address(this), amount_);

        vm.expectRevert();
        _token.transferFrom(_alice, _bob, amount_);
    }

    function testFuzz_transferFrom_insufficientBalance(address to_, uint256 mintAmount_, uint256 sendAmount_) external {
        vm.assume(mintAmount_ != type(uint256).max);

        sendAmount_ = bound(sendAmount_, mintAmount_ + 1, type(uint256).max);

        _token.mint(_alice, mintAmount_);

        vm.prank(_alice);
        _token.approve(address(this), sendAmount_);

        vm.expectRevert();
        _token.transferFrom(_alice, to_, sendAmount_);
    }

    /* ============ permit ============ */
    function test_permit() external {
        uint256 amount_ = 1e18;

        (uint8 v_, bytes32 r_, bytes32 s_) = vm.sign(
            _aliceKey,
            _token.getPermitDigest(_alice, _bob, amount_, 0, block.timestamp)
        );

        vm.expectEmit();
        emit IERC20.Approval(_alice, _bob, amount_);

        _token.permit(_alice, _bob, amount_, block.timestamp, v_, r_, s_);

        assertEq(_token.allowance(_alice, _bob), amount_);
        assertEq(_token.nonces(_alice), 1);
    }

    function testFuzz_permit(uint248 key_, address to_, uint256 amount_, uint256 deadline_) external {
        uint256 privateKey_ = key_;

        if (deadline_ < block.timestamp) deadline_ = block.timestamp;
        if (privateKey_ == 0) privateKey_ = 1;

        // private key must be less than the secp256k1 curve order
        vm.assume(privateKey_ < 115792089237316195423570985008687907852837564279074904382605163141518161494337);

        address owner_ = vm.addr(privateKey_);

        (uint8 v_, bytes32 r_, bytes32 s_) = vm.sign(
            privateKey_,
            _token.getPermitDigest(owner_, to_, amount_, 0, deadline_)
        );

        _token.permit(owner_, to_, amount_, deadline_, v_, r_, s_);

        assertEq(_token.allowance(owner_, to_), amount_);
        assertEq(_token.nonces(owner_), 1);
    }

    function test_permit_badNonce() external {
        uint256 amount_ = 1e18;

        (uint8 v_, bytes32 r_, bytes32 s_) = vm.sign(
            _aliceKey,
            _token.getPermitDigest(_alice, _bob, amount_, 1, block.timestamp)
        );

        vm.expectRevert(IERC712.SignerMismatch.selector);
        _token.permit(_alice, _bob, amount_, block.timestamp, v_, r_, s_);
    }

    function testFuzz_permit_badNonce(
        uint256 privateKey_,
        address to_,
        uint256 amount_,
        uint256 deadline_,
        uint256 nonce_
    ) external {
        if (deadline_ < block.timestamp) deadline_ = block.timestamp;
        if (privateKey_ == 0) privateKey_ = 1;
        if (nonce_ == 0) nonce_ = 1;

        // private key must be less than the secp256k1 curve order
        vm.assume(privateKey_ < 115792089237316195423570985008687907852837564279074904382605163141518161494337);

        address owner_ = vm.addr(privateKey_);

        (uint8 v_, bytes32 r_, bytes32 s_) = vm.sign(
            privateKey_,
            _token.getPermitDigest(owner_, to_, amount_, nonce_, deadline_)
        );

        vm.expectRevert(IERC712.SignerMismatch.selector);
        _token.permit(owner_, to_, amount_, deadline_, v_, r_, s_);
    }

    function test_permit_badDeadline() external {
        uint256 amount_ = 1e18;

        (uint8 v_, bytes32 r_, bytes32 s_) = vm.sign(
            _aliceKey,
            _token.getPermitDigest(_alice, _bob, amount_, 0, block.timestamp)
        );

        vm.expectRevert(IERC712.SignerMismatch.selector);
        _token.permit(_alice, _bob, amount_, block.timestamp + 1, v_, r_, s_);
    }

    function testFuzz_permit_badDeadline(
        uint256 privateKey_,
        address to_,
        uint256 amount_,
        uint256 deadline_
    ) external {
        if (deadline_ < block.timestamp) deadline_ = block.timestamp;
        if (privateKey_ == 0) privateKey_ = 1;

        vm.assume(deadline_ != type(uint256).max);

        // private key must be less than the secp256k1 curve order
        vm.assume(privateKey_ < 115792089237316195423570985008687907852837564279074904382605163141518161494337);

        address owner_ = vm.addr(privateKey_);

        (uint8 v_, bytes32 r_, bytes32 s_) = vm.sign(
            privateKey_,
            _token.getPermitDigest(owner_, to_, amount_, 0, deadline_)
        );

        vm.expectRevert(IERC712.SignerMismatch.selector);
        _token.permit(owner_, to_, amount_, deadline_ + 1, v_, r_, s_);
    }

    function test_permit_pastDeadline() external {
        uint256 amount_ = 1e18;
        uint256 oldTimestamp_ = block.timestamp;
        uint256 newTimestamp_ = oldTimestamp_ + 1;

        (uint8 v_, bytes32 r_, bytes32 s_) = vm.sign(
            _aliceKey,
            _token.getPermitDigest(_alice, _bob, amount_, 0, oldTimestamp_)
        );

        vm.warp(newTimestamp_);

        vm.expectRevert(abi.encodeWithSelector(IERC712.SignatureExpired.selector, oldTimestamp_, newTimestamp_));
        _token.permit(_alice, _bob, amount_, oldTimestamp_, v_, r_, s_);
    }

    function testFuzz_permit_pastDeadline(
        uint256 privateKey_,
        address to_,
        uint256 amount_,
        uint256 deadline_
    ) external {
        deadline_ = bound(deadline_, 0, block.timestamp - 1);
        if (privateKey_ == 0) privateKey_ = 1;

        // private key must be less than the secp256k1 curve order
        vm.assume(privateKey_ < 115792089237316195423570985008687907852837564279074904382605163141518161494337);

        address owner_ = vm.addr(privateKey_);

        (uint8 v_, bytes32 r_, bytes32 s_) = vm.sign(
            privateKey_,
            _token.getPermitDigest(owner_, to_, amount_, 0, deadline_)
        );

        vm.expectRevert(abi.encodeWithSelector(IERC712.SignatureExpired.selector, deadline_, block.timestamp));
        _token.permit(owner_, to_, amount_, deadline_, v_, r_, s_);
    }

    function test_permit_replay() external {
        uint256 amount_ = 1e18;

        (uint8 v_, bytes32 r_, bytes32 s_) = vm.sign(
            _aliceKey,
            _token.getPermitDigest(_alice, _bob, amount_, 0, block.timestamp)
        );

        _token.permit(_alice, _bob, amount_, block.timestamp, v_, r_, s_);

        vm.expectRevert(IERC712.SignerMismatch.selector);
        _token.permit(_alice, _bob, amount_, block.timestamp, v_, r_, s_);
    }

    function testFuzz_permit_replay(uint256 privateKey_, address to_, uint256 amount_, uint256 deadline_) external {
        if (deadline_ < block.timestamp) deadline_ = block.timestamp;
        if (privateKey_ == 0) privateKey_ = 1;

        // private key must be less than the secp256k1 curve order
        vm.assume(privateKey_ < 115792089237316195423570985008687907852837564279074904382605163141518161494337);

        address owner_ = vm.addr(privateKey_);

        (uint8 v_, bytes32 r_, bytes32 s_) = vm.sign(
            privateKey_,
            _token.getPermitDigest(owner_, to_, amount_, 0, deadline_)
        );

        _token.permit(owner_, to_, amount_, deadline_, v_, r_, s_);

        vm.expectRevert(IERC712.SignerMismatch.selector);
        _token.permit(owner_, to_, amount_, deadline_, v_, r_, s_);
    }
}
