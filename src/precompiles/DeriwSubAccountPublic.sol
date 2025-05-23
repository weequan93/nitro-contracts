// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/OffchainLabs/nitro-contracts/blob/main/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.4.21 <0.9.0;

/// @title Provides user to grant permission to sub-account, allowed sub-account able to send transaction on their behave.
/// @notice Precompiled contract that exists in every Arbitrum chain at 0x00000000000000000000000000000000000007E9.
interface DeriwSubAccountPublic {
    /**
     * @notice bind relationship between parent-sub account
     * Sub-account submitted the signature of the parent, verify content and update the relationship
     * replace existing relationship if existed
     */
    function grantAccountControl(bytes calldata signData, bytes calldata signature) external;

    /**
     * @notice revoke relationship between parent and sub-account
     * Sub-account submitted the signature of the parent, verify content and update the relationship
     */
    function revokeAccountControl(bytes calldata signData, bytes calldata signature) external;

    /**
     * @notice Check which parent account is control by child address
     */
    function readAccountControl(address childAddress) external view returns (address);

    function readAccountGranted(address parentAddress) external view returns (address);

    /**
     * @notice Check either sub-account session is still valid
     */
//    function isValidAccountSession(address addr)
//        external
//        view
//    returns (
//            bool,
//            uint256,
//            int256    
//        );
}
