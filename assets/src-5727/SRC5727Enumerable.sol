//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./SRC5727.sol";
import "./interfaces/ISRC5727Enumerable.sol";
import "../SRC3525/SRC3525SlotEnumerable.sol";

abstract contract SRC5727Enumerable is
    ISRC5727Enumerable,
    SRC5727,
    SRC3525SlotEnumerable
{
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableMap for EnumerableMap.AddressToUintMap;

    mapping(address => EnumerableSet.UintSet) private _slotsOfOwner;

    mapping(uint256 => EnumerableMap.AddressToUintMap)
        private _ownerBalanceInSlot;

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ISRC165, SRC3525, SRC5727) returns (bool) {
        return
            interfaceId == type(ISRC5727Enumerable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function slotCountOfOwner(
        address owner
    ) external view override returns (uint256) {
        if (owner == address(0)) revert NullValue();

        return _slotsOfOwner[owner].length();
    }

    function slotOfOwnerByIndex(
        address owner,
        uint256 index
    ) external view override returns (uint256) {
        if (owner == address(0)) revert NullValue();
        uint256 slotCountByOwner = _slotsOfOwner[owner].length();
        if (index >= slotCountByOwner)
            revert IndexOutOfBounds(index, slotCountByOwner);

        return _slotsOfOwner[owner].at(index);
    }

    function ownerBalanceInSlot(
        address owner,
        uint256 slot
    ) external view returns (uint256) {
        if (owner == address(0)) revert NullValue();
        if (!_slotExists(slot)) revert NotFound(slot);

        return _ownerBalanceInSlot[slot].get(owner);
    }

    function _incrementOwnerBalanceInSlot(
        address owner,
        uint256 slot
    ) internal virtual {
        if (owner == address(0)) revert NullValue();

        (, uint256 balanceInSlot) = _ownerBalanceInSlot[slot].tryGet(owner);
        unchecked {
            _ownerBalanceInSlot[slot].set(owner, balanceInSlot + 1);
        }
    }

    function _decrementOwnerBalanceInSlot(
        address owner,
        uint256 slot
    ) internal virtual {
        if (owner == address(0)) revert NullValue();

        uint256 balanceInSlot = _ownerBalanceInSlot[slot].get(owner);
        unchecked {
            _ownerBalanceInSlot[slot].set(owner, balanceInSlot - 1);
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual override(SRC721Enumerable, SRC5727) {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
    }

    function _burn(
        uint256 tokenId
    ) internal virtual override(SRC3525, SRC5727) {
        SRC5727._burn(tokenId);
    }

    function _beforeValueTransfer(
        address from,
        address to,
        uint256 fromTokenId,
        uint256 toTokenId,
        uint256 slot,
        uint256 value
    ) internal virtual override(SRC3525SlotEnumerable, SRC5727) {
        super._beforeValueTransfer(
            from,
            to,
            fromTokenId,
            toTokenId,
            slot,
            value
        );

        if (from == address(0) && fromTokenId == 0) {
            _incrementOwnerBalanceInSlot(to, slot);

            _slotsOfOwner[to].add(slot);
        }

        value;
    }

    function _afterValueTransfer(
        address from,
        address to,
        uint256 fromTokenId,
        uint256 toTokenId,
        uint256 slot,
        uint256 value
    ) internal virtual override(SRC3525SlotEnumerable, SRC3525) {
        super._afterValueTransfer(
            from,
            to,
            fromTokenId,
            toTokenId,
            slot,
            value
        );

        if (to == address(0) && toTokenId == 0) {
            _decrementOwnerBalanceInSlot(from, slot);

            if (_ownerBalanceInSlot[slot].get(from) == 0) {
                _slotsOfOwner[from].remove(slot);
            }
        }

        value;
    }
}
