// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/OffchainLabs/nitro-contracts/blob/main/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.4.21 <0.9.0;

/// @title Provides owners with tools for managing the rollup.
/// @notice Calls by non-owners will always revert.
/// Most of Arbitrum Classic's owner methods have been removed since they no longer make sense in Nitro:
/// - What were once chain parameters are now parts of ArbOS's state, and those that remain are set at genesis.
/// - ArbOS upgrades happen with the rest of the system rather than being independent
/// - Exemptions to address aliasing are no longer offered. Exemptions were intended to support backward compatibility for contracts deployed before aliasing was introduced, but no exemptions were ever requested.
/// Precompiled contract that exists in every Arbitrum chain at 0x00000000000000000000000000000000000007EA.
interface DeriwSubAccount {

    function addSubAccountOwner(address newOwner) external;

    /// @notice Remove account from the list of chain owners
    function removeSubAccountOwner(address ownerToRemove) external;

    /// @notice See if the user is a chain owner
    function isSubAccountOwner(address addr) external view returns (bool);




    /// @notice Add account as a chain owner
    function addAllowedAddress(address newAddress) external;

    /// @notice Remove account from the list of chain owners
    function removeAllowedAddress(address addressToRemove) external;

    /// @notice See if the user is a chain owner
    function isAllowedAddress(address addr) external view returns (bool);

    /// @notice Retrieves the list of chain owners
    function getAllAllowedOwner() external view returns (address[] memory);
    function getAllSubAccountOwner() external view returns (address[] memory);


    // Emitted when a successful call is made to this precompile
    event OwnerActs(bytes4 indexed method, address indexed owner, bytes data);



}
