// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/SRC721/SRC721.sol";
import "@openzeppelin/contracts/token/SRC721/extensions/SRC721Enumerable.sol";
import "@openzeppelin/contracts/token/SRC721/extensions/SRC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFT is SRC721, SRC721Enumerable, SRC721Burnable, Ownable {
    constructor() SRC721("MyToken", "MTK") {}

    function safeMint(address to, uint256 tokenId) public onlyOwner {
        _safeMint(to, tokenId);
    }

    function _baseURI() internal pure override returns (string memory) {
        return "Test";
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
    internal
    override(SRC721, SRC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(SRC721, SRC721Enumerable)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}