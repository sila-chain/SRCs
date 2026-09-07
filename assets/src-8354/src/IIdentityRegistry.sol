// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.20;

/// @notice The single SRC-8004 Identity Registry call this standard needs. An agent exists on the
/// chain where the verdict is consumed if its id is a live SRC-721 token there. Declared minimally
/// rather than imported so a Guard depends on the ownership read alone, not on the whole of SRC-8004.
interface IIdentityRegistry {
    /// @dev SRC-721 semantics: reverts if `agentId` is not a valid token id.
    function ownerOf(uint256 agentId) external view returns (address owner);
}
