/*
Consumer

SPDX-License-Identifier: CC0-1.0
*/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/SRC721/ISRC721.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "./ISRC721Holder.sol";

/**
 * @title Consumer
 *
 * @notice this contract implements an example "consumer" of the proposed
 * held token SRC standard.
 
 * This example consumer contract will query SRC721 ownership and balances
 * including any "held" tokens
 */
contract Consumer {
  using Address for address;

  // members
  ISRC721 public token;

  /**
   * @param token_ address of SRC721 token
   */
  constructor(address token_) {
    token = ISRC721(token_);
  }

  /**
   * @notice get the functional owner of a token
   * @param tokenId token id of interest
   */
  function getOwner(uint256 tokenId) external view returns (address) {
    // get raw owner
    address owner = token.ownerOf(tokenId);

    // if owner is not contract, return
    if (!owner.isContract()) {
      return owner;
    }

    // check for token holder interface support
    try ISRC165(owner).supportsInterface(0x16b900ff) returns (bool ret) {
      if (!ret) return owner;
    } catch {
      return owner;
    }

    // check for held owner
    try ISRC721Holder(owner).heldOwnerOf(address(token), tokenId) returns (address user) {
      if (user != address(0)) return user;
    } catch {}

    return owner;
  }

  /**
   * @notice get the total user balance including held tokens
   * @param owner user address
   * @param holders list of token holder addresses
   */
  function getBalance(address owner, address[] calldata holders)
    external
    view
    returns (uint256)
  {
    // start with raw token balance
    uint256 balance = token.balanceOf(owner);

    // consider each provided token holder contract
    for (uint256 i = 0; i < holders.length; i++) {
      balance += ISRC721Holder(holders[i]).heldBalanceOf(address(token), owner);
    }

    return balance;
  }
}
