// SPDX-License-Identifier: CC0-1.0
// Contract based on [https://docs.openzeppelin.com/contracts/3.x/src721](https://docs.openzeppelin.com/contracts/3.x/src721)
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/SRC721/SRC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/SRC721/extensions/SRC721URIStorage.sol";
import "./nFR.sol";

contract MyNFT is SRC721URIStorage, Ownable, nFR {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    constructor() SRC721("MyNFT", "NFT") {}

    function mintNFT(address recipient, uint8 numGenerations, uint256 psrcentOfProfit, uint256 successiveRatio, string memory tokenURI)
        public onlyOwner
        returns (uint256)
    {
        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();
        _mint(recipient, newItemId, numGenerations, psrcentOfProfit, successiveRatio);
        _setTokenURI(newItemId, tokenURI);

        return newItemId;
    }

    function mintSRC721(address recipient, string memory tokenURI) public onlyOwner {
        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();
        _mint(recipient, newItemId);
        _setTokenURI(newItemId, tokenURI);
    }

    function setDefaultFRInfo(uint8 numGenerations, uint256 psrcentOfProfit, uint256 successiveRatio) public onlyOwner {
        _setDefaultFRInfo(numGenerations, psrcentOfProfit, successiveRatio);
    }

    function burnNFT(uint256 tokenId) public onlyOwner {
        _burn(tokenId);
    }

    function _burn(uint256 tokenId) internal override(nFR, SRC721URIStorage) {
        super._burn(tokenId);
    }

    function _transfer(address from, address to, uint256 tokenId) internal override(SRC721, nFR) {
        super._transfer(from, to, tokenId);
    }

    function _mint(address to, uint256 tokenId) internal virtual override(SRC721, nFR) { 
        super._mint(to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(SRC721, nFR) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(SRC721, SRC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
}
