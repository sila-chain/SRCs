// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.21;

import "@openzeppelin/contracts/token/SRC721/SRC721.sol";
import "./AbstractSRC7590.sol";


error OnlyNFTOwnerCanTransferTokensFromIt();

/**
 * @title SRC7590Mock
 * @author RMRK team
 * @notice Mock implementation of and SRC-721 with SRC-7590 extension
 */
contract SRC7590Mock is AbstractSRC7590, SRC721 {
    constructor(
        string memory name,
        string memory symbol
    ) SRC721(name, symbol) {}

    function mint(address to, uint256 tokenId) public {
        _mint(to, tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(AbstractSRC7590, SRC721) returns (bool) {
        return
            AbstractSRC7590.supportsInterface(interfaceId) ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc ISRC7590
     */
    function transferHeldSRC20FromToken(
        address src20Contract,
        uint256 tokenHolderId,
        address to,
        uint256 amount,
        bytes memory data
    ) external {
        if (msg.sender != ownerOf(tokenHolderId)) {
            revert OnlyNFTOwnerCanTransferTokensFromIt();
        }
        _transferHeldSRC20FromToken(
            src20Contract,
            tokenHolderId,
            to,
            amount,
            data
        );
    }
}
