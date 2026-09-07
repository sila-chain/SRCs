// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

import "../factory/ISRC5058Factory.sol";
import "../factory/ISRC721Bound.sol";
import "../SRC5058.sol";

abstract contract SRC5058Bound is SRC5058 {
    address public bound;

    function _setFactory(address _factory) internal {
        bound = ISRC5058Factory(_factory).boundOf(address(this));
    }

    function _setBoundBaseTokenURI(string memory uri) internal {
        ISRC721Bound(bound).setBaseTokenURI(uri);
    }

    function _setBoundContractURI(string memory uri) internal {
        ISRC721Bound(bound).setContractURI(uri);
    }

    function burnBound(uint256 tokenId) external {
        ISRC721Bound(bound).burn(tokenId);
    }

    // NOTE:
    //
    // this will be called when `lock` or `unlock`
    function _afterTokenLock(
        address operator,
        address from,
        uint256 tokenId,
        uint256 expired
    ) internal virtual override {
        super._afterTokenLock(operator, from, tokenId, expired);

        if (bound != address(0)) {
            if (expired != 0) {
                // lock mint
                if (operator != address(0)) {
                    ISRC721Bound(bound).safeMint(msg.sender, tokenId, "");
                }
            } else {
                // unlock
                if (ISRC721Bound(bound).exists(tokenId)) {
                    ISRC721Bound(bound).burn(tokenId);
                }
            }
        }
    }
}
