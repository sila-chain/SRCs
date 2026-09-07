// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/SRC1155/SRC1155.sol";
import "./ISRC5633.sol";

/**
 * @dev Extension of SRC1155 that adds soulbound property per token id.
 *
 */
abstract contract SRC5633 is SRC1155, ISRC5633 {
    mapping(uint256 => bool) private _soulbounds;
    
    /// @dev See {ISRC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId) public view virtual override(SRC1155) returns (bool) {
        return interfaceId == type(ISRC5633).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns true if a token type `id` is soulbound.
     */
    function isSoulbound(uint256 id) public view virtual returns (bool) {
        return _soulbounds[id];
    }

    function _setSoulbound(uint256 id, bool soulbound) internal {
        _soulbounds[id] = soulbound;
        emit Soulbound(id, soulbound);
    }

    /**
     * @dev See {SRC1155-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            if (isSoulbound(ids[i])) {
                require(
                    from == address(0) || to == address(0),
                    "SRC5633: Soulbound, Non-Transferable"
                );
            }
        }
    }
}