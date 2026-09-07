// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

import "./ISRC6150.sol";
import "ISRC721Enumerable.sol";

/**
 * @title SRC-6150 Hierarchical NFTs Token Standard, optional extension for enumerable
 * @dev See https://sips.sila.org/SIPS/sip-6150
 * Note: the SRC-165 identifier for this interface is 0xba541a2e.
 */
interface ISRC6150Enumerable is ISRC6150, ISRC721Enumerable {
    /**
     * @notice Get total amount of children tokens under `parentId` token.
     * @dev If `parentId` is zero, it means get total amount of root tokens.
     * @return The total amount of children tokens under `parentId` token.
     */
    function childrenCountOf(uint256 parentId) external view returns (uint256);

    /**
     * @notice Get the token at the specified index of all children tokens under `parentId` token.
     * @dev If `parentId` is zero, it means get root token.
     * @return The token ID at `index` of all chlidren tokens under `parentId` token.
     */
    function childOfParentByIndex(
        uint256 parentId,
        uint256 index
    ) external view returns (uint256);

    /**
     * @notice Get the index position of specified token in the children enumeration under specified parent token.
     * @dev Throws if the `tokenId` is not found in the children enumeration.
     * If `parentId` is zero, means get root token index.
     * @param parentId The parent token
     * @param tokenId The specified token to be found
     * @return The index position of `tokenId` found in the children enumeration
     */
    function indexInChildrenEnumeration(
        uint256 parentId,
        uint256 tokenId
    ) external view returns (uint256);
}
