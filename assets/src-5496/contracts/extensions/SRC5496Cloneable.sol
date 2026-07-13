// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/SRC721/extensions/SRC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../SRC5496.sol";
import "./ISRC5496Cloneable.sol";

/**
 * @dev This implements an optional extension of {SRC721} defined in the SIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract SRC5496Cloneable is SRC5496, ISRC5496Cloneable {
    struct CloneableRecord {
        // account => shared
        mapping(address => bool) shared;
        // account => refer
        mapping(address => address) referrer;
    }

    // privId => isCloneable
    mapping(uint => bool) public cloneable;
    // tokenId => privId => CloneableRecord
    mapping(uint => mapping(uint => CloneableRecord)) cloneableSetting;

    function supportsInterface(bytes4 interfaceId) public override virtual view returns (bool) {
        return interfaceId == type(ISRC5496Cloneable).interfaceId || super.supportsInterface(interfaceId);
    }

    function hasPrivilege(
        uint256 tokenId,
        uint256 privId,
        address user
    ) public override virtual view returns(bool) {
        if ( privilegeBook[tokenId].privilegeEntry[privId].expiresAt >=  block.timestamp ){
            return cloneableSetting[tokenId][privId].shared[user] || super.hasPrivilege(tokenId, privId, user);
        }
        return ownerOf(tokenId) == user;
    }

    function clonePrivilege(uint tokenId, uint privId, address referrer) external returns (bool) {
        require(cloneable[privId], "privilege not cloneable");
        return _clonePrivilege(tokenId, privId, referrer);
    }

    function _clonePrivilege(uint tokenId, uint privId, address referrer) internal returns (bool) {
        require(privilegeBook[tokenId].privilegeEntry[privId].user == referrer || cloneableSetting[tokenId][privId].shared[referrer], "referrer not exists");
        if (cloneableSetting[tokenId][privId].referrer[msg.sender] == address(0)) {
            cloneableSetting[tokenId][privId].shared[msg.sender] = true;
            cloneableSetting[tokenId][privId].referrer[msg.sender] = referrer;
            emit PrivilegeCloned(tokenId, privId, referrer, msg.sender);
            return true;
        }
        return false;
    }    
}
