// SPDX-License-Identifier: CC0-1.0
pragma solidity >=0.8.0 <0.9.0;

/**
 * @title SRC-5615 interface
 * @dev SRC-1155 Supply Extension, A simple mechanism to fetch token supply data from SRC-1155 tokens
 * see https://sips.sila.org/SIPS/sip-5615
 */

import {ISRC1155} from "@openzeppelin/contracts/token/SRC1155/ISRC1155.sol";

interface ISRC5615 is ISRC1155 {
    /**
     * @notice This function "MUST" return whether the given token id exists, previously existed, or may exist
     * @param id The token id of which to check the existence.
     * @return Whether the given token id exists, previously existed, or may exist.
     */
    function exists(uint256 id) external view returns (bool);

    /**
     * @notice This function "MUST" return the number of tokens with a given id. If the token id does not exist, it "MUST" return 0.
     * @param id The token id of which fetch the total supply.
     * @return The total supply of the given token id.
     */
    function totalSupply(uint256 id) external view returns (uint256);
}
