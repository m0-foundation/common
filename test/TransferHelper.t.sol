// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { Test } from "../lib/forge-std/src/Test.sol";

import { TransferHelper } from "../src/libs/TransferHelper.sol";
import { TypeConverter } from "../src/libs/TypeConverter.sol";
import { IERC20 } from "../src/interfaces/IERC20.sol";

import { TransferHelperHarness } from "./utils/TransferHelperHarness.sol";

abstract contract ERC20Base {
    string public constant name = "Test Token";
    string public constant symbol = "TTK";
    uint8 public constant decimals = 18;
    uint256 public totalSupply;
    mapping(address owner => uint256) public balanceOf;
    mapping(address owner => mapping(address spender => uint256)) public allowance;

    function mint(address to, uint256 amount) external {
        balanceOf[to] += amount;
        totalSupply += amount;
    }

    function _transfer(address from, address to, uint256 amount) internal {
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(spender != address(0), "approve to the zero address"); // add check to have failure case
        allowance[owner][spender] = amount;
    }

    function _spendAllowance(address owner, address spender, uint256 amount) internal {
        if (owner == spender) return;
        uint256 currentAllowance = allowance[owner][spender];
        require(currentAllowance >= amount, "ERC20: insufficient allowance");
        allowance[owner][spender] = currentAllowance - amount;
    }

    function _afterTransfer(address from, address to, uint256 amount) internal virtual {}
}

