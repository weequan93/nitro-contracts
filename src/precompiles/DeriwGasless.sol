// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/OffchainLabs/nitro-contracts/blob/main/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.4.21 <0.9.0;

/// @title Provides owners with tools for managing the gasless configuration.
/// @notice Calls by non-owners will always revert.
/// Precompiled contract that exists in Deriw chain at 0x00000000000000000000000000000000000007E8.
interface DeriwGasless {
    /// @notice Add account as a gasless owner
    function addGaslessOwner(address newOwner) external;

    /// @notice Remove account from the list of gasless owners
    function removeGaslessOwner(address ownerToRemove) external;

    /// @notice See if the user is a gasless owner
    function isGaslessOwner(address addr) external view returns (bool);

    /// @notice Retrieves the list of gasless owners
    function getAllGaslessOwners() external view returns (address[] memory);

    // Emitted when a successful call is made to this precompile
    event OwnerActs(bytes4 indexed method, address indexed owner, bytes data);

    /// @notice Retrieves the allowed list of gasless transaction (sender, tx.from)
    function getPricerTxFromAddrs() external view returns (address[] memory);

    /// @notice Retrieves the allowed list of gasless transaction (interacted smart contract, tx.to)
    function getPricerTxToAddrs() external view returns (address[] memory);

    /// @notice Add a address that can send (tx.to) gasless transaction
    function addPricerTxFrom(address addr) external;

    /// @notice Add a address tx.to is gasless transaction
    function addPricerTxTo(address addr) external;

    /// @notice See if the tx.from address is in the gasless transaction
    function isPricerTxFrom(address addr) external view returns (bool);

    /// @notice See if the tx.to is in the gasless transaction
    function isPricerTxTo(address addr) external view returns (bool);

    /// @notice Remove tx.from address from the gasless sender
    function removePricerTxFrom(address addr) external;

    // @notice Remove tx.to address from the gasless contract
    function removePricerTxTo(address addr) external;
}
