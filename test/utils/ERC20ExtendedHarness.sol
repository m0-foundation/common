// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.20 <0.9.0;

import { ERC20Extended } from "../../src/ERC20Extended.sol";

contract ERC20ExtendedHarness is ERC20Extended {
    mapping(address => uint256) public balanceOf;

    uint256 public totalSupply;

    constructor(string memory name_, string memory symbol_, uint8 decimals_) ERC20Extended(name_, symbol_, decimals_) {}

    /* ============ Interactive Functions ============ */

    function mint(address recipient_, uint256 amount_) external {
        _transfer(address(0), recipient_, amount_);
    }

    function burn(address account_, uint256 amount_) external {
        _transfer(account_, address(0), amount_);
    }

    function setAuthorizationState(address authorizer_, bytes32 nonce_, bool isNonceUsed_) external {
        authorizationState[authorizer_][nonce_] = isNonceUsed_;
    }

    /* ============ View/Pure Functions ============ */

    function getDigest(bytes32 internalDigest_) external view returns (bytes32) {
        return _getDigest(internalDigest_);
    }

    function getPermitDigest(
        address owner_,
        address spender_,
        uint256 value_,
        uint256 nonce_,
        uint256 deadline_
    ) external view returns (bytes32) {
        return _getDigest(keccak256(abi.encode(PERMIT_TYPEHASH, owner_, spender_, value_, nonce_, deadline_)));
    }

    function getTransferWithAuthorizationDigest(
        address from_,
        address to_,
        uint256 value_,
        uint256 validAfter_,
        uint256 validBefore_,
        bytes32 nonce_
    ) external view returns (bytes32) {
        return _getTransferWithAuthorizationDigest(from_, to_, value_, validAfter_, validBefore_, nonce_);
    }

    function getReceiveWithAuthorizationDigest(
        address from_,
        address to_,
        uint256 value_,
        uint256 validAfter_,
        uint256 validBefore_,
        bytes32 nonce_
    ) external view returns (bytes32) {
        return _getReceiveWithAuthorizationDigest(from_, to_, value_, validAfter_, validBefore_, nonce_);
    }

    function getCancelAuthorizationDigest(address authorizer_, bytes32 nonce_) external view returns (bytes32) {
        return _getCancelAuthorizationDigest(authorizer_, nonce_);
    }

    /* ============ Internal Interactive Functions ============ */

    function _transfer(address sender_, address recipient_, uint256 amount_) internal override {
        if (sender_ != address(0)) {
            balanceOf[sender_] -= amount_;
        }

        if (recipient_ != address(0)) {
            balanceOf[recipient_] += amount_;
        }

        if (sender_ == address(0)) {
            totalSupply += amount_;
        }

        if (recipient_ == address(0)) {
            totalSupply -= amount_;
        }

        emit Transfer(sender_, recipient_, amount_);
    }
}
