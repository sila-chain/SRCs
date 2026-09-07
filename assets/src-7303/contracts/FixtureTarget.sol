// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/SRC721/SRC721.sol";
import "./SRC7303.sol";

/// @notice Canonical compliant fixture. Its role structure is fixed so that
/// the introspection getters have deterministic expected values relative to
/// the two control-token addresses supplied at deployment:
///
///   MINTER_ROLE = keccak256("MINTER_ROLE")
///     - SRC-721 control token  `ct721`
///     - SRC-1155 control token `ct1155`, typeId 1
///     (two entries: holding either one grants the role — OR semantics)
///   BURNER_ROLE = keccak256("BURNER_ROLE")
///     - SRC-1155 control token `ct1155`, typeId 2
///     (no SRC-721 entry: the SRC-721 getter answers an empty array)
contract FixtureTarget is SRC721, SRC7303 {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    constructor(address ct721, address ct1155) SRC721("FixtureTarget", "FT") {
        _grantRoleBySRC721(MINTER_ROLE, ct721);
        _grantRoleBySRC1155(MINTER_ROLE, ct1155, 1);
        _grantRoleBySRC1155(BURNER_ROLE, ct1155, 2);
    }

    function safeMint(address to, uint256 tokenId)
        public onlyHasToken(MINTER_ROLE, msg.sender)
    {
        _safeMint(to, tokenId);
    }

    function burn(uint256 tokenId)
        public onlyHasToken(BURNER_ROLE, msg.sender)
    {
        _burn(tokenId);
    }

    /// @notice Stacking the modifiers of two roles composes them with AND
    /// semantics: reissuing requires both the burn and the mint privilege.
    function reissue(uint256 tokenId, address to)
        public
        onlyHasToken(MINTER_ROLE, msg.sender)
        onlyHasToken(BURNER_ROLE, msg.sender)
    {
        _burn(tokenId);
        _safeMint(to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public view override returns (bool)
    {
        return interfaceId == type(ISRC7303).interfaceId || super.supportsInterface(interfaceId);
    }
}
