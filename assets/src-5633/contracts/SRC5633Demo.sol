// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/SRC1155/SRC1155.sol";
import "@openzeppelin/contracts/token/SRC1155/extensions/SRC1155Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./SRC5633.sol";

contract SRC5633Demo is SRC1155, SRC1155Burnable, Ownable, SRC5633 {
    constructor() SRC1155("") SRC5633() {}

    function mint(address account, uint256 id, uint256 amount, bytes memory data)
        public
        onlyOwner
    {
        _mint(account, id, amount, data);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        public
        onlyOwner
    {
        _mintBatch(to, ids, amounts, data);
    }

    function setSoulbound(uint256 id, bool soulbound) 
        public
        onlyOwner 
    {
        _setSoulbound(id, soulbound);
    }

    // The following functions are overrides required by Solidity.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(SRC1155, SRC5633)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
    
    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        override(SRC1155, SRC5633)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function getInterfaceId() public view returns (bytes4) {
        return type(ISRC5633).interfaceId;
    }
}
