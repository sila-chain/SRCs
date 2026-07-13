// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

import "./SRC6150.sol";
import "./interfaces/ISRC6150ParentTransferable.sol";

abstract contract SRC6150ParentTransferable is
    SRC6150,
    ISRC6150ParentTransferable
{
    function transferParent(
        uint256 newParentId,
        uint256 tokenId
    ) public virtual override {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "SRC6150ParentTransferable: caller is not token owner nor approved"
        );
        if (newParentId != 0) {
            require(
                _exists(newParentId),
                "SRC6150ParentTransferable: newParentId doesn't exists"
            );
        }

        address owner = ownerOf(tokenId);
        uint256 oldParentId = parentOf(tokenId);
        _safeBurn(tokenId);
        _safeMintWithParent(owner, newParentId, tokenId);
        emit ParentTransferred(tokenId, oldParentId, newParentId);
    }

    function batchTransferParent(
        uint256 newParentId,
        uint256[] memory tokenIds
    ) public virtual override {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            transferParent(tokenIds[i], newParentId);
        }
    }
}
