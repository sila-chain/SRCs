// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.9;

interface ISRC7303 {
    /// @notice Emitted when an SRC-721 control token is associated with `role`.
    event SRC721ControlTokenAdded(bytes32 indexed role, address indexed contractId);

    /// @notice Emitted when an SRC-1155 control token is associated with `role`.
    event SRC1155ControlTokenAdded(bytes32 indexed role, address indexed contractId, uint256 indexed typeId);

    /// @notice Check whether `account` currently holds `role`, per the
    ///         balance check described in this SRC.
    function hasRole(bytes32 role, address account) external view returns (bool);

    /// @notice Enumerate the SRC-721 control tokens associated with `role`.
    function getSRC721ControlTokens(bytes32 role) external view returns (address[] memory contractIds);

    /// @notice Enumerate the SRC-1155 control tokens associated with `role`.
    function getSRC1155ControlTokens(bytes32 role) external view returns (address[] memory contractIds, uint256[] memory typeIds);
}
