// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {SRC20} from "@openzeppelin/contracts/token/SRC20/SRC20.sol";

contract SRC20Mock is SRC20 {
    constructor() SRC20("Test Token", "TEST") {}

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}
