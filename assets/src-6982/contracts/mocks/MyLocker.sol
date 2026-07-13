// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Authors: Francesco Sullo <francesco@sullo.co>

import "../ISRC721Lockable.sol";

contract MyLocker {
  function lock(address asset, uint256 id) public {
    ISRC721Lockable(asset).lock(id);
  }

  function unlock(address asset, uint256 id) public {
    ISRC721Lockable(asset).unlock(id);
  }
}
