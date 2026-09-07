// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/SRC721/SRC721.sol";
import "@openzeppelin/contracts/token/SRC1155/ISRC1155.sol";

/// @notice Negative fixture. Functionally identical balance gating to
/// `FixtureTarget` (same roles, same control tokens, same revert string),
/// but written in the pre-ISRC7303 style: no introspection interface and no
/// SRC-165 registration of the ISRC7303 identifier, so
/// `supportsInterface(0x4ee69337)` answers `false`. Discovery tooling
/// encountering this contract must classify it as NOT implementing this SRC,
/// even though its gating behaves identically on-chain.
contract LegacyTarget is SRC721 {
    ISRC721 private immutable _ct721;
    ISRC1155 private immutable _ct1155;

    constructor(address ct721, address ct1155) SRC721("LegacyTarget", "LT") {
        _ct721 = ISRC721(ct721);
        _ct1155 = ISRC1155(ct1155);
    }

    function safeMint(address to, uint256 tokenId) public {
        require(
            _ct721.balanceOf(msg.sender) > 0 || _ct1155.balanceOf(msg.sender, 1) > 0,
            "SRC7303: not has a required token"
        );
        _safeMint(to, tokenId);
    }

    function burn(uint256 tokenId) public {
        require(
            _ct1155.balanceOf(msg.sender, 2) > 0,
            "SRC7303: not has a required token"
        );
        _burn(tokenId);
    }
}
