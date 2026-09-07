// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/SRC721/SRC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @notice Minimal SRC-721 control token for the conformance fixture.
/// The issuer (owner) grants a role by minting and revokes it by burning
/// without the holder's cooperation — the issuer-side kill switch described
/// in the SRC's Security Considerations.
contract SRC721ControlToken is SRC721, Ownable {
    uint256 private _nextId;

    constructor() SRC721("FixtureControl721", "FC721") Ownable(msg.sender) {}

    function mint(address to) external onlyOwner returns (uint256 tokenId) {
        tokenId = ++_nextId;
        _safeMint(to, tokenId);
    }

    function burnByIssuer(uint256 tokenId) external onlyOwner {
        _burn(tokenId);
    }
}
