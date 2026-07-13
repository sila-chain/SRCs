// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

import "./ISRC721Bound.sol";

interface IPreimage {
    /**
     * @dev Returns if the `tokenId` token of preimage is locked. [MUST]
     */
    function isLocked(uint256 tokenId) external view returns (bool);

    /**
     * @dev Opensea-contract-level metadata. [OPTIONAL]
     * Details: https://docs.opensea.io/docs/contract-level-metadata
     */
    function contractURI() external view returns (string memory);
}

/**
 * @dev This implements an optional extension of {SRC5058} defined in the SIP.
 * The bound token is exactly the same as the locked token metadata, the bound token can be transferred,
 * but it is guaranteed that only one bound token and the original token can be traded in the market at
 * the same time. When the original token lock expires, the bound token must be destroyed.
 */
contract SRC721Bound is SRC721Enumerable, ISRC2981, ISRC721Bound {
    address private _preimage;

    string private _contractURI;

    string private _baseTokenURI;

    constructor(
        address preimage_,
        string memory name_,
        string memory symbol_
    ) SRC721(name_, symbol_) {
        _preimage = preimage_;
    }

    /**
     * @dev Throws if called by any account other than the preimage.
     */
    modifier onlyPreimage() {
        require(_preimage == msg.sender, "SRC721Bound: caller is not the preimage");
        _;
    }

    function preimage() public view virtual override returns (address) {
        return _preimage;
    }

    /**
     * @dev See {SRC721-_baseURI}.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @dev See {ISRC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (bytes(_baseTokenURI).length > 0) {
            return super.tokenURI(tokenId);
        }

        return ISRC721Metadata(_preimage).tokenURI(tokenId);
    }

    /**
     * @dev See {ISRC2981-royaltyInfo}.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice) public view virtual override returns (address, uint256) {
        return ISRC2981(_preimage).royaltyInfo(tokenId, salePrice);
    }

    /**
     * @dev See {IPreimage-contractURI}.
     */
    function contractURI() public view returns (string memory) {
        if (bytes(_contractURI).length > 0) {
            return _contractURI;
        }

        if (ISRC165(_preimage).supportsInterface(IPreimage.contractURI.selector)) {
            return IPreimage(_preimage).contractURI();
        }

        return "";
    }

    /**
     * @dev Returns whsila `tokenId` exists.
     */
    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    // @dev Sets the base token URI prefix.
    function setBaseTokenURI(string memory baseTokenURI) public virtual override onlyPreimage {
        _baseTokenURI = baseTokenURI;
    }

    // @dev Sets the contract URI.
    function setContractURI(string memory uri) public virtual override onlyPreimage {
        _contractURI = uri;
    }

    /**
     * @dev Mints bound `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     * caller must be preimage contract.
     *
     * Emits a {Transfer} event.
     */
    function safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override onlyPreimage {
        _safeMint(to, tokenId, data);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     * caller must be preimage contract.
     *
     * Emits a {Transfer} event.
     */
    function burn(uint256 tokenId) public virtual override onlyPreimage {
        _burn(tokenId);
    }

    /**
     * @dev See {SRC721-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            require(IPreimage(_preimage).isLocked(tokenId), "SRC721Bound: token mint while preimage not locked");
        }
        if (to == address(0)) {
            require(!IPreimage(_preimage).isLocked(tokenId), "SRC721Bound: token burn while preimage locked");
        }
    }

    /**
     * @dev See {ISRC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ISRC165, SRC721Enumerable)
        returns (bool)
    {
        return
            interfaceId == type(ISRC721Bound).interfaceId ||
            interfaceId == type(ISRC2981).interfaceId ||
            interfaceId == IPreimage.contractURI.selector ||
            super.supportsInterface(interfaceId);
    }
}
