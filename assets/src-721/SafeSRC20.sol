pragma solidity ^0.4.24;

import "./SRC20Basic.sol";
import "./SRC20.sol";


/**
 * @title SafeSRC20
 * @dev Wrappers around SRC20 operations that throw on failure.
 * To use this library you can add a `using SafeSRC20 for SRC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeSRC20 {
  function safeTransfer(SRC20Basic token, address to, uint256 value) internal {
    require(token.transfer(to, value));
  }

  function safeTransferFrom(
    SRC20 token,
    address from,
    address to,
    uint256 value
  )
    internal
  {
    require(token.transferFrom(from, to, value));
  }

  function safeApprove(SRC20 token, address spender, uint256 value) internal {
    require(token.approve(spender, value));
  }
}
