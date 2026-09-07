// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.20;

import {ISRC165} from "./interfaces/ISRC165.sol";
import {ISRC7656Service} from "./interfaces/ISRC7656Service.sol";

import {SRC7656ServiceLib} from "./lib/SRC7656ServiceLib.sol";

/**
 * @title SRC7656Service.sol
 */
contract SRC7656Service is ISRC7656Service, ISRC165 {
  function supportsInterface(bytes4 interfaceId) public pure virtual override returns (bool) {
    return interfaceId == type(ISRC7656Service).interfaceId || interfaceId == type(ISRC165).interfaceId;
  }

  /**
   * @notice Returns the linkedContract linked to the contract
   */
  function linkedData() public view virtual override returns (uint256, bytes12, address, uint256) {
    return _linkedData();
  }

  /**
   * Private functions
   */

  function _linkedData() internal view returns (uint256, bytes12, address, uint256) {
    return SRC7656ServiceLib.linkedData(address(this));
  }

}
