// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import {SRC7858} from "./abstracts/SRC7858.sol";

contract MockSRC7858 is SRC7858 {
    constructor(string memory _name, string memory _symbol) SRC7858(_name, _symbol) {}

    function mint(address to, uint256 tokenId) public {
        _mint(to, tokenId);
    }

    function burn(uint256 tokenId) public {
        _clearTimeStamp(tokenId);
        _burn(tokenId);
    }

    function clearTimeStamp(uint256 tokenId) public {
        _clearTimeStamp(tokenId);
    }

    function updateTimeStamp(uint256 tokenId, uint256 start, uint256 end) public {
        _updateTimeStamp(tokenId, start, end);
    }
}
