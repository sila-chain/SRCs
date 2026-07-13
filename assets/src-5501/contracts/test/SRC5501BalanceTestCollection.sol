// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0; 

import "../SRC5501Balance.sol";

contract SRC5501BalanceTestCollection is SRC5501Balance {

    constructor(string memory name_, string memory symbol_) SRC5501Balance(name_,symbol_) {}

    function getUserBalances(address user) external view returns (uint256[] memory) {
        return _userBalances[user];
    }

    function mint(address to, uint256 tokenId) public {
        _mint(to, tokenId);
    }
}
