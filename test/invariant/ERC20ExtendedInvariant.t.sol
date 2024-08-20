// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { CommonBase } from "../../lib/forge-std/src/Base.sol";
import { StdCheats } from "../../lib/forge-std/src/StdCheats.sol";
import { StdUtils } from "../../lib/forge-std/src/StdUtils.sol";

import { ERC20ExtendedHarness } from "../utils/ERC20ExtendedHarness.sol";
import { TestUtils } from "../utils/TestUtils.t.sol";

contract ERC20ExtendedHandler is CommonBase, StdCheats, StdUtils {
    ERC20ExtendedHarness internal _token;
    uint256 public sum;

    constructor(ERC20ExtendedHarness token_) {
        _token = token_;
    }

    function mint(address to_, uint256 amount_) public {
        if (to_ == address(0)) return;

        amount_ = bound(amount_, 0, type(uint256).max - sum);

        _token.mint(to_, amount_);
        sum += amount_;
    }

    function burn(address from_, uint256 amount_) public {
        amount_ = bound(amount_, 0, _token.balanceOf(from_));

        _token.burn(from_, amount_);
        sum -= amount_;
    }

    function approve(address to_, uint256 amount_) public {
        _token.approve(to_, amount_);
    }

    function transferFrom(address from_, address to_, uint256 amount_) public {
        if (from_ == address(0) || to_ == address(0)) return;

        amount_ = bound(amount_, 0, _token.balanceOf(from_));

        amount_ = amount_ > type(uint256).max - _token.balanceOf(to_)
            ? type(uint256).max - _token.balanceOf(to_)
            : amount_;

        if (_token.allowance(from_, address(this)) < amount_) {
            vm.prank(from_);
            _token.approve(address(this), type(uint256).max);
        }

        _token.transferFrom(from_, to_, amount_);
    }

    function transfer(address to_, uint256 amount_) public {
        if (msg.sender == address(0) || to_ == address(0)) return;

        amount_ = bound(amount_, 0, _token.balanceOf(msg.sender));

        amount_ = amount_ > type(uint256).max - _token.balanceOf(to_)
            ? type(uint256).max - _token.balanceOf(to_)
            : amount_;

        if (_token.allowance(msg.sender, address(this)) < amount_) {
            vm.prank(msg.sender);
            _token.approve(address(this), type(uint256).max);
        }

        vm.prank(msg.sender);
        _token.transfer(to_, amount_);
    }
}

contract ERC20ExtendedInvariantTests is TestUtils {
    ERC20ExtendedHarness internal _token;
    ERC20ExtendedHandler internal _handler;

    function setUp() public {
        _token = new ERC20ExtendedHarness("ERC20Extended Token", "ERC20E_TKN", 18);
        _handler = new ERC20ExtendedHandler(_token);

        targetContract(address(_handler));

        bytes4[] memory selectors = new bytes4[](5);
        selectors[0] = ERC20ExtendedHandler.mint.selector;
        selectors[1] = ERC20ExtendedHandler.burn.selector;
        selectors[2] = ERC20ExtendedHandler.approve.selector;
        selectors[3] = ERC20ExtendedHandler.transferFrom.selector;
        selectors[4] = ERC20ExtendedHandler.transfer.selector;

        targetSelector(FuzzSelector({ addr: address(_handler), selectors: selectors }));
    }

    function invariant_main() public {
        assertEq(_token.totalSupply(), _handler.sum());
    }
}