contract StandardERC20 is ERC20Base {
    function transfer(address to, uint256 amount) external returns (bool) {
        _transfer(msg.sender, to, amount);
        _afterTransfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        _spendAllowance(from, msg.sender, amount);
        _transfer(from, to, amount);
        _afterTransfer(from, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
}

contract NoReturnsERC20 is ERC20Base {
    function transfer(address to, uint256 amount) external {
        _transfer(msg.sender, to, amount);
        _afterTransfer(msg.sender, to, amount);
    }

    function transferFrom(address from, address to, uint256 amount) external {
        _spendAllowance(from, msg.sender, amount);
        _transfer(from, to, amount);
        _afterTransfer(from, to, amount);
    }

    function approve(address spender, uint256 amount) external {
        _approve(msg.sender, spender, amount);
    }
}

contract FeeOnTransferERC20 is StandardERC20 {
    uint256 public feeBps;

    function setFeeBps(uint256 bps) external {
        feeBps = bps;
    }

    function _feeAmount(uint256 amount) internal view returns (uint256) {
        if (feeBps == 0) {
            return 0;
        }
        return (amount * feeBps) / 10_000;
    }

    function _afterTransfer(address, address to, uint256 amount) internal override {
        uint256 feeAmount = _feeAmount(amount);
        if (feeAmount > 0) {
            balanceOf[to] -= feeAmount;
            // For simplicity, send fees to address(0)
            balanceOf[address(0)] += feeAmount;
        }
    }
}

contract TransferHelperTest is Test {
    using TypeConverter for *;
    using TransferHelper for IERC20;

    TransferHelperHarness public transferHelper;
    address public alice;
    address public bob;
    IERC20 public token;
    uint256 public constant INITIAL_BALANCE = 100e18;

    function setUp() public {
        transferHelper = new TransferHelperHarness();

        alice = (keccak256("alice") >> 96).toAddress();
        bob = (keccak256("bob") >> 96).toAddress();

        vm.deal(alice, 1 ether);
        vm.deal(bob, 1 ether);
    }

    modifier givenStandardToken() {
        StandardERC20 standardToken = new StandardERC20();
        standardToken.mint(address(transferHelper), INITIAL_BALANCE);
        standardToken.mint(alice, INITIAL_BALANCE);
        token = IERC20(address(standardToken));
        _;
    }

    modifier givenNoReturnsToken() {
        NoReturnsERC20 noReturnsToken = new NoReturnsERC20();
        noReturnsToken.mint(address(transferHelper), INITIAL_BALANCE);
        noReturnsToken.mint(alice, INITIAL_BALANCE);
        token = IERC20(address(noReturnsToken));
        _;
    }

    modifier givenFeeOnTransferToken(uint256 feeBps) {
        FeeOnTransferERC20 feeToken = new FeeOnTransferERC20();
        feeToken.mint(address(transferHelper), INITIAL_BALANCE);
        feeToken.mint(alice, INITIAL_BALANCE);
        feeToken.setFeeBps(feeBps);
        token = IERC20(address(feeToken));
        _;
    }

    // Test cases (by function)

    // safeTransfer
    // [X] given the token returns a boolean from the transfer call
    //   [X] given the transfer succeeds
    //     [X] it succeeds
    //   [X] given the transfer fails
    //     [X] it reverts with 'ST'
    // [X] given the token does not return a boolean from the transfer call
    //   [X] given the transfer succeeds
    //     [X] it succeeds
    //   [X] given the transfer fails
    //     [X] it reverts with 'ST'

    function testFuzz_safeTransfer_standardToken_success(uint256 amount) external givenStandardToken {
        amount = amount % (INITIAL_BALANCE + 1);

        transferHelper.safeTransfer(token, bob, amount);

        assertEq(token.balanceOf(bob), amount);
        assertEq(token.balanceOf(address(transferHelper)), INITIAL_BALANCE - amount);
    }

    function testFuzz_safeTransfer_standardToken_reverts(uint256 amount) external givenStandardToken {
        vm.assume(amount > INITIAL_BALANCE);

        vm.expectRevert(abi.encodePacked("ST"));
        transferHelper.safeTransfer(token, bob, amount);
    }

    function testFuzz_safeTransfer_noReturnsToken_success(uint256 amount) external givenNoReturnsToken {
        amount = amount % (INITIAL_BALANCE + 1);

        transferHelper.safeTransfer(token, bob, amount);

        assertEq(token.balanceOf(bob), amount);
        assertEq(token.balanceOf(address(transferHelper)), INITIAL_BALANCE - amount);
    }

    function testFuzz_safeTransfer_noReturnsToken_reverts(uint256 amount) external givenNoReturnsToken {
        vm.assume(amount > INITIAL_BALANCE);

        vm.expectRevert(abi.encodePacked("ST"));
        transferHelper.safeTransfer(token, bob, amount);
    }

    // safeTransferExact
    // [X] given the token does not charge a fee on transfer
    //   [X] it succeeds
    // [X] given the token charges a fee on transfer
    //   [X] it reverts with 'STE'

    function testFuzz_safeTransferExact_noFee_success(uint256 amount) external givenStandardToken {
        amount = amount % (INITIAL_BALANCE + 1);

        transferHelper.safeTransferExact(token, bob, amount);

        assertEq(token.balanceOf(bob), amount);
        assertEq(token.balanceOf(address(transferHelper)), INITIAL_BALANCE - amount);
    }

    function testFuzz_safeTransferExact_feeOnTransfer_reverts(uint256 amount) external givenFeeOnTransferToken(100) {
        amount = (amount % (INITIAL_BALANCE - 99)) + 100; // ensure amount >= 100

        vm.expectRevert(abi.encodePacked("STE"));
        transferHelper.safeTransferExact(token, bob, amount);
    }

    // safeTransferFrom
    // [X] given the token returns a boolean from the transferFrom call
    //   [X] given the transferFrom succeeds
    //     [X] it succeeds
    //   [X] given the transferFrom fails
    //     [X] it reverts with 'STF'
    // [X] given the token does not return a boolean from the transferFrom call
    //   [X] given the transferFrom succeeds
    //     [X] it succeeds
    //   [X] given the transferFrom fails
    //     [X] it reverts with 'STF'

    function testFuzz_safeTransferFrom_standardToken_success(uint256 amount) external givenStandardToken {
        amount = amount % (INITIAL_BALANCE + 1);

        vm.prank(alice);
        token.approve(address(transferHelper), type(uint256).max);

        transferHelper.safeTransferFrom(token, alice, bob, amount);

        assertEq(token.balanceOf(bob), amount);
        assertEq(token.balanceOf(alice), INITIAL_BALANCE - amount);
    }

    function testFuzz_safeTransferFrom_standardToken_reverts(uint256 amount) external givenStandardToken {
        vm.assume(amount > INITIAL_BALANCE);

        vm.prank(alice);
        token.approve(address(transferHelper), type(uint256).max);

        vm.expectRevert(abi.encodePacked("STF"));
        transferHelper.safeTransferFrom(token, alice, bob, amount);
    }

    function testFuzz_safeTransferFrom_noReturnsToken_success(uint256 amount) external givenNoReturnsToken {
        amount = amount % (INITIAL_BALANCE + 1);

        vm.prank(alice);
        token.safeApprove(address(transferHelper), type(uint256).max);

        transferHelper.safeTransferFrom(token, alice, bob, amount);

        assertEq(token.balanceOf(bob), amount);
        assertEq(token.balanceOf(alice), INITIAL_BALANCE - amount);
    }

    function testFuzz_safeTransferFrom_noReturnsToken_reverts(uint256 amount) external givenNoReturnsToken {
        vm.assume(amount > INITIAL_BALANCE);

        vm.prank(alice);
        token.safeApprove(address(transferHelper), type(uint256).max);

        vm.expectRevert(abi.encodePacked("STF"));
        transferHelper.safeTransferFrom(token, alice, bob, amount);
    }

    // safeTransferExactFrom
    // [X] given the token does not charge a fee on transfer
    //   [X] it succeeds
    // [X] given the token charges a fee on transfer
    //   [X] it reverts with 'STFE'

    function testFuzz_safeTransferExactFrom_noFee_success(uint256 amount) external givenStandardToken {
        amount = amount % (INITIAL_BALANCE + 1);

        vm.prank(alice);
        token.approve(address(transferHelper), type(uint256).max);

        transferHelper.safeTransferExactFrom(token, alice, bob, amount);

        assertEq(token.balanceOf(alice), INITIAL_BALANCE - amount);
        assertEq(token.balanceOf(bob), amount);
    }

    function testFuzz_safeTransferExactFrom_feeOnTransfer_reverts(uint256 amount) external givenFeeOnTransferToken(100) {
        amount = (amount % (INITIAL_BALANCE - 99)) + 100; // ensure amount >= 100

        vm.prank(alice);
        token.approve(address(transferHelper), type(uint256).max);

        vm.expectRevert(abi.encodePacked("STFE"));
        transferHelper.safeTransferExactFrom(token, alice, bob, amount);
    }


    // safeApprove
    // [X] given the token returns a boolean from the approve call
    //   [X] given the approve succeeds
    //     [X] it succeeds
    //   [X] given the approve fails
    //     [X] it reverts with 'SA' 
    // [X] given the token does not return a boolean from the approve call
    //   [X] given the approve succeeds
    //     [X] it succeeds
    //   [X] given the approve fails
    //     [X] it reverts with 'SA'

    function testFuzz_safeApprove_standardToken_success(address spender, uint256 amount) external givenStandardToken {
        vm.assume(spender != address(0));

        transferHelper.safeApprove(token, spender, amount);

        assertEq(token.allowance(address(transferHelper), spender), amount);
    }

    function testFuzz_safeApprove_standardToken_reverts(uint256 amount) external givenStandardToken {
        // Test token reverts when approving address(0)

        vm.expectRevert(abi.encodePacked("SA"));
        transferHelper.safeApprove(token, address(0), amount);
    }

    function testFuzz_safeApprove_noReturnsToken_success(address spender, uint256 amount) external givenNoReturnsToken {
        vm.assume(spender != address(0));

        transferHelper.safeApprove(token, spender, amount);

        assertEq(token.allowance(address(transferHelper), spender), amount);
    }

    function testFuzz_safeApprove_noReturnsToken_reverts(uint256 amount) external givenNoReturnsToken {
        // Test token reverts when approving address(0)

        vm.expectRevert(abi.encodePacked("SA"));
        transferHelper.safeApprove(token, address(0), amount);
    }

}
