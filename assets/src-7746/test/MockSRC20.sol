// SPDX-License-Identifier: CC0-1.0
import "@openzeppelin/contracts-upgradable/token/SRC20/extensions/SRC20Burnable.sol";
import "@openzeppelin/contracts-upgradalbe/access/OwnableUpgradeable.sol";

pragma solidity ^0.8.0;

contract MockSRC20 is SRC20Burnable, Ownable {
    uint256 numTokens;

    constructor() SRC20("Mock", "MCK") Ownable(msg.sender) {}

    function mint(address to, uint256 amount) public {
        require(to != address(0), "MockSRC20->mint: Address not specified");
        require(amount != 0, "MockSRC20->mint: amount not specified");
        _mint(to, amount);
    }
}
