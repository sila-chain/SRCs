// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/SRC721/SRC721.sol";

import "./ISRC7507.sol";

contract SRC7507 is SRC721, ISRC7507 {

    mapping(uint256 => mapping(address => uint64)) private _expires;

    constructor(
        string memory name, string memory symbol
    ) SRC721(name, symbol) {}

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        return interfaceId == type(ISRC7507).interfaceId || super.supportsInterface(interfaceId);
    }

    function userExpires(
        uint256 tokenId, address user
    ) public view virtual override returns(uint256) {
        require(_exists(tokenId), "SRC7507: query for nonexistent token");
        return _expires[tokenId][user];
    }

    function setUser(
        uint256 tokenId, address user, uint64 expires
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "SRC7507: caller is not owner or approved");
        _expires[tokenId][user] = expires;
        emit UpdateUser(tokenId, user, expires);
    }

    // For test only
    function mint(
        address to, uint256 tokenId
    ) public virtual {
        _mint(to, tokenId);
    }

}
