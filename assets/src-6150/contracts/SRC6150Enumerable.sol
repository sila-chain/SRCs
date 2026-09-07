// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

import "./SRC6150.sol";
import "./interfaces/ISRC6150Enumerable.sol";

abstract contract SRC6150Enumerable is SRC6150, ISRC6150Enumerable {
    function childrenCountOf(
        uint256 parentId
    ) external view virtual override returns (uint256) {
        return childrenOf(parentId).length;
    }

    function childOfParentByIndex(
        uint256 parentId,
        uint256 index
    ) external view virtual override returns (uint256) {
        uint256[] memory children = childrenOf(parentId);
        return children[index];
    }

    function indexInChildrenEnumeration(
        uint256 parentId,
        uint256 tokenId
    ) external view virtual override returns (uint256) {
        require(parentOf(tokenId) == parentId, "wrong parent");
        return _getIndexInChildrenArray(tokenId);
    }
}
