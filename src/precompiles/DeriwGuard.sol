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
/// Precompiled contract that exists in every Arbitrum chain at 0x0000000000000000000000000000000000000070.
interface DeriwGuard {
    // Emitted when a successful call is made to this precompile
    event OwnerActs(bytes4 indexed method, address indexed owner, bytes data);

    /// @notice Retrieves the list of tx.from in pricer
    function getPricerTxFromAddrs() external view returns (address[] memory);

    /// @notice Retrieves the list of tx.to in pricer
    function getPricerTxToAddrs() external view returns (address[] memory);

    /// @notice Add a tx.from to the pricer
    function addPricerTxFrom(address addr) external;

    /// @notice Add a tx.to to the pricer
    function addPricerTxTo(address addr) external;

    /// @notice See if the tx.from is in the pricer
    function isPricerTxFrom(address addr) external view returns (bool);

    /// @notice See if the tx.to is in the pricer
    function isPricerTxTo(address addr) external view returns (bool);

    /// @notice Remove tx.from from the pricer
    function removePricerTxFrom(address addr) external;

    // @notice Remove tx.to from the pricer
    function removePricerTxTo(address addr) external;
}
