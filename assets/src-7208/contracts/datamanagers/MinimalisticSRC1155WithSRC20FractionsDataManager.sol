// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Arrays} from "@openzeppelin/contracts/utils/Arrays.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {SRC165, ISRC165} from "@openzeppelin/contracts/utils/introspection/SRC165.sol";
import {ISRC1155} from "@openzeppelin/contracts/token/SRC1155/ISRC1155.sol";
import {ISRC1155MetadataURI} from "@openzeppelin/contracts/token/SRC1155/extensions/ISRC1155MetadataURI.sol";
import {ISRC1155Receiver} from "@openzeppelin/contracts/token/SRC1155/ISRC1155Receiver.sol";
import {ISRC1155Errors} from "@openzeppelin/contracts/interfaces/draft-ISRC6093.sol";
import {IDataIndex} from "../interfaces/IDataIndex.sol";
import {IDataObject} from "../interfaces/IDataObject.sol";
import {MinimalisticSRC20FractionDataManagerFactory} from "./MinimalisticSRC20FractionDataManagerFactory.sol";
import {MinimalisticSRC20FractionDataManager} from "./MinimalisticSRC20FractionDataManager.sol";
import {IFractionTransferEventEmitter} from "../interfaces/IFractionTransferEventEmitter.sol";
import {DataPoint} from "../utils/DataPoints.sol";
import {IFungibleFractionsOperations} from "../interfaces/IFungibleFractionsOperations.sol";

/**
 * @title Minimalistic SRC1155 With SRC20 Fractions Data Manager
 * @notice Contract for managing SRC1155 tokens with SRC20 fractions
 * @dev This contract is used to manage SRC1155 tokens where each token ID can be treated as an SRC20 token
 *      by deploying a SRC20FractionDataManager contract for each token ID.
 *
 *      Deployment process:
 *      1. Allocate DataPoint via IDataPointRegistry.allocate()
 *      2. Deploy SRC1155WithSRC20FractionsDataManager (or an extending contract)
 *      3. Grant Admin role on the DataPoint to the deployed contract
 */
