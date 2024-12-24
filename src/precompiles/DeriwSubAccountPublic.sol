// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/OffchainLabs/nitro-contracts/blob/main/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.4.21 <0.9.0;

struct SignData {
    uint256 userId;
    address wallet;
}
// Primary type: HyperliquidTransaction:ApproveAgent
// HyperliquidChain
// parent nonce
// timestamp
// sub-address
/// @title Provides non-owners with info about the current chain owners.
/// @notice Precompiled contract that exists in every Arbitrum chain at 0x00000000000000000000000000000000000007E9.

interface DeriwSubAccountPublic {
    /**
     * @notice bind relationship between parent-sub account
     * Sub submitted the signature of the parent, verify content and update the relationship
     * replace existing relationship if existed
     */
    function GrantAccountControl(bytes memory signData, bytes memory signature)
        external;

    /**
     * @notice revoke relationship between parent-sub account
     * Sub submitted the signature of the parent, verify content and update the relationship
     */
    function RevokeAccountControl(bytes memory signData, bytes memory signature)
        external;

    /**
     * @notice read the parent account relation from relationship record
     */
    function ReadAccountControl(address addr) external  returns (address);
}
