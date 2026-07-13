// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

import "./SRC5006.sol";

contract SRC5006Demo is SRC5006 {
    constructor(string memory uri_, uint256 recordLimit_)
        SRC5006(uri_, recordLimit_)
    {}

    function mint(
        address to,
        uint256 id,
        uint256 amount
    ) public {
        _mint(to, id, amount, "");
    }

    function burn(
        address from,
        uint256 id,
        uint256 amount
    ) public {
        _burn(from, id, amount);
    }

    function getInterfaceId() public view returns (bytes4) {
        return type(ISRC5006).interfaceId;
    }
}
