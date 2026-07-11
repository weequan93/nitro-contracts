// Copyright 2021-2022, Offchain Labs, Inc.
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";

interface IRecoveryBridge {
    function sequencerMessageCount() external view returns (uint256);
    function sequencerInboxAccs(uint256) external view returns (bytes32);
}

interface IRecoveryOutbox {
    function updateSendRoot(bytes32 sendRoot, bytes32 l2BlockHash) external;
}

interface IRecoveryArbSys {
    function arbBlockNumber() external view returns (uint256);
}

/// @notice Minimal temporary admin logic for checkpointing a rollup to trusted sequencer state.
/// @dev Intended for one upgradeToAndCall use, then immediate upgrade back to the original admin logic.
contract RollupAdminLogicRecoveryMinimal is UUPSUpgradeable {
    struct GlobalState {
        bytes32[2] bytes32Vals;
        uint64[2] u64Vals;
    }

    struct ExecutionState {
        GlobalState globalState;
        uint8 machineStatus;
    }

    struct Assertion {
        ExecutionState beforeState;
        ExecutionState afterState;
        uint64 numBlocks;
    }

    struct CheckpointFrame {
        uint64 expectedLatestConfirmed;
        uint64 expectedFirstUnresolved;
        uint64 expectedLatestNodeCreated;
        bytes32 blockHash;
        bytes32 sendRoot;
        uint64 batch;
        uint64 posInBatch;
    }

    struct DerivedFrame {
        bytes32 wasmModuleRoot;
        uint256 inboxMaxCount;
        bytes32 sequencerBatchAcc;
        bytes32 globalStateHash;
        bytes32 executionHash;
        bytes32 parentNodeHash;
        bytes32 newNodeHash;
    }

    event NodeCreated(
        uint64 indexed nodeNum,
        bytes32 indexed parentNodeHash,
        bytes32 indexed nodeHash,
        bytes32 executionHash,
        Assertion assertion,
        bytes32 afterInboxBatchAcc,
        bytes32 wasmModuleRoot,
        uint256 inboxMaxCount
    );

    event NodeConfirmed(uint64 indexed nodeNum, bytes32 blockHash, bytes32 sendRoot);

    uint256 private constant PAUSED_SLOT = 51;
    uint256 private constant WASM_MODULE_ROOT_SLOT = 104;
    uint256 private constant BRIDGE_SLOT = 106;
    uint256 private constant OUTBOX_SLOT = 107;
    uint256 private constant NODE_POINTERS_SLOT = 117;
    uint256 private constant NODES_SLOT = 118;
    uint256 private constant NODE_CREATED_AT_ARBSYS_BLOCK_SLOT = 127;
    uint8 private constant MACHINE_STATUS_FINISHED = 1;

    function emergencyConfirmSequencerCheckpoint(
        uint64 expectedLatestConfirmed,
        uint64 expectedFirstUnresolved,
        uint64 expectedLatestNodeCreated,
        bytes32 blockHash,
        bytes32 sendRoot,
        uint64 batch,
        uint64 posInBatch
    ) external returns (uint64 newNodeNum) {
        CheckpointFrame memory frame = CheckpointFrame({
            expectedLatestConfirmed: expectedLatestConfirmed,
            expectedFirstUnresolved: expectedFirstUnresolved,
            expectedLatestNodeCreated: expectedLatestNodeCreated,
            blockHash: blockHash,
            sendRoot: sendRoot,
            batch: batch,
            posInBatch: posInBatch
        });
        return _emergencyConfirmSequencerCheckpoint(frame);
    }

    function _emergencyConfirmSequencerCheckpoint(CheckpointFrame memory frame)
        internal
        returns (uint64 newNodeNum)
    {
        require(_paused(), "NOT_PAUSED");
        require(frame.blockHash != bytes32(0), "BAD_BLOCK_HASH");
        require(frame.sendRoot != bytes32(0), "BAD_SEND_ROOT");

        (uint64 latestConfirmed, uint64 firstUnresolved, uint64 latestNodeCreated, uint64 lastStakeBlock) =
            _nodePointers();
        require(latestConfirmed == frame.expectedLatestConfirmed, "BAD_LATEST_CONFIRMED");
        require(firstUnresolved == frame.expectedFirstUnresolved, "BAD_FIRST_UNRESOLVED");
        require(latestNodeCreated == frame.expectedLatestNodeCreated, "BAD_LATEST_CREATED");

        newNodeNum = frame.expectedLatestNodeCreated + 1;

        GlobalState memory gs;
        gs.bytes32Vals[0] = frame.blockHash;
        gs.bytes32Vals[1] = frame.sendRoot;
        gs.u64Vals[0] = frame.batch;
        gs.u64Vals[1] = frame.posInBatch;

        Assertion memory assertion;
        assertion.beforeState = ExecutionState(gs, MACHINE_STATUS_FINISHED);
        assertion.afterState = ExecutionState(gs, MACHINE_STATUS_FINISHED);
        assertion.numBlocks = 0;

        DerivedFrame memory derived = _derive(frame);
        bytes32 prevNodeBase = _nodeBase(frame.expectedLatestConfirmed);

        _setPrevLatestChild(prevNodeBase, newNodeNum);
        _writeCheckpointNode(newNodeNum, frame, derived);
        _setNodeCreatedAtArbSysBlock(newNodeNum);
        _writeNodePointers(newNodeNum, newNodeNum + 1, newNodeNum, lastStakeBlock);

        emit NodeCreated(
            newNodeNum,
            derived.parentNodeHash,
            derived.newNodeHash,
            derived.executionHash,
            assertion,
            derived.sequencerBatchAcc,
            derived.wasmModuleRoot,
            derived.inboxMaxCount
        );

        IRecoveryOutbox(_addressAt(OUTBOX_SLOT)).updateSendRoot(frame.sendRoot, frame.blockHash);
        emit NodeConfirmed(newNodeNum, frame.blockHash, frame.sendRoot);
    }

    function _authorizeUpgrade(address) internal override {}

    function _paused() private view returns (bool paused_) {
        uint256 slot = PAUSED_SLOT;
        assembly {
            paused_ := and(sload(slot), 0xff)
        }
    }

    function _nodePointers()
        private
        view
        returns (uint64 latestConfirmed, uint64 firstUnresolved, uint64 latestNodeCreated, uint64 lastStakeBlock)
    {
        uint256 word = _uintAt(NODE_POINTERS_SLOT);
        latestConfirmed = uint64(word);
        firstUnresolved = uint64(word >> 64);
        latestNodeCreated = uint64(word >> 128);
        lastStakeBlock = uint64(word >> 192);
    }

    function _writeNodePointers(
        uint64 latestConfirmed,
        uint64 firstUnresolved,
        uint64 latestNodeCreated,
        uint64 lastStakeBlock
    ) private {
        uint256 word = uint256(latestConfirmed) | (uint256(firstUnresolved) << 64)
            | (uint256(latestNodeCreated) << 128) | (uint256(lastStakeBlock) << 192);
        uint256 slot = NODE_POINTERS_SLOT;
        assembly {
            sstore(slot, word)
        }
    }

    function _nodeBase(uint64 nodeNum) private pure returns (bytes32) {
        return keccak256(abi.encode(uint256(nodeNum), uint256(NODES_SLOT)));
    }

    function _derive(CheckpointFrame memory frame) private view returns (DerivedFrame memory d) {
        d.wasmModuleRoot = _bytes32At(WASM_MODULE_ROOT_SLOT);
        IRecoveryBridge bridge = IRecoveryBridge(_addressAt(BRIDGE_SLOT));
        d.inboxMaxCount = bridge.sequencerMessageCount();
        d.sequencerBatchAcc = frame.batch == 0 ? bytes32(0) : bridge.sequencerInboxAccs(frame.batch - 1);
        d.globalStateHash = _globalStateHash(frame.blockHash, frame.sendRoot, frame.batch, frame.posInBatch);

        bytes32 blockStateHash = keccak256(abi.encodePacked("Block state:", d.globalStateHash));
        d.executionHash = keccak256(abi.encodePacked(uint256(0), uint256(0), blockStateHash, blockStateHash));

        bytes32 prevNodeBase = _nodeBase(frame.expectedLatestConfirmed);
        d.parentNodeHash = _bytes32At(uint256(prevNodeBase) + 5);
        uint64 latestChild = _latestChildNumber(prevNodeBase);
        bool hasSibling = latestChild > 0;
        bytes32 lastHash = hasSibling ? _bytes32At(uint256(_nodeBase(latestChild)) + 5) : d.parentNodeHash;
        d.newNodeHash = keccak256(
            abi.encodePacked(uint8(hasSibling ? 1 : 0), lastHash, d.executionHash, d.sequencerBatchAcc, d.wasmModuleRoot)
        );
    }

    function _writeCheckpointNode(uint64 newNodeNum, CheckpointFrame memory frame, DerivedFrame memory d) private {
        bytes32 stateHash = keccak256(abi.encodePacked(d.globalStateHash, d.inboxMaxCount, MACHINE_STATUS_FINISHED));
        bytes32 challengeHash = keccak256(abi.encodePacked(d.executionHash, block.number, d.wasmModuleRoot));
        bytes32 confirmData = keccak256(abi.encodePacked(frame.blockHash, frame.sendRoot));
        _writeNode(newNodeNum, stateHash, challengeHash, confirmData, frame.expectedLatestConfirmed, d.newNodeHash);
    }

    function _writeNode(
        uint64 nodeNum,
        bytes32 stateHash,
        bytes32 challengeHash,
        bytes32 confirmData,
        uint64 prevNum,
        bytes32 nodeHash
    ) private {
        uint256 base = uint256(_nodeBase(nodeNum));
        uint256 blockNum = block.number;
        assembly {
            sstore(base, stateHash)
            sstore(add(base, 1), challengeHash)
            sstore(add(base, 2), confirmData)
            sstore(add(base, 3), or(or(prevNum, shl(64, blockNum)), shl(128, blockNum)))
            sstore(add(base, 4), shl(192, blockNum))
            sstore(add(base, 5), nodeHash)
        }
    }

    function _setPrevLatestChild(bytes32 prevNodeBase, uint64 newNodeNum) private {
        uint256 slot = uint256(prevNodeBase) + 4;
        uint256 word = _uintAt(slot);
        uint64 firstChildBlock = uint64(word >> 64);
        if (firstChildBlock == 0) {
            firstChildBlock = uint64(block.number);
        }
        uint256 keepChildStakerCount = word & ((uint256(1) << 64) - 1);
        uint256 keepCreatedAtBlock = word & ~((uint256(1) << 192) - 1);
        uint256 updated =
            keepChildStakerCount | (uint256(firstChildBlock) << 64) | (uint256(newNodeNum) << 128) | keepCreatedAtBlock;
        assembly {
            sstore(slot, updated)
        }
    }

    function _setNodeCreatedAtArbSysBlock(uint64 nodeNum) private {
        try IRecoveryArbSys(address(100)).arbBlockNumber() returns (uint256 arbBlockNumber) {
            bytes32 slot = keccak256(abi.encode(uint256(nodeNum), uint256(NODE_CREATED_AT_ARBSYS_BLOCK_SLOT)));
            assembly {
                sstore(slot, arbBlockNumber)
            }
        } catch {}
    }

    function _latestChildNumber(bytes32 nodeBase) private view returns (uint64) {
        return uint64(_uintAt(uint256(nodeBase) + 4) >> 128);
    }

    function _globalStateHash(bytes32 blockHash, bytes32 sendRoot, uint64 batch, uint64 posInBatch)
        private
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked("Global state:", blockHash, sendRoot, batch, posInBatch));
    }

    function _addressAt(uint256 slot) private view returns (address value) {
        uint256 word = _uintAt(slot);
        value = address(uint160(word));
    }

    function _bytes32At(uint256 slot) private view returns (bytes32 value) {
        assembly {
            value := sload(slot)
        }
    }

    function _uintAt(uint256 slot) private view returns (uint256 value) {
        assembly {
            value := sload(slot)
        }
    }
}
