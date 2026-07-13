// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

import "./ISRC7066.sol";

/// @title SRC7066: Lockable Extension for SRC721
/// @dev Implementation for the Lockable extension SRC7066 for SRC721
/// @author StreamNFT 

abstract contract SRC7066 is SRC721,ISRC7066{


    /*///////////////////////////////////////////////////////////////
                            SRC7066 EXTENSION STORAGE                        
    //////////////////////////////////////////////////////////////*/

    //Mapping from tokenId to user address for locker
    mapping(uint256 => address) internal locker;

    /*///////////////////////////////////////////////////////////////
                              SRC7066 LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Returns the locker for the tokenId
     *      address(0) means token is not locked
     *      reverts if token does not exist
     */
    function lockerOf(uint256 tokenId) public virtual view override returns(address){
        require(_exists(tokenId), "SRC7066: Nonexistent token");
        return locker[tokenId];
    }

    /**
     * @dev Public function to lock the token. Verifies if the msg.sender is owner or approved
     *      reverts otherwise
     */
    function lock(uint256 tokenId) public virtual override{
        require(locker[tokenId]==address(0), "SRC7066: Locked");
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Require owner or approved");
        _lock(tokenId,msg.sender);
    }

    /**
     * @dev Public function to lock the token. Verifies if the msg.sender is owner
     *      reverts otherwise
     */
    function lock(uint256 tokenId, address _locker) public virtual override{
        require(locker[tokenId]==address(0), "SRC7066: Locked");
        require(ownerOf(tokenId)==msg.sender, "SRC7066: Require owner");
        _lock(tokenId,_locker);
    }

    /**
     * @dev Internal function to lock the token.
     */
    function _lock(uint256 tokenId, address _locker) internal {
        locker[tokenId]=_locker;
        emit Lock(tokenId, _locker);
    }

    /**
     * @dev Public function to unlock the token. Verifies the msg.sender is locker
     *      reverts otherwise
     */
    function unlock(uint256 tokenId) public virtual override{
        require(locker[tokenId]!=address(0), "SRC7066: Unlocked");
        require(locker[tokenId]==msg.sender);
        _unlock(tokenId);
    }

    /**
     * @dev Internal function to unlock the token. 
     */
    function _unlock(uint256 tokenId) internal{
        delete locker[tokenId];
        emit Unlock(tokenId);
    }

   /**
     * @dev Public function to tranfer and lock the token. Reverts if caller is not owner or approved.
     *      Lock the token and set locker to caller
     *.     Optionally approve caller if bool setApprove flag is true
     */
    function transferAndLock(address from, address to, uint256 tokenId, bool setApprove) public virtual override{
        _transferAndLock(tokenId,from,to,setApprove);
    }

    /**
     * @dev Internal function to tranfer, update locker/approve and lock the token.
     */
    function _transferAndLock(uint256 tokenId, address from, address to, bool setApprove) internal {
        transferFrom(from, to, tokenId); 
        if(setApprove){
            _approve(msg.sender, tokenId);
        }
        _lock(tokenId,msg.sender);
    }

    /*///////////////////////////////////////////////////////////////
                              OVERRIDES
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Override approve to make sure token is unlocked
     */
    function approve(address to, uint256 tokenId) public virtual override(ISRC721, SRC721) {
        require (locker[tokenId]==address(0), "SRC7066: Locked");
        super.approve(to, tokenId);
    }

    /**
     * @dev Override _beforeTokenTransfer to make sure token is unlocked or msg.sender is approved if 
     * token is lockApproved
     */
    function _beforeTokenTransfer( 
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
        // if it is a Transfer or Burn, we always deal with one token, that is startTokenId
        if (from != address(0)) { 
            require(locker[startTokenId]==address(0)
            || ( locker[startTokenId]==msg.sender && (isApprovedForAll(ownerOf(startTokenId), msg.sender) 
            || getApproved(startTokenId) == msg.sender)), "SRC7066: Locked" );
        }
        super._beforeTokenTransfer(from,to,startTokenId,quantity);
    }

    /**
     * @dev Override _afterTokenTransfer to make locker is purged
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
        // if it is a Transfer or Burn, we always deal with one token, that is startTokenId
        if (from != address(0)) { 
            delete locker[startTokenId];
        }
        super._afterTokenTransfer(from,to,startTokenId,quantity);
    }

     /*///////////////////////////////////////////////////////////////
                              SRC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev See {ISRC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ISRC165, SRC721) returns (bool) {
         return
            interfaceId == type(ISRC7066).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}