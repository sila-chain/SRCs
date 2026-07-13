// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

import "../SRC5058.sol";

contract SIP5058Mock is SRC721Enumerable, SRC5058 {
    constructor(string memory name, string memory symbol) SRC721(name, symbol) {}

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    function lockMint(
        address to,
        uint256 tokenId,
        uint256 expired
    ) external {
        _safeLockMint(to, tokenId, expired, "");
    }

    function mint(address to, uint256 tokenId) external {
        _mint(to, tokenId);
    }

    function burn(uint256 tokenId) external {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "SRC721: caller is not owner nor approved");

        _burn(tokenId);
    }

    function _burn(uint256 tokenId) internal virtual override(SRC721, SRC5058) {
        super._burn(tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(SRC721Enumerable, SRC5058) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(SRC721Enumerable, SRC5058)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
