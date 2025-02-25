// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/OffchainLabs/nitro-contracts/blob/main/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.4.21 <0.9.0;

/// @title Provides owners with tools for managing the blacklist configuration.
/// @notice Calls by non-owners will always revert.
/// Precompiled contract that exists in Deriw chain at 0x00000000000000000000000000000000000007EC.
interface DeriwBlacklist{
    /// @notice Add account as a blacklist owner
    function addBlacklistOwner(address newOwner) external;

    /// @notice Remove account from the list of blacklist owners
    function removeBlacklistOwner(address ownerToRemove) external;

    /// @notice See if the user is a blacklist owner
    function isBlacklistOwner(address addr) external view returns (bool);

    /// @notice Retrieves the list of blacklist owners
    function getAllBlacklistOwners() external view returns (address[] memory);

    // Emitted when a successful call is made to this precompile
    event OwnerActs(bytes4 indexed method, address indexed owner, bytes data);

    /// @notice Retrieves the allowed list of blacklist transaction (sender, tx.from)
    function getBlacklistTxFrom() external view returns (address[] memory);

    /// @notice Retrieves the allowed list of blacklist transaction (interacted smart contract, tx.to)
    function getBlacklistTxTo() external view returns (address[] memory);

    /// @notice Add a address that can send (tx.to) blacklist transaction
    function addBlacklistTxFrom(address addr) external;

    /// @notice Add a address tx.to is blacklist transaction
    function addBlacklistTxTo(address addr) external;

    /// @notice See if the tx.from address is in the blacklist transaction
    function isBlacklistTxFrom(address addr) external view returns (bool);

    /// @notice See if the tx.to is in the blacklist transaction
    function isBlacklistTxTo(address addr) external view returns (bool);

    /// @notice Remove tx.from address from the blacklist sender
    function removeBlacklistTxFrom(address addr) external;

    // @notice Remove tx.to address from the blacklist contract
    function removeBlacklistTxTo(address addr) external;
}
