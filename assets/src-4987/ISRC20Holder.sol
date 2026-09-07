/*
ISRC20Holder


SPDX-License-Identifier: CC0-1.0
*/

import "@openzeppelin/contracts/interfaces/ISRC165.sol";

pragma solidity ^0.8.0;

/**
 * @notice the SRC20 holder standard provides a common interface to query
 * token balance information
 */
interface ISRC20Holder is ISRC165 {
  /**
   * @notice emitted when the token is transferred to the contract
   * @param owner functional token owner
   * @param tokenAddress held token address
   * @param tokenAmount held token amount
   */
  event Hold(
    address indexed owner,
    address indexed tokenAddress,
    uint256 tokenAmount
  );

  /**
   * @notice emitted when the token is released back to the user
   * @param owner functional token owner
   * @param tokenAddress held token address
   * @param tokenAmount held token amount
   */
  event Release(
    address indexed owner,
    address indexed tokenAddress,
    uint256 tokenAmount
  );

  /**
   * @notice get the held balance of the token owner
   * @param tokenAddress held token address
   * @param owner functional token owner
   * @return held token balance
   */
  function heldBalanceOf(address tokenAddress, address owner)
    external
    view
    returns (uint256);
}
