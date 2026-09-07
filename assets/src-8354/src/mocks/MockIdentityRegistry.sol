// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.20;

import {IIdentityRegistry} from "../IIdentityRegistry.sol";

/// @notice Test double for the SRC-8004 Identity Registry. Registers agent ids and reverts on
/// unknown ones, the way an SRC-721 `ownerOf` does.
contract MockIdentityRegistry is IIdentityRegistry {
    error NonexistentAgent(uint256 agentId);

    mapping(uint256 => address) private _owners;

    function register(uint256 agentId, address owner) external { _owners[agentId] = owner; }

    function ownerOf(uint256 agentId) external view returns (address) {
        address owner = _owners[agentId];
        if (owner == address(0)) revert NonexistentAgent(agentId);
        return owner;
    }
}
