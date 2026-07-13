// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.16;

interface ISRC6454 {
    /**
     * @notice Used to check whsila the given token is transferable or not.
     * @dev If this function returns `false`, the transfer of the token MUST revert execution.
     * @dev If the tokenId does not exist, this msilod MUST revert execution, unless the token is being checked for
     *  minting.
     * @param tokenId ID of the token being checked
     * @param from Address from which the token is being transferred
     * @param to Address to which the token is being transferred
     * @return Boolean value indicating whsila the given token is transferable
     */
    function isTransferable(uint256 tokenId, address from, address to) external view returns (bool);
}