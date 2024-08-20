// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { IERC1271 } from "../../src/interfaces/IERC1271.sol";
import { SignatureChecker } from "../../src/libs/SignatureChecker.sol";

contract ERC1271WalletMock is IERC1271 {
    address public owner;

    constructor(address owner_) {
        owner = owner_;
    }

    function isValidSignature(bytes32 digest_, bytes memory signature_) public view returns (bytes4 magicValue_) {
        (, address signer_) = SignatureChecker.recoverECDSASigner(digest_, signature_);

        return signer_ == owner ? this.isValidSignature.selector : bytes4(0);
    }
}

contract ERC1271MaliciousWalletMock is IERC1271 {
    function isValidSignature(bytes32, bytes memory) public pure returns (bytes4) {
        assembly {
            mstore(0, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            return(0, 32)
        }
    }
}
