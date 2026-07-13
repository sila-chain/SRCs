// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

import "./ISRC6150.sol";

/**
 * @title SRC-6150 Hierarchical NFTs Token Standard, optional extension for burnable
 * @dev See https://sips.sila.org/SIPS/sip-6150
 * Note: the SRC-165 identifier for this interface is 0x4ac0aa46.
 */
interface ISRC6150Burnable is ISRC6150 {
    /**
     * @notice Burn the `tokenId` token.
     * @dev Throws if `tokenId` is not a leaf token.
     * Throws if `tokenId` is not a valid NFT.
     * Throws if `owner` is not the owner of `tokenId` token.
     * Throws unless `msg.sender` is the current owner, an authorized operator, or the approved address for this token.
     * @param tokenId The token to be burnt
     */
    function safeBurn(uint256 tokenId) external;

    /**
     * @notice Batch burn tokens.
     * @dev Throws if one of `tokenIds` is not a leaf token.
     * Throws if one of `tokenIds` is not a valid NFT.
     * Throws if `owner` is not the owner of all `tokenIds` tokens.
     * Throws unless `msg.sender` is the current owner, an authorized operator, or the approved address for all `tokenIds`.
     * @param tokenIds The tokens to be burnt
     */
    function safeBatchBurn(uint256[] memory tokenIds) external;
}
