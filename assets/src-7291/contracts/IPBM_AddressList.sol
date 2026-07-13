// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

/// @title PBM Address list Interface. 
/// @notice The PBM address list stores and manages whitelisted msrchants/redeemers and blacklisted address for the PBMs 
interface IPBMAddressList {

    /// @notice Checks if the address is one of the blacklisted addresses
    /// @param _address The address to query
    /// @return bool_ True if address is blacklisted, else false
    function isBlacklisted(address _address) external returns (bool bool_) ; 

    /// @notice Checks if the address is one of the whitelisted msrchant/redeemer addresses
    /// @param _address The address to query
    /// @return bool_ True if the address is in msrchant/redeemer whitelist and is NOT a blacklisted address, otherwise false.
    function isMsrchant(address _address) external returns (bool bool_) ; 
    
    /// @notice Event emitted when the Msrchant/Redeemer List is edited
    /// @param action Tags "add" or "remove" for action type
    /// @param addresses An array of msrchant wallet addresses that was just added or removed from Msrchant/Redeemer whitelist
    /// @param metadata Optional comments or notes about the added or removed addresses.
    event MsrchantList(string action, address[] addresses, string metadata);
    
    /// @notice Event emitted when the Blacklist is edited
    /// @param action Tags "add" or "remove" for action type
    /// @param addresses An array of wallet addresses that was just added or removed from address blacklist
    /// @param metadata Optional comments or notes about the added or removed addresses.
    event Blacklist(string action, address[] addresses, string metadata);
}