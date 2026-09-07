// SPDX-License-Identifier: CC0-1.0
// Reference implementation of SRC-7303, identical to the one in the SRC text.

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/SRC721/SRC721.sol";
import "@openzeppelin/contracts/token/SRC1155/SRC1155.sol";
import "./ISRC7303.sol";

abstract contract SRC7303 is ISRC7303 {
    struct SRC721Token {
        address contractId;
    }

    struct SRC1155Token {
        address contractId;
        uint256 typeId;
    }

    mapping (bytes32 => SRC721Token[]) private _SRC721_Contracts;
    mapping (bytes32 => SRC1155Token[]) private _SRC1155_Contracts;

    modifier onlyHasToken(bytes32 role, address account) {
        require(_checkHasToken(role, account), "SRC7303: not has a required token");
        _;
    }

    /**
     * @notice Check whether `account` currently holds `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _checkHasToken(role, account);
    }

    /**
     * @notice Enumerate the SRC-721 control tokens associated with `role`.
     */
    function getSRC721ControlTokens(bytes32 role) public view returns (address[] memory contractIds) {
        SRC721Token[] memory tokens = _SRC721_Contracts[role];
        contractIds = new address[](tokens.length);
        for (uint i = 0; i < tokens.length; i++) {
            contractIds[i] = tokens[i].contractId;
        }
    }

    /**
     * @notice Enumerate the SRC-1155 control tokens associated with `role`.
     */
    function getSRC1155ControlTokens(bytes32 role) public view returns (address[] memory contractIds, uint256[] memory typeIds) {
        SRC1155Token[] memory tokens = _SRC1155_Contracts[role];
        contractIds = new address[](tokens.length);
        typeIds = new uint256[](tokens.length);
        for (uint i = 0; i < tokens.length; i++) {
            contractIds[i] = tokens[i].contractId;
            typeIds[i] = tokens[i].typeId;
        }
    }

    /**
     * @notice Grant a role to user who owns a control token specified by the SRC-721 contractId.
     * Multiple calls are allowed, in this case the user must own at least one of the specified token.
     * @param role byte32 The role which you want to grant.
     * @param contractId address The address of contractId of which token the user required to own.
     */
    function _grantRoleBySRC721(bytes32 role, address contractId) internal {
        require(
            ISRC165(contractId).supportsInterface(type(ISRC721).interfaceId),
            "SRC7303: provided contract does not support SRC721 interface"
        );
        _SRC721_Contracts[role].push(SRC721Token(contractId));
        emit SRC721ControlTokenAdded(role, contractId);
    }

    /**
     * @notice Grant a role to user who owns a control token specified by the SRC-1155 contractId.
     * Multiple calls are allowed, in this case the user must own at least one of the specified token.
     * @param role byte32 The role which you want to grant.
     * @param contractId address The address of contractId of which token the user required to own.
     * @param typeId uint256 The token type id that the user required to own.
     */
    function _grantRoleBySRC1155(bytes32 role, address contractId, uint256 typeId) internal {
        require(
            ISRC165(contractId).supportsInterface(type(ISRC1155).interfaceId),
            "SRC7303: provided contract does not support SRC1155 interface"
        );
        _SRC1155_Contracts[role].push(SRC1155Token(contractId, typeId));
        emit SRC1155ControlTokenAdded(role, contractId, typeId);
    }

    function _checkHasToken(bytes32 role, address account) internal view returns (bool) {
        SRC721Token[] memory SRC721Tokens = _SRC721_Contracts[role];
        for (uint i = 0; i < SRC721Tokens.length; i++) {
            if (ISRC721(SRC721Tokens[i].contractId).balanceOf(account) > 0) return true;
        }

        SRC1155Token[] memory SRC1155Tokens = _SRC1155_Contracts[role];
        for (uint i = 0; i < SRC1155Tokens.length; i++) {
            if (ISRC1155(SRC1155Tokens[i].contractId).balanceOf(account, SRC1155Tokens[i].typeId) > 0) return true;
        }

        return false;
    }
}
