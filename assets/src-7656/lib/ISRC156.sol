// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.20;

interface ISRC165 {
  function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
