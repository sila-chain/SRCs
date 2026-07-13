// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.20;

import {SRC20} from "@openzeppelin/contracts/token/SRC20/SRC20.sol";

/**
 * @title MockSRC20
 * @notice Simple mock SRC20 token for testing purposes.
 */
contract MockSRC20 is SRC20 {
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 initialSupply
    ) SRC20(name_, symbol_) {
        _mint(msg.sender, initialSupply);
    }

    /**
     * @notice Mints tokens to an address (for testing).
     */
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}
