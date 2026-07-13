// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

import "./SRC3525.sol";
import "./interface/ISRC3525SlotApprovable.sol";

abstract contract SRC3525SlotApprovable is SRC3525, ISRC3525SlotApprovable {
    // @dev owner => slot => operator => approved
    mapping(address => mapping(uint256 => mapping(address => bool)))
        private _slotApprovals;

    function setApprovalForSlot( address owner_, uint256 slot_, address operator_, bool approved_) external payable virtual override {
        require(
            _msgSender() == owner_ || isApprovedForAll(owner_, _msgSender()),
            "SRC3525SlotApprovable: caller is not owner nor approved for all"
        );
        _setApprovalForSlot(owner_, slot_, operator_, approved_);
    }

    function isApprovedForSlot( address owner_, uint256 slot_, address operator_) public view virtual override returns (bool) {
        return _slotApprovals[owner_][slot_][operator_];
    }

    function approve(address to_, uint256 tokenId_) public virtual override(ISRC721, SRC721) {
        address owner = SRC721.ownerOf(tokenId_);
        uint256 slot = SRC3525.slotOf(tokenId_);
        require(to_ != owner, "SRC3525: approval to current owner");

        require(
            _msgSender() == owner ||
                SRC721.isApprovedForAll(owner, _msgSender()) ||
                SRC3525SlotApprovable.isApprovedForSlot(
                    owner,
                    slot,
                    _msgSender()
                ),
            "SRC3525: caller is not owner nor approved"
        );

        _approve(to_, tokenId_);
    }

    function approve(uint256 tokenId_, address to_, uint256 value_) external payable virtual override(ISRC3525, SRC3525) {
        address owner = SRC721.ownerOf(tokenId_);
        require(to_ != owner, "SRC3525: approval to current owner");

        require(
            _isApprovedOrOwner(_msgSender(), tokenId_),
            "SRC3525: caller is not owner nor approved"
        );

        _approveValue(tokenId_, to_, value_);
    }

    function _setApprovalForSlot( address owner_, uint256 slot_, address operator_, bool approved_) internal virtual {
        require(owner_ != operator_, "SRC3525SlotApprovable: approve to owner");
        _slotApprovals[owner_][slot_][operator_] = approved_;
        emit ApprovalForSlot(owner_, slot_, operator_, approved_);
    }

    function _isApprovedOrOwner(address operator_, uint256 tokenId_) internal view virtual override returns (bool) {
        require(
            _exists(tokenId_),
            "SRC3525: operator query for nonexistent token"
        );
        address owner = SRC721.ownerOf(tokenId_);
        uint256 slot = SRC3525.slotOf(tokenId_);
        return (operator_ == owner ||
            getApproved(tokenId_) == operator_ ||
            SRC721.isApprovedForAll(owner, operator_) ||
            SRC3525SlotApprovable.isApprovedForSlot(owner, slot, operator_));
    }
}
