// SPDX-License-Identifier: CC0-1.0
pragma solidity 0.8.17;

import "openzeppelin-contracts/token/SRC20/SRC20.sol";
import "./ISRC7410.sol";

contract SRC7410 is SRC20, ISRC7410 {

    constructor(
        string memory name_,
        string memory symbol_
    ) SRC20(name_, symbol_) {}

    function decreaseAllowanceBySpender(
        address _owner,
        uint256 _value
    ) public override(SRC20, ISRC7410) returns (bool success) {
        address spender = _msgSender();
        if (allowance(_owner, spender) > _value) {
            _spendAllowance(_owner, spender, _value);
        } else {
            _approve(_owner, spender, 0);
        }
        
        return true;
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual returns (bool) {
        return interfaceId == type(ISRC7410).interfaceId;
    }
}
