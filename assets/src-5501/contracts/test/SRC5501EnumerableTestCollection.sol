// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0; 

import "../SRC5501Enumerable.sol";

contract SRC5501EnumerableTestCollection is SRC5501Enumerable {

    constructor(string memory name_, string memory symbol_) SRC5501Enumerable(name_,symbol_) {}

    function getUserBalances(address user) external view returns (uint256[] memory) {
        return _userBalances[user];
    }

    function mint(address to, uint256 tokenId) public {
        _mint(to, tokenId);
    }
}
