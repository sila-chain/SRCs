// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.20;

/// @title ISRC8063 — Optional membership introspection for SRC-20 tokens
/// @notice A Group is an SRC-20 token where balance represents membership level
interface ISRC8063 {
    /// @notice Returns true if `account` holds at least `threshold` tokens
    /// @param account The address to check
    /// @param threshold Minimum balance required for membership at this tier
    /// @dev Equivalent to: balanceOf(account) >= threshold
    function isMember(address account, uint256 threshold) external view returns (bool);
}
