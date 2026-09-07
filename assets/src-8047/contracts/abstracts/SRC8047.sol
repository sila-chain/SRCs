// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0 <0.9.0;

import {Forest} from "../libraries/Forest.sol";
import {ISRC5615} from "../interfaces/ISRC5615.sol";
import {ISRC8047} from "../interfaces/ISRC8047.sol";
import {ISRC1155} from "@openzeppelin/contracts/token/SRC1155/ISRC1155.sol";
import {ISRC1155Errors} from "@openzeppelin/contracts/interfaces/draft-ISRC6093.sol";
import {SRC1155Utils} from "@openzeppelin/contracts/token/SRC1155/utils/SRC1155Utils.sol";
import {ISRC165, SRC165} from "@openzeppelin/contracts/utils/introspection/SRC165.sol";

/**
 * @title SRC8047
 * @dev Abstract contract implementing SRC1155 functionalities with token management using the Forest library.
 * @notice This contract manages transactions in a forest-like structure using the Forest library.
 * @author Sirawit Techavanitch (sirawit_tec@live4.utcc.ac.th)
 */

abstract contract SRC8047 is SRC165, ISRC1155Errors, ISRC8047 {
    /** @custom:library */
    using Forest for Forest.DAG;

    /** @custom:storage */
    string private _uri;
    uint256 private _totalSupplyAll;

    mapping(uint256 => uint256) private _totalSupply;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    Forest.DAG private _dag;

    /** @custom:error */
    error InvalidValue();

    /** @custom:constructor */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /** @custom:function-private */
    /**
     * @dev helper function from openzeppelin implementation.
     */
    function _asSingletonArrays(
        uint256 element1,
        uint256 element2
    ) private pure returns (uint256[] memory array1, uint256[] memory array2) {
        assembly ("memory-safe") {
            // Load the free memory pointer
            array1 := mload(0x40)
            // Set array length to 1
            mstore(array1, 1)
            // Store the single element at the next word after the length (where content starts)
            mstore(add(array1, 0x20), element1)

            // Repeat for next array locating it right after the first array
            array2 := add(array1, 0x40)
            mstore(array2, 1)
            mstore(add(array2, 0x20), element2)

            // Update the free memory pointer by pointing after the second array
            mstore(0x40, add(array2, 0x40))
        }
    }

    /** @custom:function-internal */
    function _acceptanceCheck(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values,
        bytes memory data
    ) internal virtual {
        if (to != address(0)) {
            if (ids.length == 1) {
                SRC1155Utils.checkOnSRC1155Received(msg.sender, from, to, ids[0], values[0], data);
            } else {
                SRC1155Utils.checkOnSRC1155BatchReceived(msg.sender, from, to, ids, values, data);
            }
        }
    }

    function _mint(address to, uint256 value, bytes memory data) internal returns (uint256 id) {
        // createToken will auto generate new id.
        id = _dag.createToken(Token(0, 0, value, 0, to), address(0));
        _totalSupply[id] += value;
        _totalSupplyAll += value;

        emit TransferSingle(msg.sender, address(0), to, id, value);

        (uint256[] memory ids, uint256[] memory values) = _asSingletonArrays(id, value);
        _acceptanceCheck(address(0), to, ids, values, data);
    }

    function _mintBatch(address to, uint256[] memory values, bytes memory data) internal {
        if (to == address(0)) revert();
        uint256 valueLength = values.length;
        uint256 totalSupplyAll;
        uint256[] memory ids = new uint256[](valueLength);
        for (uint256 i = 0; i < valueLength; i++) {
            uint256 value = values[i];
            ids[i] = _dag.createToken(Token(0, 0, value, 0, to), address(0));

            totalSupplyAll += value;
        }
        _totalSupplyAll += totalSupplyAll;

        emit TransferBatch(msg.sender, address(0), to, ids, values);

        _acceptanceCheck(address(0), to, ids, values, data);
    }

    function _burn(address from, uint256 id, uint256 value) internal {
        _dag.spendToken(id, from, address(0), value);
        unchecked {
            _totalSupply[id] -= value;
            _totalSupplyAll -= value;
        }

        emit TransferSingle(msg.sender, from, address(0), id, value);
    }

    function _burnBatch(address from, uint256[] memory ids, uint256[] memory values) internal {
        if (ids.length != values.length) {
            revert SRC1155InvalidArrayLength(ids.length, values.length);
        }
        if (from == address(0)) {
            revert SRC1155InvalidSender(address(0));
        }
        uint256 totalSupplyAll = _totalSupplyAll;
        unchecked {
            for (uint256 i = 0; i < ids.length; ++i) {
                _dag.spendToken(ids[i], from, address(0), values[i]);
                totalSupplyAll -= values[i];
            }
        }
        _totalSupplyAll = totalSupplyAll;

        emit TransferBatch(msg.sender, from, address(0), ids, values);
    }

    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes memory data
    ) internal virtual {
        if (from == to) {
            revert SRC1155InvalidReceiver(to);
        }
        if (to == address(0)) {
            revert SRC1155InvalidReceiver(address(0));
        }
        if (from == address(0)) {
            revert SRC1155InvalidSender(address(0));
        }
        if (value == 0) {
            revert InvalidValue();
        }
        uint256 newId = _dag.spendToken(id, from, to, value);

        // parent value mutate.
        emit TransferSingle(msg.sender, from, address(0), id, value);
        // child creation.
        emit TransferSingle(msg.sender, address(0), to, newId, value);

        (uint256[] memory ids, uint256[] memory values) = _asSingletonArrays(id, value);
        _acceptanceCheck(address(0), to, ids, values, data);
    }

    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values,
        bytes memory data
    ) internal virtual {
        if (ids.length != values.length) {
            revert SRC1155InvalidArrayLength(ids.length, values.length);
        }
        if (from == to) {
            revert SRC1155InvalidReceiver(to);
        }
        if (to == address(0)) {
            revert SRC1155InvalidReceiver(address(0));
        }
        if (from == address(0)) {
            revert SRC1155InvalidSender(address(0));
        }

        uint256[] memory newIds = new uint256[](ids.length);

        for (uint256 i = 0; i < ids.length; ++i) {
            newIds[i] = _dag.spendToken(ids[i], from, to, values[i]);
        }

        // list of parent reduction in order.
        emit TransferBatch(msg.sender, from, address(0), ids, values);
        // list of child creation in order.
        emit TransferBatch(msg.sender, address(0), to, newIds, values);

        _acceptanceCheck(address(0), to, ids, values, data);
    }

    function _setApprovalForAll(address owner, address operator, bool approved) internal virtual {
        if (operator == address(0)) {
            revert SRC1155InvalidOperator(address(0));
        }
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function _setURI(string memory uri) internal virtual {
        _uri = uri;
        emit URI(uri, 0);
    }

    /** @custom:function-public */
    /** @dev See {ISRC1155.balanceOf}. */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        if (account == _dag.getTokenOwner(id)) {
            return _dag.getTokenValue(id);
        }
    }

    /** @dev See {ISRC1155.balanceOfBatch}. */
    function balanceOfBatch(
        address[] calldata accounts,
        uint256[] calldata ids
    ) public view virtual override returns (uint256[] memory) {
        if (accounts.length != ids.length) {
            revert SRC1155InvalidArrayLength(ids.length, accounts.length);
        }

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            if (accounts[i] == _dag.getTokenOwner(ids[i])) {
                batchBalances[i] = _dag.getTokenValue(ids[i]);
            }
        }

        return batchBalances;
    }

    /** @dev See {ISRC1155.isApprovedForAll}. */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /** @dev See {ISRC1155.uri}. */
    function uri(uint256 /** id */) public view returns (string memory) {
        return _uri;
    }

    /** @dev See {ISRC1155.safeTransferFrom}. */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes memory data
    ) public virtual override {
        address sender = msg.sender;
        if (from != sender && !isApprovedForAll(from, sender)) {
            revert SRC1155MissingApprovalForAll(sender, from);
        }
        _safeTransferFrom(from, to, id, value, data);
    }

    /** @dev See {ISRC1155.safeBatchTransferFrom}. */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values,
        bytes memory data
    ) public virtual override {
        address sender = msg.sender;
        if (from != sender && !isApprovedForAll(from, sender)) {
            revert SRC1155MissingApprovalForAll(sender, from);
        }
        _safeBatchTransferFrom(from, to, ids, values, data);
    }

    /** @dev See {ISRC1155.safeBatchTransferFrom}. */
    function setApprovalForAll(address operator, bool approved) public virtual {
        _setApprovalForAll(msg.sender, operator, approved);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(SRC165, ISRC165) returns (bool) {
        return
            interfaceId == type(ISRC1155).interfaceId ||
            interfaceId == type(ISRC5615).interfaceId ||
            interfaceId == type(ISRC8047).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /** @dev See {ISRC5615-exists}. */
    function exists(uint256 id) external view returns (bool) {
        return _dag.contains(id);
    }

    /** @dev See {ISRC5615-totalSupply}. */
    function totalSupply(uint256 id) public view returns (uint256) {
        return _dag.getTokenValue(id);
    }

    /** @dev See {ISRC8047-latestDAGDepthOf}. */
    function latestDAGDepthOf(uint256 id) public view returns (uint256) {
        return _dag.getTokenHierarchy(id);
    }

    /** @dev See {ISRC8047-depthOf}. */
    function depthOf(uint256 id) public view returns (uint256) {
        return _dag.getTokenDepth(id);
    }

    /** @dev See {ISRC8047-ownerOf}. */
    function ownerOf(uint256 id) public view returns (address) {
        return _dag.getTokenOwner(id);
    }

    /** @dev See {ISRC8047-parentOf}. */
    function parentOf(uint256 id) public view returns (uint256) {
        return _dag.getTokenParent(id);
    }

    /** @dev See {ISRC8047-rootOf}. */
    function rootOf(uint256 id) public view returns (uint256) {
        return _dag.getTokenRoot(id);
    }

    /** @dev See {ISRC8047-token}. */
    function token(uint256 id) public view returns (Token memory) {
        return _dag.getToken(id);
    }

    /** @dev See {ISRC8047-totalSupply}. */
    function totalSupply() public view returns (uint256) {
        return _totalSupplyAll;
    }
}
