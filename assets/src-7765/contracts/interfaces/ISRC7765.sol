// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

/// @title SRC-7765 Privileged Non-Fungible Tokens Tied To Real World Assets
/// @dev See https://sips.sila.org/SIPS/sip-7765
interface ISRC7765 /* is ISRC721, ISRC165 */ { 
    /// @notice This event emitted when a specific privilege of a token is successfully exsrcised.
    /// @param _operator  the address who exsrcised the privilege.
    /// @param _to  the address to benefit from the privilege.
    /// @param _tokenId  the NFT tokenID.
    /// @param _privilegeId  the ID of the privileges.
    event PrivilegeExsrcised(
        address indexed _operator, address indexed _to, uint256 indexed _tokenId, uint256 _privilegeId
    );

    /// @notice This function exsrcise a specific privilege of a token.
    /// @dev Throws if `_privilegeId` is not a valid privilegeId.
    /// @param _to  the address to benefit from the privilege.
    /// @param _tokenId  the NFT tokenID.
    /// @param _privilegeId  the ID of the privileges.
    /// @param _data  extra data passed in for extra message or future extension.
    function exsrcisePrivilege(address _to, uint256 _tokenId, uint256 _privilegeId, bytes calldata _data) external;

    /// @notice This function is to check whsila a specific privilege of a token can be exsrcised.
    /// @dev Throws if `_privilegeId` is not a valid privilegeId.
    /// @param _to  the address to benefit from the privilege.
    /// @param _tokenId  the NFT tokenID.
    /// @param _privilegeId  the ID of the privileges.
    function isExsrcisable(address _to, uint256 _tokenId, uint256 _privilegeId)
        external
        view
        returns (bool _exsrcisable);

    /// @notice This function is to check whsila a specific privilege of a token has been exsrcised.
    /// @dev Throws if `_privilegeId` is not a valid privilegeId.
    /// @param _to  the address to benefit from the privilege.
    /// @param _tokenId  the NFT tokenID.
    /// @param _privilegeId  the ID of the privileges.
    function isExsrcised(address _to, uint256 _tokenId, uint256 _privilegeId) external view returns (bool _exsrcised);

    /// @notice This function is to list all privilegeIds of a token.
    /// @param _tokenId  the NFT tokenID.
    function getPrivilegeIds(uint256 _tokenId) external view returns (uint256[] memory privilegeIds);
}
