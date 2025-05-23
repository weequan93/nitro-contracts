// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/OffchainLabs/nitro-contracts/blob/main/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.4.21 <0.9.0;

/// @title Provides user to grant permission to sub-account, allowed sub-account able to send transaction on their behave.
/// Precompiled contract that exists in Deriw chain at 0x00000000000000000000000000000000000007EA.
interface DeriwSubAccount {
    /// @notice Add sub-account owner
    function addSubAccountOwner(address newOwner) external;

    /// @notice Remove sub-account owner
    function removeSubAccountOwner(address ownerToRemove) external;

    /// @notice See if the user is a sub-account owner
    function isSubAccountOwner(address addr) external view returns (bool);

    /// @notice Add smart contract address that allow sub-account to interact with
    function addAllowedAddress(address newAddress) external;

    /// @notice Remove smart contract address that allow sub-account to interact with
    function removeAllowedAddress(address addressToRemove) external;

    /// @notice Check is the address allowed for sub-account interaction
    function isAllowedAddress(address addr) external view returns (bool);

    /// @notice Retrieves the list smart contract address, that allow sub-account to interact with
    function getAllAllowedAddress() external view returns (address[] memory);

    /// @notice Retrieves the list of sub-account owner
    function getAllSubAccountOwner() external view returns (address[] memory);
    
    /// @notice Set usdt address, so that only approve method are allow for sub-account interact with
    function addUsdtAddress(address newAddress) external;

    /// @notice Remove smart contract address that allow sub-account to interact with
    function removeUsdtAddress(address addressToRemove) external;

    /// @notice Retrieve usdt address
    function isUsdtAddress(address addr) external view returns (bool);

    /// @notice Retrieves the list smart contract address, that allow for usdt sub-account to interact with
    function getAllUsdtAddress() external view returns (address[] memory);

    /// @notice reset all child parent relationship
    function resetAllRelationship() external;

    function resetAllRelationshipByIndex(uint64 size) external;

    function resetAllRelationshipByPosition(address addr) external;


    // Emitted when a successful call is made to this precompile
    event OwnerActs(bytes4 indexed method, address indexed owner, bytes data);
}
