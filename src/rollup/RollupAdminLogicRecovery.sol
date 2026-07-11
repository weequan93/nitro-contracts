// Copyright 2021-2022, Offchain Labs, Inc.
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "./RollupAdminLogic.sol";
import "./RollupLib.sol";

/// @notice Temporary admin logic for repairing a confirmed-node pointer rollback.
/// @dev This contract is intended to be used once via upgradeToAndCall, then replaced.
contract RollupAdminLogicRecovery is RollupAdminLogic {
    using NodeLib for Node;

    struct CheckpointFrame {
        uint64 expectedLatestConfirmed;
        uint64 expectedLatestNodeCreated;
        bytes32 blockHash;
        bytes32 sendRoot;
        uint64 batch;
    }

    // From this branch's storage layout:
    // _latestConfirmed, _firstUnresolvedNode, and _latestNodeCreated are packed
    // as uint64 values in slot 117 at byte offsets 0, 8, and 16.
    uint256 private constant NODE_POINTERS_SLOT = 117;

    event EmergencyRollbackConfirmed(
        uint64 oldLatestConfirmed,
        uint64 oldFirstUnresolved,
        uint64 oldLatestNodeCreated,
        uint64 newLatestConfirmed,
        uint64 newFirstUnresolved,
        uint64 newLatestNodeCreated
    );

    function emergencyRollbackConfirmed(
        uint64 expectedLatestConfirmed,
        uint64 expectedFirstUnresolved,
        uint64 expectedLatestNodeCreated,
        uint64 newLatestConfirmed,
        uint64 newFirstUnresolved,
        uint64 newLatestNodeCreated
    ) external whenPaused {
        require(latestConfirmed() == expectedLatestConfirmed, "BAD_LATEST_CONFIRMED");
        require(firstUnresolvedNode() == expectedFirstUnresolved, "BAD_FIRST_UNRESOLVED");
        require(latestNodeCreated() == expectedLatestNodeCreated, "BAD_LATEST_CREATED");

        require(newLatestConfirmed < expectedLatestConfirmed, "NOT_ROLLBACK");
        require(newFirstUnresolved == newLatestConfirmed + 1, "BAD_FIRST_AFTER_CONFIRMED");
        require(newLatestNodeCreated >= newFirstUnresolved, "LATEST_CREATED_TOO_LOW");
        require(newLatestNodeCreated <= expectedLatestNodeCreated, "LATEST_CREATED_TOO_HIGH");
        require(getNode(newLatestConfirmed).deadlineBlock != 0, "NO_CONFIRMED_NODE");
        require(getNode(newFirstUnresolved).deadlineBlock != 0, "NO_UNRESOLVED_NODE");

        uint256 slot = NODE_POINTERS_SLOT;
        uint256 word;
        assembly {
            word := sload(slot)
        }

        uint256 cleared = word & ~((uint256(1) << 192) - 1);
        uint256 updated = cleared | uint256(newLatestConfirmed) |
            (uint256(newFirstUnresolved) << 64) |
            (uint256(newLatestNodeCreated) << 128);

        assembly {
            sstore(slot, updated)
        }

        require(latestConfirmed() == newLatestConfirmed, "WRITE_LATEST_CONFIRMED");
        require(firstUnresolvedNode() == newFirstUnresolved, "WRITE_FIRST_UNRESOLVED");
        require(latestNodeCreated() == newLatestNodeCreated, "WRITE_LATEST_CREATED");

        emit EmergencyRollbackConfirmed(
            expectedLatestConfirmed,
            expectedFirstUnresolved,
            expectedLatestNodeCreated,
            newLatestConfirmed,
            newFirstUnresolved,
            newLatestNodeCreated
        );
    }

    function emergencyConfirmSequencerCheckpoint(
        uint64 expectedLatestConfirmed,
        uint64 expectedFirstUnresolved,
        uint64 expectedLatestNodeCreated,
        bytes32 blockHash,
        bytes32 sendRoot,
        uint64 batch,
        uint64 posInBatch
    ) external whenPaused returns (uint64 newNodeNum) {
        require(latestConfirmed() == expectedLatestConfirmed, "BAD_LATEST_CONFIRMED");
        require(firstUnresolvedNode() == expectedFirstUnresolved, "BAD_FIRST_UNRESOLVED");
        require(latestNodeCreated() == expectedLatestNodeCreated, "BAD_LATEST_CREATED");
        require(blockHash != bytes32(0), "BAD_BLOCK_HASH");
        require(sendRoot != bytes32(0), "BAD_SEND_ROOT");

        GlobalState memory checkpointGlobalState;
        checkpointGlobalState.bytes32Vals[0] = blockHash;
        checkpointGlobalState.bytes32Vals[1] = sendRoot;
        checkpointGlobalState.u64Vals[0] = batch;
        checkpointGlobalState.u64Vals[1] = posInBatch;

        ExecutionState memory checkpointState =
            ExecutionState(checkpointGlobalState, MachineStatus.FINISHED);

        return _createAndConfirmCheckpoint(
            CheckpointFrame({
                expectedLatestConfirmed: expectedLatestConfirmed,
                expectedLatestNodeCreated: expectedLatestNodeCreated,
                blockHash: blockHash,
                sendRoot: sendRoot,
                batch: batch
            }),
            checkpointState
        );
    }

    function _createAndConfirmCheckpoint(
        CheckpointFrame memory frame,
        ExecutionState memory checkpointState
    ) internal returns (uint64 newNodeNum) {
        Assertion memory assertion = Assertion(checkpointState, checkpointState, 0);

        uint256 inboxMaxCount = bridge.sequencerMessageCount();
        bytes32 executionHash = RollupLib.executionHash(assertion);
        bytes32 sequencerBatchAcc =
            frame.batch == 0 ? bytes32(0) : bridge.sequencerInboxAccs(frame.batch - 1);

        Node storage prevNode = getNodeStorage(frame.expectedLatestConfirmed);
        bytes32 lastHash = prevNode.nodeHash;
        bool hasSibling = prevNode.latestChildNumber > 0;
        if (hasSibling) {
            lastHash = getNode(prevNode.latestChildNumber).nodeHash;
        }

        bytes32 newNodeHash = RollupLib.nodeHash(
            hasSibling,
            lastHash,
            executionHash,
            sequencerBatchAcc,
            wasmModuleRoot
        );

        Node memory checkpointNode = NodeLib.createNode(
            RollupLib.stateHashMem(checkpointState, inboxMaxCount),
            RollupLib.challengeRootHash(executionHash, block.number, wasmModuleRoot),
            _confirmData(frame),
            frame.expectedLatestConfirmed,
            uint64(block.number),
            newNodeHash
        );

        newNodeNum = frame.expectedLatestNodeCreated + 1;
        prevNode.childCreated(newNodeNum);
        nodeCreated(checkpointNode);
        require(latestNodeCreated() == newNodeNum, "NODE_CREATE_FAILED");

        emit NodeCreated(
            newNodeNum,
            getNode(frame.expectedLatestConfirmed).nodeHash,
            newNodeHash,
            executionHash,
            assertion,
            sequencerBatchAcc,
            wasmModuleRoot,
            inboxMaxCount
        );

        confirmNode(newNodeNum, frame.blockHash, frame.sendRoot);
    }

    function _confirmData(CheckpointFrame memory frame) private pure returns (bytes32) {
        return RollupLib.confirmHash(frame.blockHash, frame.sendRoot);
    }
}
