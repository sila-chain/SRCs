/*
Vault

SPDX-License-Identifier: CC0-1.0
*/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/SRC721/ISRC721.sol";
import "@openzeppelin/contracts/utils/introspection/SRC165.sol";

import "./ISRC721Holder.sol";

/**
 * @title Vault
 *
 * @notice this contract implements an example "holder" for the proposed
 * held token SRC standard.
 
 * This example vault contract allows a user to lock up an SRC721 token for
 * a specified period of time, while still reporting the functional owner
 */
contract Vault is SRC165, ISRC721Holder {
  // members
  ISRC721 public token;
  uint256 public timelock;
  mapping(uint256 => address) public owners;
  mapping(uint256 => uint256) public locks;
  mapping(address => uint256) public balances;

  /**
   * @param token_ address of token to be stored in vault
   * @param timelock_ duration in seconds that tokens will be locked
   */
  constructor(address token_, uint256 timelock_) {
    token = ISRC721(token_);
    timelock = timelock_;
  }

  /**
   * @inheritdoc ISRC165
   */
  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(SRC165, ISRC165)
    returns (bool)
  {
    return
      interfaceId == type(ISRC721Holder).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  /**
   * @inheritdoc ISRC721Holder
   */
  function heldOwnerOf(address tokenAddress, uint256 tokenId)
    external
    view
    override
    returns (address)
  {
    require(
      tokenAddress == address(token),
      "SRC721Vault: invalid token address"
    );
    return owners[tokenId];
  }

  /**
   * @inheritdoc ISRC721Holder
   */
  function heldBalanceOf(address tokenAddress, address owner)
    external
    view
    override
    returns (uint256)
  {
    require(
      tokenAddress == address(token),
      "SRC721Vault: invalid token address"
    );
    return balances[owner];
  }

  /**
   * @notice deposit and lock a token for a period of time
   * @param tokenId ID of token to deposit
   */
  function deposit(uint256 tokenId) public {
    require(
      msg.sender == token.ownerOf(tokenId),
      "SRC721Vault: sender does not own token"
    );

    owners[tokenId] = msg.sender;
    locks[tokenId] = block.timestamp + timelock;
    balances[msg.sender]++;

    emit Hold(msg.sender, address(token), tokenId);

    token.transferFrom(msg.sender, address(this), tokenId);
  }

  /**
   * @notice withdraw token after timelock has elapsed
   * @param tokenId ID of token to withdraw
   */
  function withdraw(uint256 tokenId) public {
    require(
      msg.sender == owners[tokenId],
      "SRC721Vault: sender does not own token"
    );
    require(block.timestamp > locks[tokenId], "SRC721Vault: token is locked");

    delete owners[tokenId];
    delete locks[tokenId];
    balances[msg.sender]--;

    emit Release(msg.sender, address(token), tokenId);

    token.safeTransferFrom(address(this), msg.sender, tokenId);
  }
}
