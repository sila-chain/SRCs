// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0; 

import "@openzeppelin/contracts/token/SRC721/SRC721.sol";
import "./ISRC5334.sol";

contract SRC5334 is SRC721, ISRC5334 {
    struct UserInfo 
    {
        address user;   // address of user role
        uint64 expires; // unix timestamp, user expires
        uint8 level; // user level
    }

    mapping (uint256  => UserInfo) internal _users;

    constructor(string memory name_, string memory symbol_)
     SRC721(name_,symbol_)
     {         
     }
    
    /// @notice set the user and expires and level of a NFT
    /// @dev The zero address indicates there is no user 
    /// Throws if `tokenId` is not valid NFT
    /// @param user  The new user of the NFT
    /// @param expires  UNIX timestamp, The new user could use the NFT before expires
    /// @param level user level
    function setUser(uint256 tokenId, address user, uint64 expires, uint8 level) public virtual{
        require(_isApprovedOrOwner(msg.sender, tokenId),"SRC721: transfer caller is not owner nor approved");
        UserInfo storage info =  _users[tokenId];
        info.user = user;
        info.expires = expires;
        info.level = level
        emit UpdateUser(tokenId,user,expires,level);
    }

    /// @notice Get the user address of an NFT
    /// @dev The zero address indicates that there is no user or the user is expired
    /// @param tokenId The NFT to get the user address for
    /// @return The user address for this NFT
    function userOf(uint256 tokenId)public view virtual returns(address){
        if( uint256(_users[tokenId].expires) >=  block.timestamp){
            return  _users[tokenId].user; 
        }
        else{
            return address(0);
        }
    }

    /// @notice Get the user expires of an NFT
    /// @dev The zero value indicates that there is no user 
    /// @param tokenId The NFT to get the user expires for
    /// @return The user expires for this NFT
    function userExpires(uint256 tokenId) public view virtual returns(uint256){
        return _users[tokenId].expires;
    }

    /// @notice Get the user level of an NFT
    /// @dev The zero value indicates that there is no user 
    /// @param tokenId The NFT to get the user level for
    /// @return The user level for this NFT
    function userLevel(uint256 tokenId) public view virtual returns(uint256){
        return _users[tokenId].level;
    }

    /// @dev See {ISRC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(ISRC5334).interfaceId || super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override{
        super._beforeTokenTransfer(from, to, tokenId);

        if (from != to && _users[tokenId].user != address(0)) {
            delete _users[tokenId];
            emit UpdateUser(tokenId, address(0), 0, 0);
        }
    }
} 

