// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.20 <0.9.0;

import { TimelockBatchBase } from "./TimelockBatchBase.sol";

import { Safe } from "../lib/safe-utils/src/Safe.sol";
import {
    TimelockController
} from "../lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/governance/TimelockController.sol";

abstract contract SafeTimelockBatchBase is TimelockBatchBase {
    using Safe for *;

    Safe.Client internal _safeMultiSig;

    /// @notice Thrown in case a transaction that's supposed to be cancelled is not pending.
    /// @param id_ The identifier of the transaction.
    error OperationNotPending(bytes32 id_);

    /// @notice Proposes to schedule a batch of transactions to a timelock contract.
    /// @param safe_ The address of the Safe multisig to propose to.
    /// @param timelock_ The address of the timelock.
    /// @param sender_ The sender's address.
    /// @param predecessor_ The predecessor transaction, if any.
    /// @param salt_ The salt to build the transaction with, if any.
    function _proposeScheduleBatch(
        address safe_,
        address timelock_,
        address sender_,
        bytes32 predecessor_,
        bytes32 salt_
    ) internal {
        uint256 delay = TimelockController(payable(timelock_)).getMinDelay();
        bytes memory batchData = _getScheduleBatchCallData(predecessor_, salt_, delay);

        _safeMultiSig.initialize(safe_);
        _safeMultiSig.proposeTransaction(timelock_, batchData, sender_);
    }

    /// @notice Proposes to cancel the execution of a pending message that was originally scheduled through a timelock.
    /// @param safe_ The address of the Safe multisig to propose the transaction to.
    /// @param timelock_ The address of the timelock.
    /// @param sender_ The sender's address.
    /// @param id_ The id of the scheduled transaction to cancel.
    function _proposeCancel(address safe_, address timelock_, address sender_, bytes32 id_) internal {
        TimelockController timelock = TimelockController(payable(timelock_));
        if (!timelock.isOperationPending(id_)) {
            revert OperationNotPending(id_);
        }

        _safeMultiSig.initialize(safe_);
        _safeMultiSig.proposeTransaction(timelock_, abi.encodeCall(TimelockController.cancel, id_), sender_);
    }
}
