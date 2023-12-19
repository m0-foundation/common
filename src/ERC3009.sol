// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.23;

import { IERC3009 } from "./interfaces/IERC3009.sol";

import { ERC20Permit } from "./ERC20Permit.sol";

abstract contract ERC3009 is IERC3009, ERC20Permit {
    // keccak256("TransferWithAuthorization(address from,address to,uint256 value,uint256 validAfter,uint256 validBefore,bytes32 nonce)")
    bytes32 public constant TRANSFER_WITH_AUTHORIZATION_TYPEHASH =
        0x7c7c6cdb67a18743f49ec6fa9b35f50d52ed05cbed4cc592e13b44501c1a2267;

    // keccak256("ReceiveWithAuthorization(address from,address to,uint256 value,uint256 validAfter,uint256 validBefore,bytes32 nonce)")
    bytes32 public constant RECEIVE_WITH_AUTHORIZATION_TYPEHASH =
        0xd099cc98ef71107a616c4f0f941f04c322d8e254fe26b3c6668db87aae413de8;

    // keccak256("CancelAuthorization(address authorizer,bytes32 nonce)")
    bytes32 public constant CANCEL_AUTHORIZATION_TYPEHASH =
        0x158b0a9edf7a828aad02f63cd515c68ef2f50ba807396f6d12842833a1597429;

    string internal constant _INVALID_SIGNATURE_ERROR = "EIP3009: invalid signature";

    /// @dev
    string internal constant _AUTHORIZATION_USED_ERROR = "EIP3009: authorization is used";

    /// @dev authorizer => nonce => state (true = used / false = unused)
    mapping(address authorizer => mapping(bytes32 nonce => bool isNonceUsed)) internal _authorizationStates;

    /**
     * @notice Construct the ERC3009 contract.
     * @param  name_     The name of the token.
     * @param  symbol_   The symbol of the token.
     * @param  decimals_ The number of decimals the token uses.
     */
    constructor(string memory name_, string memory symbol_, uint8 decimals_) ERC20Permit(name_, symbol_, decimals_) {}

    /// @inheritdoc IERC3009
    function authorizationState(address authorizer_, bytes32 nonce_) external view returns (bool) {
        return _authorizationStates[authorizer_][nonce_];
    }

    /// @inheritdoc IERC3009
    function transferWithAuthorization(
        address from_,
        address to_,
        uint256 value_,
        uint256 validAfter_,
        uint256 validBefore_,
        bytes32 nonce_,
        uint8 v_,
        bytes32 r_,
        bytes32 s_
    ) external {
        _transferWithAuthorization(
            TRANSFER_WITH_AUTHORIZATION_TYPEHASH,
            from_,
            to_,
            value_,
            validAfter_,
            validBefore_,
            nonce_,
            v_,
            r_,
            s_
        );
    }

    /// @inheritdoc IERC3009
    function receiveWithAuthorization(
        address from_,
        address to_,
        uint256 value_,
        uint256 validAfter_,
        uint256 validBefore_,
        bytes32 nonce_,
        uint8 v_,
        bytes32 r_,
        bytes32 s_
    ) external {
        if (msg.sender != to_) revert CallerMustBePayee(msg.sender, to_);

        _transferWithAuthorization(
            RECEIVE_WITH_AUTHORIZATION_TYPEHASH,
            from_,
            to_,
            value_,
            validAfter_,
            validBefore_,
            nonce_,
            v_,
            r_,
            s_
        );
    }

    /// @inheritdoc IERC3009
    function cancelAuthorization(address authorizer_, bytes32 nonce_, uint8 v_, bytes32 r_, bytes32 s_) external {
        if (_authorizationStates[authorizer_][nonce_]) revert AuthorizationAlreadyUsed(authorizer_, nonce_);

        _revertIfInvalidSignature(
            authorizer_,
            _getDigest(keccak256(abi.encode(CANCEL_AUTHORIZATION_TYPEHASH, authorizer_, nonce_))),
            v_,
            r_,
            s_
        );

        _authorizationStates[authorizer_][nonce_] = true;
        emit AuthorizationCanceled(authorizer_, nonce_);
    }

    /**
     * @notice Common transfer function used by `transferWithAuthorization` and `receiveWithAuthorization`.
     * @param  typeHash_    Typehash of the transfer authorization
     * @param  from_        Payer's address (Authorizer)
     * @param  to_          Payee's address
     * @param  value_       Amount to be transferred
     * @param  validAfter_  The time after which this is valid (unix time)
     * @param  validBefore_ The time before which this is valid (unix time)
     * @param  nonce_       Unique nonce
     * @param  v_           v of the signature
     * @param  r_           r of the signature
     * @param  s_           s of the signature
     */
    function _transferWithAuthorization(
        bytes32 typeHash_,
        address from_,
        address to_,
        uint256 value_,
        uint256 validAfter_,
        uint256 validBefore_,
        bytes32 nonce_,
        uint8 v_,
        bytes32 r_,
        bytes32 s_
    ) internal {
        if (block.timestamp < validAfter_) revert AuthorizationNotYetValid(block.timestamp, validAfter_);
        if (block.timestamp > validBefore_) revert AuthorizationExpired(block.timestamp, validBefore_);
        _revertIfAuthorizationAlreadyUsed(from_, nonce_);

        _revertIfInvalidSignature(
            from_,
            _getDigest(keccak256(abi.encode(typeHash_, from_, to_, value_, validAfter_, validBefore_, nonce_))),
            v_,
            r_,
            s_
        );

        _authorizationStates[from_][nonce_] = true;
        emit AuthorizationUsed(from_, nonce_);

        _transfer(from_, to_, value_);
    }

    /**
     * @notice Reverts if the authorization is already used.
     * @param  authorizer_ The authorizer's address
     * @param  nonce_      The nonce of the authorization
     */
    function _revertIfAuthorizationAlreadyUsed(address authorizer_, bytes32 nonce_) internal view {
        if (_authorizationStates[authorizer_][nonce_]) revert AuthorizationAlreadyUsed(authorizer_, nonce_);
    }
}
