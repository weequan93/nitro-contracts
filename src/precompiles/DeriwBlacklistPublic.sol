// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/OffchainLabs/nitro-contracts/blob/main/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.4.21 <0.9.0;

/// @title Provides non-owners with info about the blacklist configuration.
/// @notice Precompiled contract that exists in deriw chain at 0x00000000000000000000000000000000000007EB.
interface DeriwBlacklistPublic {
    /// @notice See if the user is a blacklist owner
    function isBlacklistOwner(address addr) external view returns (bool);

    /**
     * @notice Rectify the list of blacklist owners
     * If successful, emits BlacklistOwnerRectified event
     * Available in ArbOS version 11
     */
    function rectifyBlacklistOwner(address ownerToRectify) external;

    /// @notice Retrieves the list of blacklist owners
    function getAllBlacklistOwners() external view returns (address[] memory);

    /// @notice Retrieves the allowed list of blacklist transaction (sender, tx.from)
    function getBlacklistTxFrom() external view returns (address[] memory);

    /// @notice Retrieves the allowed list of blacklist transaction (interacted smart contract, tx.to)
    function getBlacklistTxTo() external view returns (address[] memory);

    /// @notice See if the address is allowed tx.from for blacklist transaction
    function isBlacklistTxFrom(address addr) external view returns (bool);

    /// @notice See if the  address is allowed tx.to for blacklist transaction
    function isBlacklistTxTo(address addr) external view returns (bool);
}
