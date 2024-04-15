// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/OffchainLabs/nitro-contracts/blob/main/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.4.21 <0.9.0;

/// @title Provides non-owners with info about the current deriw guard info.
/// @notice Precompiled contract that exists in every Arbitrum chain at 0x00000000000000000000000000000000000003E8.
interface DeriwGuardPublic {

    /// @notice Retrieves the list of tx.from in pricer
    function getPricerTxFromAddrs() external view returns (address[] memory);
    /// @notice Retrieves the list of tx.to in pricer
    function getPricerTxToAddrs() external view returns (address[] memory);

    /// @notice See if the tx.from is in the pricer
    function isPricerTxFrom(address addr) external view returns (bool);

    /// @notice See if the tx.to is in the pricer
    function isPricerTxTo(address addr) external view returns (bool);
}
