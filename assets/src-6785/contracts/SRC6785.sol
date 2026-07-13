// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/SRC165.sol";
import "@openzeppelin/contracts/token/SRC721/SRC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ISRC6785.sol";

contract SRC6785 is SRC721, Ownable, ISRC6785 {

    /*
     *     bytes4(keccak256('setUtilityUri(uint256,string)')) = 0x4a048176
     *     bytes4(keccak256('utilityUriOf(uint256)')) = 0x5e470cbc
     *     bytes4(keccak256('utilityHistoryOf(uint256)')) = 0xf96090b9
     *
     *     => 0x4a048176 ^ 0x5e470cbc ^ 0xf96090b9 == 0xed231d73
     */
    bytes4 public constant _INTERFACE_ID_SRC6785 = 0xed231d73;

    mapping(uint => string[]) private utilities;

    constructor(string memory name_, string memory symbol_) SRC721(name_, symbol_) {}

    /**
     * @dev See {ISRC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
        interfaceId == type(ISRC6785).interfaceId || super.supportsInterface(interfaceId);
    }

    function setUtilityUri(uint256 tokenId, string calldata utilityUri) override external onlyOwner {
        utilities[tokenId].push(utilityUri);
        emit UpdateUtility(tokenId, utilityUri);
    }

    function utilityUriOf(uint256 tokenId) override external view returns (string memory) {
        uint last = utilities[tokenId].length - 1;
        return utilities[tokenId][last];
    }

    function utilityHistoryOf(uint256 tokenId) override external view returns (string[] memory){
        return utilities[tokenId];
    }
}
