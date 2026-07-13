// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./ISRC7007.sol";

/**
 * @title SRC7007 Token Standard, optional updatable extension
 */
interface ISRC7007Updatable is ISRC7007 {
    /**
     * @dev Update the `aigcData` of `prompt`.
     */
    function update(
        bytes calldata prompt,
        bytes calldata aigcData
    ) external;

    /**
     * @dev Emitted when `tokenId` token is updated.
     */
    event Update(
        uint256 indexed tokenId,
        bytes indexed prompt,
        bytes indexed aigcData
    );
}
