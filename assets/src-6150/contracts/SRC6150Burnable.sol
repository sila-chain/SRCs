// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

import "./SRC6150.sol";
import "./interfaces/ISRC6150Burnable.sol";

abstract contract SRC6150Burnable is SRC6150, ISRC6150Burnable {
    function safeBurn(uint256 tokenId) public virtual override {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "SRC6150Burnable: caller is neither token owner nor approved"
        );
        _safeBurn(tokenId);
    }

    function safeBatchBurn(uint256[] memory tokenIds) public virtual override {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            safeBurn(tokenIds[i]);
        }
    }
}
