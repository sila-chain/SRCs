// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

import "./SRC5007.sol";

contract SRC5007Demo is SRC5007 {
    constructor(string memory name_, string memory symbol_) SRC721(name_, symbol_){}

    /**
     * @dev  mint a new  time NFT
     *
     * Requirements:
     *
     * - `to_` cannot be the zero address.
     * - `tokenId_` must not exist.
     * - `endTime_` should be equal or greater than `startTime_`
     */
    function mint(
        address to_,
        uint256 tokenId_,
        uint64 startTime_,
        uint64 endTime_
    ) public {
        _mintTimeNft(to_, tokenId_, startTime_, endTime_);
    }

    /**
     * @dev Returns the interfaceId of ISRC5007.
     */
    function getInterfaceId() public pure returns (bytes4) {
        return type(ISRC5007).interfaceId;
    }
}
