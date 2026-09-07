// SPDX-License-Identifier: MIT
pragma solidity =0.8.16;

import { ISRC165 } from '@openzeppelin/contracts/utils/introspection/ISRC165.sol';
import { SRC20 } from '@openzeppelin/contracts/token/SRC20/SRC20.sol';
import { ISRC20 } from '@openzeppelin/contracts/token/SRC20/ISRC20.sol';
import { IAbstractToken, IAbstractSRC20, AbstractTokenMessage, AbstractTokenMessageStatus } from './IAbstractToken.sol';
import { AbstractToken } from './AbstractToken.sol';

contract AbstractSRC20 is ISRC165, AbstractToken, IAbstractSRC20, SRC20 {
  constructor(
    string memory _name,
    string memory _symbol,
    uint256 supply,
    address _signer
  ) SRC20(_name, _symbol) AbstractToken(_signer) {
    _mint(msg.sender, supply);
  }

  function _validMeta(bytes calldata metadata) internal pure override returns (bool) {
    /** SRC20 metadata
       - id: 0 - not applicable
       - amount: uint256 representing the number of tokens to mint on-chain
       - uri: empty string '' - not applicable
      */
    return metadata.length >= 32;
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return
      type(ISRC165).interfaceId == interfaceId ||
      type(ISRC20).interfaceId == interfaceId ||
      type(IAbstractSRC20).interfaceId == interfaceId ||
      type(IAbstractToken).interfaceId == interfaceId;
  }

  function id(AbstractTokenMessage calldata message) public pure returns (uint256) {
    require(_validMeta(message.meta), 'invalid metadata');
    revert('SRC20s have no id');
  }

  function amount(AbstractTokenMessage calldata message) public pure returns (uint256) {
    require(_validMeta(message.meta), 'invalid metadata');
    // the only metadata for SRC20 tokens is the amount
    return uint256(bytes32(message.meta));
  }

  function uri(AbstractTokenMessage calldata message) public pure returns (string calldata) {
    require(_validMeta(message.meta), 'invalid metadata');
    revert('SRC20s have no uri');
  }

  // transforms token(s) from message to contract
  function _reify(AbstractTokenMessage calldata message) internal override(AbstractToken) {
    // no permission checking! Callers must validate the message!
    _mint(message.owner, amount(message));
  }

  // transforms token(s) from contract to message
  function _dereify(AbstractTokenMessage calldata message) internal override(AbstractToken) {
    // no permission checking! Callers must validate the message!
    _burn(message.owner, amount(message));
  }

  function transfer(
    address to,
    uint256 _amount,
    AbstractTokenMessage calldata message
  ) external override returns (bool) {
    reify(message);
    return transfer(to, _amount);
  }

  // reify the message and then transferFrom tokens
  function transferFrom(
    address from,
    address to,
    uint256 _amount,
    AbstractTokenMessage calldata message
  ) external override returns (bool) {
    reify(message);
    return transferFrom(from, to, _amount);
  }
}
