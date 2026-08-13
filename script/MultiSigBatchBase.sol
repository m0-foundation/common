// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.20 <0.9.0;

import { Enum } from "safe-smart-account/common/Enum.sol";
import { OwnerManager } from "safe-smart-account/base/OwnerManager.sol";
import { Safe } from "safe-utils/Safe.sol";

import { console } from "forge-std/console.sol";
import { Script } from "forge-std/Script.sol";

abstract contract MultiSigBatchBase is Script {
    using Safe for *;

    Safe.Client internal _safeMultiSig;
    address[] internal _targets;
    bytes[] internal _data;

    function _addToBatch(address target_, bytes memory data_) internal {
        _targets.push(target_);
        _data.push(data_);
    }

    /// @dev Proposes the batch at the Safe's current on-chain nonce.
    function _proposeBatch(address safe_, address sender_) internal {
        _safeMultiSig.initialize(safe_);
        _propose(sender_, _safeMultiSig.getNonce());
    }

    /// @dev Proposes the batch at an explicit nonce. The Safe's on-chain nonce only advances on execution, so
    ///      proposing at it can collide with already queued proposals instead of queueing behind them.
    function _proposeBatch(address safe_, address sender_, uint256 nonce_) internal {
        _safeMultiSig.initialize(safe_);
        _propose(sender_, nonce_);
    }

    /// @dev Simulates the batch through the Safe itself, using synthetic owner approvals, so that the MultiSend
    ///      encoding, the threshold check and any guard or fallback handler are exercised too.
    function _simulateBatch(address safe_) internal {
        _safeMultiSig.initialize(safe_);

        address[] memory owners_ = OwnerManager(safe_).getOwners();

        // NOTE: `isolate` mode runs each top-level call as its own transaction, requiring the signer to pay for gas.
        for (uint256 i = 0; i < owners_.length; i++) {
            vm.deal(owners_[i], owners_[i].balance + 1 ether);
        }

        require(_safeMultiSig.simulateTransactionsMultiSigNoSign(_targets, _data, owners_), "Simulation failed");
    }

    function _propose(address sender_, uint256 nonce_) private {
        console.log("Safe nonce:", nonce_);

        (address to_, bytes memory data_) = _safeMultiSig.getProposeTransactionsTargetAndData(_targets, _data);

        // NOTE: Batches are executed via DelegateCall to preserve `msg.sender` across the sub-calls, and the signed
        //       operation must match the proposed one.
        bytes memory signature_ = _safeMultiSig.sign(to_, data_, Enum.Operation.DelegateCall, sender_, nonce_, "");

        _safeMultiSig.proposeTransactionsWithSignature(_targets, _data, sender_, signature_, nonce_);
    }
}
