// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/ISRC165.sol";

interface ISRC4671Store is ISRC165 {
    // Event emitted when a ISRC4671Enumerable contract is added to the owner's records
    event Added(address owner, address token);

    // Event emitted when a ISRC4671Enumerable contract is removed from the owner's records
    event Removed(address owner, address token);

    /// @notice Add a ISRC4671Enumerable contract address to the caller's record
    /// @param token Address of the ISRC4671Enumerable contract to add
    function add(address token) external;

    /// @notice Remove a ISRC4671Enumerable contract from the caller's record
    /// @param token Address of the ISRC4671Enumerable contract to remove
    function remove(address token) external;

    /// @notice Get all the ISRC4671Enumerable contracts for a given owner
    /// @param owner Address for which to retrieve the ISRC4671Enumerable contracts
    function get(address owner) external view returns (address[] memory);
}
