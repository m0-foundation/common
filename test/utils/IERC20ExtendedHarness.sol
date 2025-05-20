// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.20 <0.9.0;

import { IERC20Extended } from "../../src/interfaces/IERC20Extended.sol";

interface IERC20ExtendedHarness is IERC20Extended {
    /* ============ Interactive Functions ============ */

    function mint(address recipient_, uint256 amount_) external;

    function burn(address account_, uint256 amount_) external;

    function setAuthorizationState(address authorizer_, bytes32 nonce_, bool isNonceUsed_) external;

    /* ============ View/Pure Functions ============ */

    function getDigest(bytes32 internalDigest_) external view returns (bytes32);

    function getPermitDigest(
        address owner_,
        address spender_,
        uint256 value_,
        uint256 nonce_,
        uint256 deadline_
    ) external view returns (bytes32);

    function getTransferWithAuthorizationDigest(
        address from_,
        address to_,
        uint256 value_,
        uint256 validAfter_,
        uint256 validBefore_,
        bytes32 nonce_
    ) external view returns (bytes32);

    function getReceiveWithAuthorizationDigest(
        address from_,
        address to_,
        uint256 value_,
        uint256 validAfter_,
        uint256 validBefore_,
        bytes32 nonce_
    ) external view returns (bytes32);

    function getCancelAuthorizationDigest(address authorizer_, bytes32 nonce_) external view returns (bytes32);
}
