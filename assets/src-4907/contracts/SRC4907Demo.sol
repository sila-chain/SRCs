// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

import "./SRC4907.sol";

contract SRC4907Demo is SRC4907 {

    constructor(string memory name_, string memory symbol_)
     SRC4907(name_,symbol_)
     {
     }

    function mint(uint256 tokenId, address to) public {
        _mint(to, tokenId);
    }

}
