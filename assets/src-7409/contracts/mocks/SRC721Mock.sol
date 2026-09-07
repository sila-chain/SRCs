// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/SRC721/SRC721.sol";

/**
 * @title SRC721Mock
 * Used for tests
 */
contract SRC721Mock is SRC721 {
    constructor(
        string memory name,
        string memory symbol
    ) SRC721(name, symbol) {}

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}
