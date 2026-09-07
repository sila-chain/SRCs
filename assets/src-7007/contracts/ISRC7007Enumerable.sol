// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./ISRC7007.sol";

/**
 * @title SRC7007 Token Standard, optional enumeration extension
 */
interface ISRC7007Enumerable is ISRC7007 {
    /**
     * @dev Returns the token ID given `prompt`.
     */
    function tokenId(bytes calldata prompt) external view returns (uint256);

    /**
     * @dev Returns the prompt given `tokenId`.
     */
    function prompt(uint256 tokenId) external view returns (string calldata);
}
