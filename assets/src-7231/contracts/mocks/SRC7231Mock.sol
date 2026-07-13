// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.17;

import "../SRC7231.sol";

contract SRC7231Mock is SRC7231 {
    
    constructor(
        string memory name,
        string memory symbol
    ) SRC7231(name, symbol) {}

    function mint(address to, uint256 tokenId) external {
        _mint(to, tokenId);
    }

    function transfer(address to, uint256 tokenId) external {
        _transfer(msg.sender, to, tokenId);
    }

    function burn(uint256 tokenId) external {
        _burn(tokenId);
    }
}
