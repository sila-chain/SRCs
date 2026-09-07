// SPDX-License-Identifier: CC0-1.0
pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/SRC721/SRC721.sol";
import "./ISRC721Consumable.sol";

contract SRC721Consumable is ISRC721Consumable, SRC721 {

    // Mapping from token ID to consumer address
    mapping(uint256 => address) _tokenConsumers;

    constructor (string memory name_, string memory symbol_) SRC721(name_, symbol_) {}

    /**
     * @dev Returns true if the `msg.sender` is approved, owner or consumer of the `tokenId`
     */
    function _isApprovedOwnerOrConsumer(uint256 tokenId) internal view returns (bool) {
        return _isApprovedOrOwner(msg.sender, tokenId) || _tokenConsumers[tokenId] == msg.sender;
    }

    /**
     * @dev See {ISRC721Consumable-consumerOf}
     */
    function consumerOf(uint256 _tokenId) view external returns (address) {
        require(_exists(_tokenId), "SRC721Consumable: consumer query for nonexistent token");
        return _tokenConsumers[_tokenId];
    }

    /**
     * @dev See {ISRC721Consumable-changeConsumer}
     */
    function changeConsumer(address _consumer, uint256 _tokenId) external {
        address owner = this.ownerOf(_tokenId);
        require(msg.sender == owner || msg.sender == getApproved(_tokenId) || isApprovedForAll(owner, msg.sender),
            "SRC721Consumable: changeConsumer caller is not owner nor approved");
        _changeConsumer(owner, _consumer, _tokenId);
    }

    /**
     * @dev See {ISRC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ISRC165, SRC721) returns (bool) {
        return interfaceId == type(ISRC721Consumable).interfaceId || super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(address _from, address _to, uint256 _tokenId) internal virtual override (SRC721) {
        super._beforeTokenTransfer(_from, _to, _tokenId);
        _changeConsumer(_from, address(0), _tokenId);
    }

    /**
     * @dev Changes the consumer
     * Requirement: `tokenId` must exist
     */
    function _changeConsumer(address _owner, address _consumer, uint256 _tokenId) internal {
        _tokenConsumers[_tokenId] = _consumer;
        emit ConsumerChanged(_owner, _consumer, _tokenId);
    }
}
