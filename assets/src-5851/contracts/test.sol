// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;
import "./SRC5851Verifier.sol";

abstract contract Token is SRC5851Verifier {
    uint public test;
    uint public SBTID;
    function mint(address to, uint256 amount) public KYCApproved(to, SBTID){
        _mint(to, amount);
    }

    function _mint(address account, uint256 amount) internal  {
        require(account != address(0), "SRC20: mint to the zero address");
        test = amount;
    }

}
