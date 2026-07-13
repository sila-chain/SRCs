// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.21;

import "ISRC1155.sol";
import "SRC1155.sol";

/**
 * @title SRC-1155 Allowance Extension
 * Note: the SRC-165 identifier for this interface is 0x1be07d74
 */
interface ISRC5216 is ISRC1155 {

    /**
     * @notice Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `id` and with an amount: `amount`.
     */
    event Approval(address indexed account, address indexed operator, uint256 id, uint256 amount);

    /**
     * @notice Grants permission to `operator` to transfer the caller's tokens, according to `id`, and an amount: `amount`.
     * Emits an {Approval} event.
     *
     * Requirements:
     * - `operator` cannot be the caller.
     */
    function approve(address operator, uint256 id, uint256 amount) external;

    /**
     * @notice Returns the amount allocated to `operator` approved to transfer `account`'s tokens, according to `id`.
     */
    function allowance(address account, address operator, uint256 id) external view returns (uint256);
}

/**
 * @dev Extension of {SRC1155} that allows you to approve your tokens by amount and id.
 */
abstract contract SRC5216 is SRC1155, ISRC5216 {

    // Mapping from account to operator approvals by id and amount.
    mapping(address => mapping(address => mapping(uint256 => uint256))) internal _allowances;

    /**
     * @dev See {ISRC5216}
     */
    function approve(address operator, uint256 id, uint256 amount) public virtual {
        _approve(msg.sender, operator, id, amount);
    }

    /**
     * @dev See {ISRC5216}
     */
    function allowance(address account, address operator, uint256 id) public view virtual returns (uint256) {
        return _allowances[account][operator][id];
    }

    /**
     * @dev safeTransferFrom implementation for using allowance extension
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public override(ISRC1155, SRC1155) {
        require(
            from == msg.sender || isApprovedForAll(from, msg.sender) || allowance(from, msg.sender, id) >= amount,
            "SRC1155: caller is not owner nor approved nor approved for amount"
        );
        unchecked {
            _allowances[from][msg.sender][id] -= amount;
        }
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev safeBatchTransferFrom implementation for using allowance extension
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override(ISRC1155, SRC1155) {
        require(
            from == msg.sender || isApprovedForAll(from, msg.sender) || _checkApprovalForBatch(from, msg.sender, ids, amounts),
            "SRC1155: transfer caller is not owner nor approved nor approved for some amount"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Checks if all ids and amounts are permissioned for `to`. 
     *
     * Requirements:
     * - `ids` and `amounts` length should be equal.
     */
    function _checkApprovalForBatch(
        address from, 
        address to, 
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual returns (bool) {
        uint256 idsLength = ids.length;
        uint256 amountsLength = amounts.length;

        require(idsLength == amountsLength, "SRC5216: ids and amounts length mismatch");
        for (uint256 i = 0; i < idsLength;) {
            require(allowance(from, to, ids[i]) >= amounts[i], "SRC5216: operator is not approved for that id or amount");
            unchecked { 
                _allowances[from][to][ids[i]] -= amounts[i];
                ++i; 
            }
        }
        return true;
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens by id and amount.
     * Emits a {Approval} event.
     */
    function _approve(
        address owner,
        address operator,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(owner != operator, "SRC5216: setting approval status for self");
        _allowances[owner][operator][id] = amount;
        emit Approval(owner, operator, id, amount);
    }
}

contract ExampleToken is SRC5216 {
    constructor() SRC1155("") {}

    function mint(address account, uint256 id, uint256 amount, bytes memory data) public {
        _mint(account, id, amount, data);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) public {
        _mintBatch(to, ids, amounts, data);
    }
}
