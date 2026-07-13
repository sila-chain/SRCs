// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Authors: Francesco Sullo <francesco@sullo.co>

import "@openzeppelin/contracts/token/SRC721/SRC721.sol";
import "@openzeppelin/contracts/token/SRC721/extensions/SRC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ISRC721Lockable.sol";
import "./ISRC6982.sol";

// This is an example of lockable SRC721 using ISRC6982 as basic interface

contract SRC721Lockable is ISRC6982, ISRC721Lockable, Ownable, SRC721, SRC721Enumerable {
  using Address for address;

  mapping(address => bool) private _locker;
  mapping(uint256 => address) private _lockedBy;

  bool internal _defaultLocked;

  modifier onlyLocker() {
    require(_locker[_msgSender()], "Not a locker");
    _;
  }

  constructor(
    string memory name,
    string memory symbol,
    bool defaultLocked_
  ) SRC721(name, symbol) {
    updateDefaultLocked(defaultLocked_);
  }

  function defaultLocked() external view override returns (bool) {
    return _defaultLocked;
  }

  function updateDefaultLocked(bool defaultLocked_) public onlyOwner {
    _defaultLocked = defaultLocked_;
    emit DefaultLocked(defaultLocked_);
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId,
    uint256 batchSize
  ) internal override(SRC721, SRC721Enumerable) {
    require(
      // during minting
      from == address(0) ||
        // later
        !locked(tokenId),
      "Token is locked"
    );
    super._beforeTokenTransfer(from, to, tokenId, batchSize);
  }

  function supportsInterface(bytes4 interfaceId) public view override(SRC721, SRC721Enumerable) returns (bool) {
    return
      interfaceId == type(ISRC6982).interfaceId ||
      interfaceId == type(ISRC721Lockable).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  function locked(uint256 tokenId) public view virtual override returns (bool) {
    require(_exists(tokenId), "Token does not exist");
    return _lockedBy[tokenId] != address(0);
  }

  function lockerOf(uint256 tokenId) public view virtual override returns (address) {
    return _lockedBy[tokenId];
  }

  function isLocker(address locker) public view virtual override returns (bool) {
    return _locker[locker];
  }

  function setLocker(address locker) external virtual override onlyOwner {
    require(locker.isContract(), "Locker not a contract");
    _locker[locker] = true;
    emit LockerSet(locker);
  }

  function removeLocker(address locker) external virtual override onlyOwner {
    require(_locker[locker], "Not an active locker");
    delete _locker[locker];
    emit LockerRemoved(locker);
  }

  function hasLocks(address owner) public view virtual override returns (bool) {
    uint256 balance = balanceOf(owner);
    for (uint256 i = 0; i < balance; i++) {
      uint256 id = tokenOfOwnerByIndex(owner, i);
      if (locked(id)) {
        return true;
      }
    }
    return false;
  }

  function lock(uint256 tokenId) external virtual override onlyLocker {
    // locker must be approved to mark the token as locked
    require(isLocker(_msgSender()), "Not an authorized locker");
    require(getApproved(tokenId) == _msgSender() || isApprovedForAll(ownerOf(tokenId), _msgSender()), "Locker not approved");
    _lockedBy[tokenId] = _msgSender();
    emit Locked(tokenId, true);
  }

  function unlock(uint256 tokenId) external virtual override onlyLocker {
    // will revert if token does not exist
    require(_lockedBy[tokenId] == _msgSender(), "Wrong locker");
    delete _lockedBy[tokenId];
    emit Locked(tokenId, false);
  }

  // emergency function in case a compromised locker is removed
  function unlockIfRemovedLocker(uint256 tokenId) external virtual override {
    require(locked(tokenId), "Not a locked tokenId");
    require(!_locker[_lockedBy[tokenId]], "Locker is still active");
    require(ownerOf(tokenId) == _msgSender(), "Not the asset owner");
    delete _lockedBy[tokenId];
    emit ForcefullyUnlocked(tokenId);
  }

  // manage approval

  function approve(address to, uint256 tokenId) public virtual override(ISRC721, SRC721) {
    require(!locked(tokenId), "Locked asset");
    super.approve(to, tokenId);
  }

  function getApproved(uint256 tokenId) public view virtual override(ISRC721, SRC721) returns (address) {
    if (locked(tokenId) && lockerOf(tokenId) != _msgSender()) {
      return address(0);
    }
    return super.getApproved(tokenId);
  }

  function setApprovalForAll(address operator, bool approved) public virtual override(ISRC721, SRC721) {
    require(!approved || !hasLocks(_msgSender()), "At least one asset is locked");
    super.setApprovalForAll(operator, approved);
  }

  function isApprovedForAll(address owner, address operator) public view virtual override(ISRC721, SRC721) returns (bool) {
    if (hasLocks(owner)) {
      return false;
    }
    return super.isApprovedForAll(owner, operator);
  }
}
