//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/SRC721/extensions/ISRC721Enumerable.sol";

import "../../SRC3525/interfaces/ISRC3525SlotEnumerable.sol";
import "./ISRC5727.sol";

/**
 * @title SRC5727 Soulbound Token Enumerable Interface
 * @dev This extension allows querying the tokens of a owner.
 */
interface ISRC5727Enumerable is ISRC3525SlotEnumerable, ISRC5727 {
    /**
     * @notice Get the number of slots of a owner.
     * @param owner The owner whose number of slots is queried for
     * @return The number of slots of the `owner`
     */
    function slotCountOfOwner(address owner) external view returns (uint256);

    /**
     * @notice Get the slot with `index` of the `owner`.
     * @dev MUST revert if the `index` exceed the number of slots of the `owner`.
     * @param owner The owner whose slot is queried for.
     * @param index The index of the slot queried for
     * @return The slot is queried for
     */
    function slotOfOwnerByIndex(
        address owner,
        uint256 index
    ) external view returns (uint256);

    /**
     * @notice Get the balance of a owner in a slot.
     * @dev MUST revert if the slot does not exist.
     * @param owner The owner whose balance is queried for
     * @param slot The slot whose balance is queried for
     * @return The balance of the `owner` in the `slot`
     */
    function ownerBalanceInSlot(
        address owner,
        uint256 slot
    ) external view returns (uint256);
}
