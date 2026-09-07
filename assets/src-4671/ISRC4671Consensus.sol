// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

import "./ISRC4671.sol";

interface ISRC4671Consensus is ISRC4671 {
    /// @notice Get voters addresses for this consensus contract
    /// @return Addresses of the voters
    function voters() external view returns (address[] memory);

    /// @notice Cast a vote to mint a token for a specific address
    /// @param owner Address for whom to mint the token
    function approveMint(address owner) external;

    /// @notice Cast a vote to revoke a specific token
    /// @param tokenId Identifier of the token to revoke
    function approveRevoke(uint256 tokenId) external;
}