contract MinimalisticSRC1155WithSRC20FractionsDataManager is
    IFractionTransferEventEmitter,
    ISRC1155,
    ISRC1155Errors,
    ISRC1155MetadataURI,
    SRC165,
    Ownable,
    ReentrancyGuard
{
    using Arrays for uint256[];

    /// @dev Error thrown when the parameters are wrong
    error WrongParameters();

    /// @dev Error thrown when the SRC1155 token ID is zero
    error IncorrectId(uint256 id);

    /// @notice Event emitted when a SRC20FractionDataManager contract is deployed
    event SRC20FractionDataManagerDeployed(uint256 id, address dm);

    /// @notice Event emitted when the default URI is set
    event DefaultURISet(string defaultURI);

    /// @dev DataPoint used in the fungibleFractions data object
    DataPoint internal immutable _datapoint;

    /// @dev Fungible Fractions Data Object contract
    IDataObject public immutable fungibleFractionsDO;

    /// @dev Data Index implementation
    IDataIndex public immutable dataIndex;

    /// @dev SRC20FractionDataManager factory contract
    MinimalisticSRC20FractionDataManagerFactory public immutable src20FractionsDMFactory;

    /// @dev Name of the SRC1155 token
    string private _name;

    /// @dev Symbol of the SRC1155 token
    string private _symbol;

    /// @dev Default URI for token types
    string private _defaultURI = "";

    /// @dev Mapping of approvals state for an address to an operator
    mapping(address account => mapping(address operator => bool)) private _operatorApprovals;

    /// @dev Mapping of SRC20FractionDataManager contract address by token ID
    mapping(uint256 id => address src20dm) public fractionManagersById;

    /// @dev Mapping of token ID by SRC20FractionDataManager contract address
    mapping(address src20dm => uint256 id) public fractionManagersByAddress;

    /// @notice Modifier to check if the caller is the minter
    modifier onlyMinter() {
        _checkMinter();
        _;
    }

    /// @dev Set up the SRC1155 token with initial data and roles
    constructor(
        bytes32 _dp,
        address _dataIndex,
        address _fungibleFractionsDO,
        address _src20FractionsDMFactory,
        string memory name_,
        string memory symbol_
    ) Ownable(msg.sender) {
        if (_dp == bytes32(0) || _dataIndex == address(0) || _fungibleFractionsDO == address(0) || _src20FractionsDMFactory == address(0)) {
            revert WrongParameters();
        }

        _name = name_;
        _symbol = symbol_;
        _datapoint = DataPoint.wrap(_dp);
        dataIndex = IDataIndex(_dataIndex);
        fungibleFractionsDO = IDataObject(_fungibleFractionsDO);
        src20FractionsDMFactory = MinimalisticSRC20FractionDataManagerFactory(_src20FractionsDMFactory);
    }

    /// @inheritdoc ISRC165
    function supportsInterface(bytes4 interfaceId) public view virtual override(ISRC165, SRC165) returns (bool) {
        return interfaceId == type(ISRC1155).interfaceId || interfaceId == type(ISRC1155MetadataURI).interfaceId || super.supportsInterface(interfaceId);
    }

    /// @notice Set a new Default URI
    function setDefaultURI(string calldata defaultURI) external onlyOwner {
        _setDefaultURI(defaultURI);
    }

    /**
     * @notice Total supply of the SRC1155 token
     * @return The amount of tokens in existence
     * @dev This function is used to get the total supply of the SRC1155 token considering all token IDs
     */
    function totalSupply() public view returns (uint256) {
        return abi.decode(fungibleFractionsDO.read(_datapoint, IFungibleFractionsOperations.totalSupplyAll.selector, ""), (uint256));
    }

    /**
     * @notice Total supply of the SRC1155 token by ID
     * @param id The token ID
     * @return The amount of tokens in existence for the given token ID
     */
    function totalSupply(uint256 id) public view returns (uint256) {
        return abi.decode(fungibleFractionsDO.read(_datapoint, IFungibleFractionsOperations.totalSupply.selector, abi.encode(id)), (uint256));
    }

    /**
     * @notice Balance of an account
     * @param account The account to check the balance of
     * @param id The token ID
     * @return The amount of tokens the account has for the given token ID
     */
    function balanceOf(address account, uint256 id) public view returns (uint256) {
        return abi.decode(fungibleFractionsDO.read(_datapoint, IFungibleFractionsOperations.balanceOf.selector, abi.encode(account, id)), (uint256));
    }

    /**
     * @notice Balance of multiple accounts for multiple token IDs
     * @param accounts The accounts to check the balance of
     * @param ids The token IDs
     * @return The amounts of tokens each account has for respective token IDs
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids) public view returns (uint256[] memory) {
        return
            abi.decode(
                fungibleFractionsDO.read(_datapoint, IFungibleFractionsOperations.balanceOfBatchAccounts.selector, abi.encode(accounts, ids)),
                (uint256[])
            );
    }

    /**
     * @notice Get the URI for a token ID
     * @return The URI for the given token ID
     */
    function uri(uint256) public view virtual returns (string memory) {
        return _defaultURI;
    }

    /**
     * @notice Get the name of the SRC1155 token
     * @return The name of the token
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @notice Get the symbol of the SRC1155 token
     * @return The symbol of the token
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /// @inheritdoc ISRC1155
    function setApprovalForAll(address operator, bool approved) public virtual {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /// @inheritdoc ISRC1155
    function isApprovedForAll(address account, address operator) public view virtual returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev Approve `operator` to operate on all of `tokenOwner` tokens
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the zero address.
     */
    function _setApprovalForAll(address tokenOwner, address operator, bool approved) internal virtual {
        if (operator == address(0)) {
            revert SRC1155InvalidOperator(address(0));
        }
        _operatorApprovals[tokenOwner][operator] = approved;
        emit ApprovalForAll(tokenOwner, operator, approved);
    }

    /// @inheritdoc ISRC1155
    function safeTransferFrom(address from, address to, uint256 id, uint256 value, bytes calldata data) public virtual {
        address sender = _msgSender();
        if (from != sender && !isApprovedForAll(from, sender)) {
            revert SRC1155MissingApprovalForAll(sender, from);
        }
        _safeTransferFrom(from, to, id, value, data);
    }

    /// @inheritdoc ISRC1155
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata values, bytes calldata data) external virtual {
        address sender = _msgSender();
        if (from != sender && !isApprovedForAll(from, sender)) {
            revert SRC1155MissingApprovalForAll(sender, from);
        }
        _safeBatchTransferFrom(from, to, ids, values, data);
    }

    /**
     * @dev Transfers a `value` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `value` amount.
     * - If `to` refers to a smart contract, it must implement {ISRC1155Receiver-onSRC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(address from, address to, uint256 id, uint256 value, bytes memory data) internal {
        if (to == address(0)) {
            revert SRC1155InvalidReceiver(address(0));
        }
        if (from == address(0)) {
            revert SRC1155InvalidSender(address(0));
        }
        _updateWithAcceptanceCheck(from, to, id, value, data);
    }

    /**
     * @dev xref:ROOT:src1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {ISRC1155Receiver-onSRC1155BatchReceived} and return the
     * acceptance magic value.
     * - `ids` and `values` must have the same length.
     */
    function _safeBatchTransferFrom(address from, address to, uint256[] memory ids, uint256[] memory values, bytes memory data) internal {
        if (ids.length != values.length) {
            revert SRC1155InvalidArrayLength(ids.length, values.length);
            // DO NOT remove this check without refactoring SRC1155WithSRC20FractionsDataManager._update() which relies on it!
        }

        if (to == address(0)) {
            revert SRC1155InvalidReceiver(address(0));
        }
        if (from == address(0)) {
            revert SRC1155InvalidSender(address(0));
        }
        if (ids.length == 1 && values.length == 1) {
            uint256 id = ids.unsafeMemoryAccess(0);
            uint256 value = values.unsafeMemoryAccess(0);
            _updateWithAcceptanceCheck(from, to, id, value, data);
        } else {
            _updateWithAcceptanceCheck(from, to, ids, values, data);
        }
    }

    /**
     * @dev Version of {_update} that performs the token acceptance check by calling
     * {ISRC1155Receiver-onSRC1155Received} or {ISRC1155Receiver-onSRC1155BatchReceived} on the receiver address if it
     * contains code (eg. is a smart contract at the moment of execution).
     *
     * IMPORTANT: Overriding this function is discouraged because it poses a reentrancy risk from the receiver. So any
     * update to the contract state after this function would break the check-effect-interaction pattern. Consider
     * overriding {_update} instead.
     */
    function _updateWithAcceptanceCheck(address from, address to, uint256 id, uint256 value, bytes memory data) internal virtual {
        _update(from, to, id, value);
        if (to != address(0)) {
            address operator = _msgSender();
            _doSafeTransferAcceptanceCheck(operator, from, to, id, value, data);
        }
    }

    /**
     * @dev Version of {_update} that performs the token acceptance check by calling
     * {ISRC1155Receiver-onSRC1155Received} or {ISRC1155Receiver-onSRC1155BatchReceived} on the receiver address if it
     * contains code (eg. is a smart contract at the moment of execution).
     *
     * IMPORTANT: Overriding this function is discouraged because it poses a reentrancy risk from the receiver. So any
     * update to the contract state after this function would break the check-effect-interaction pattern. Consider
     * overriding {_update} instead.
     */
    function _updateWithAcceptanceCheck(address from, address to, uint256[] memory ids, uint256[] memory values, bytes memory data) internal virtual {
        _update(from, to, ids, values);
        if (to != address(0)) {
            address operator = _msgSender();
            _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, values, data);
        }
    }

    /**
     * @dev Transfers a `value` amount of tokens of type `id` from `from` to `to`. Will mint (or burn) if `from`
     * (or `to`) is the zero address.
     *
     * Emits a {TransferSingle} event if the arrays contain one element, and {TransferBatch} otherwise.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement either {ISRC1155Receiver-onSRC1155Received}
     *   or {ISRC1155Receiver-onSRC1155BatchReceived} and return the acceptance magic value.
     * - `ids` and `values` must have the same length.
     *
     * NOTE: The SRC-1155 acceptance check is not performed in this function. See {_updateWithAcceptanceCheck} instead.
     */
    function _updateInternal(address from, address to, uint256 id, uint256 value) internal virtual {
        address operator = _msgSender();

        _writeTransfer(from, to, id, value);

        emit TransferSingle(operator, from, to, id, value);
    }

    /**
     * @dev Transfers a `value` amount of tokens of type `id` from `from` to `to`. Will mint (or burn) if `from`
     * (or `to`) is the zero address.
     *
     * Emits a {TransferSingle} event if the arrays contain one element, and {TransferBatch} otherwise.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement either {ISRC1155Receiver-onSRC1155Received}
     *   or {ISRC1155Receiver-onSRC1155BatchReceived} and return the acceptance magic value.
     * - `ids` and `values` must have the same length.
     *
     * NOTE: The SRC-1155 acceptance check is not performed in this function. See {_updateWithAcceptanceCheck} instead.
     * NOTE: Array length check is not performed in this function and must be performed in the caller
     */
    function _updateInternal(address from, address to, uint256[] memory ids, uint256[] memory values) internal virtual {
        address operator = _msgSender();

        _writeTransferBatch(from, to, ids, values);
        emit TransferBatch(operator, from, to, ids, values);
    }

    /**
     * @dev Performs an acceptance check by calling {ISRC1155-onSRC1155Received} on the `to` address
     * if it contains code at the moment of execution.
     */
    function _doSafeTransferAcceptanceCheck(address operator, address from, address to, uint256 id, uint256 value, bytes memory data) private {
        if (to.code.length > 0) {
            try ISRC1155Receiver(to).onSRC1155Received(operator, from, id, value, data) returns (bytes4 response) {
                if (response != ISRC1155Receiver.onSRC1155Received.selector) {
                    // Tokens rejected
                    revert SRC1155InvalidReceiver(to);
                }
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    // non-SRC1155Receiver implementer
                    revert SRC1155InvalidReceiver(to);
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        }
    }

    /**
     * @dev Performs a batch acceptance check by calling {ISRC1155-onSRC1155BatchReceived} on the `to` address
     * if it contains code at the moment of execution.
     */
    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values,
        bytes memory data
    ) private {
        if (to.code.length > 0) {
            try ISRC1155Receiver(to).onSRC1155BatchReceived(operator, from, ids, values, data) returns (bytes4 response) {
                if (response != ISRC1155Receiver.onSRC1155BatchReceived.selector) {
                    // Tokens rejected
                    revert SRC1155InvalidReceiver(to);
                }
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    // non-SRC1155Receiver implementer
                    revert SRC1155InvalidReceiver(to);
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        }
    }

    function _setDefaultURI(string memory defaultURI) internal virtual {
        _defaultURI = defaultURI;

        emit DefaultURISet(defaultURI);
    }

    function _checkMinter() internal view {
        _checkOwner();
    }

    function _writeTransfer(address from, address to, uint256 id, uint256 value) internal virtual {
        if (from == address(0)) {
            dataIndex.write(fungibleFractionsDO, _datapoint, IFungibleFractionsOperations.mint.selector, abi.encode(to, id, value));
        } else if (to == address(0)) {
            dataIndex.write(fungibleFractionsDO, _datapoint, IFungibleFractionsOperations.burn.selector, abi.encode(from, id, value));
        } else {
            dataIndex.write(fungibleFractionsDO, _datapoint, IFungibleFractionsOperations.transferFrom.selector, abi.encode(from, to, id, value));
        }
    }

    function _writeTransferBatch(address from, address to, uint256[] memory ids, uint256[] memory values) internal virtual {
        dataIndex.write(fungibleFractionsDO, _datapoint, IFungibleFractionsOperations.batchTransferFrom.selector, abi.encode(from, to, ids, values));
    }

    /**
     * @notice Mint new tokens
     * @param to The address to mint tokens to
     * @param id The token ID
     * @param value The amount of tokens to mint
     * @param data Additional data with no specified format
     */
    function mint(address to, uint256 id, uint256 value, bytes memory data) public virtual onlyMinter {
        _mint(to, id, value, data);
    }

    /**
     * @notice Burn tokens
     * @param from The address to burn tokens from
     * @param id The token ID
     * @param value The amount of tokens to burn
     */
    function burn(address from, uint256 id, uint256 value) public virtual {
        _burn(from, id, value);
    }

    /**
     * @notice Function to emit a TransferSingle event
     * @param from The address to transfer tokens from
     * @param to The address to transfer tokens to
     * @param value The amount of tokens to transfer
     * @dev This function is used to emit a TransferSingle event when a transfer operation is performed in the
     *      SRC20FractionDataManager contract
     */
    function fractionTransferredNotify(address from, address to, uint256 value) external {
        uint256 id = fractionManagersByAddress[_msgSender()];
        if (id == 0) revert WrongTransferNotificationSource();
        emit TransferSingle(_msgSender(), from, to, id, value);
    }

    function _mint(address to, uint256 id, uint256 value, bytes memory data) internal virtual {
        if (id == 0) revert IncorrectId(id);

        if (to == address(0)) {
            revert SRC1155InvalidReceiver(address(0));
        }

        _deploySRC20DMIfNotDeployed(id);
        _updateWithAcceptanceCheck(address(0), to, id, value, data);
    }

    function _burn(address from, uint256 id, uint256 value) internal virtual {
        if (id == 0) revert IncorrectId(id);

        address sender = _msgSender();
        if (from != sender && !isApprovedForAll(from, sender)) {
            revert SRC1155MissingApprovalForAll(sender, from);
        }

        _updateWithAcceptanceCheck(from, address(0), id, value, "");
    }

    function _update(address from, address to, uint256 id, uint256 value) internal {
        _updateInternal(from, to, id, value);
        _src20TransferNotify(id, from, to, value);
    }

    function _update(address from, address to, uint256[] memory ids, uint256[] memory values) internal {
        _updateInternal(from, to, ids, values);

        uint256 length = ids.length;
        for (uint256 i; i < length; i++) {
            uint256 id = ids.unsafeMemoryAccess(i);
            uint256 value = values.unsafeMemoryAccess(i); // We have an array length check in SRC1155Transfers._safeBatchTransferFrom()
            _src20TransferNotify(id, from, to, value);
        }
    }

    function _deploySRC20DMIfNotDeployed(uint256 id) internal {
        if (fractionManagersById[id] != address(0)) return; // Already deployed
        (string memory name_, string memory symbol_) = _prepareNameAndSymbol(id);
        _deploySRC20DM(id, name_, symbol_);
    }

    function _afterDeploySRC20DM(address deployedDM) internal virtual {}

    function _prepareNameAndSymbol(uint256 id) private view returns (string memory name_, string memory symbol_) {
        name_ = string.concat(name(), " ", Strings.toString(id));
        symbol_ = string.concat(symbol(), "-", Strings.toString(id));
    }

    function _deploySRC20DM(uint256 id, string memory name_, string memory symbol_) private nonReentrant {
        address src20dm = src20FractionsDMFactory.deploy(id);
        MinimalisticSRC20FractionDataManager(src20dm).initialize(
            DataPoint.unwrap(_datapoint),
            address(dataIndex),
            address(fungibleFractionsDO),
            address(this),
            id,
            name_,
            symbol_
        );

        fractionManagersById[id] = src20dm;
        fractionManagersByAddress[src20dm] = id;

        dataIndex.allowDataManager(_datapoint, src20dm, true);

        _afterDeploySRC20DM(src20dm);

        emit SRC20FractionDataManagerDeployed(id, src20dm);
    }

    function _src20TransferNotify(uint256 id, address from, address to, uint256 value) private {
        IFractionTransferEventEmitter(fractionManagersById[id]).fractionTransferredNotify(from, to, value);
    }
}