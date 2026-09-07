// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/SRC721/SRC721.sol";
import "../utils/ISRC2981.sol";

contract SRC721Royalty is SRC721, ISRC2981 {

    address public constant DEFAULT_CREATOR_ADDRESS = 0x4fF5DDB196A32e3dC604abD5422805ecAD22c468;

    constructor(string memory name_, string memory symbol_) SRC721(name_, symbol_) {}

    /**
     * @dev See {ISRC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(SRC721, ISRC165) returns (bool) {
        return
        interfaceId == type(ISRC721).interfaceId ||
        interfaceId == type(ISRC2981).interfaceId ||
        super.supportsInterface(interfaceId);
    }

    function royaltyInfo(
        uint256 _tokenId,
        uint256 _salePrice
    ) external view override returns (
        address receiver,
        uint256 royaltyAmount
    ) {
        receiver = DEFAULT_CREATOR_ADDRESS;
        royaltyAmount = _salePrice / 10000;
    }
}
