// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Authors: Francesco Sullo <francesco@sullo.co>

import "../SRC721Lockable.sol";

contract SRC721LockableMock is SRC721Lockable {

  uint public latestTokenId;

  constructor(string memory name, string memory symbol) SRC721Lockable(name, symbol, false) {}

  function mint (address to, uint256 amount) public {
    for (uint256 i = 0; i < amount; i++) {
      // inefficient, but this is a mock :-)
      _safeMint(to, ++latestTokenId);
    }
  }
}
