// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/SRC1155/ISRC1155Receiver.sol";
import "@openzeppelin/contracts/token/SRC1155/extensions/SRC1155Supply.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/SRC721/extensions/SRC721Enumerable.sol";
import "@openzeppelin/contracts/token/SRC721/extensions/SRC721URIStorage.sol";

contract SRC721Full is SRC721Enumerable, SRC721URIStorage {
    /// @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
    /// @param name is a non-empty string
    /// @param symbol is a non-empty string
    constructor(string memory name, string memory symbol)
        SRC721(name, symbol)
    {}

    /// @dev Hook that is called before any token transfer. This includes minting and burning. `from`'s `tokenId` will be transferred to `to`
    /// @param from is an non-zero address
    /// @param to is an non-zero address
    /// @param tokenId is an uint256 which determine token transferred from `from` to `to`
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(SRC721Enumerable, SRC721) {
        SRC721Enumerable._beforeTokenTransfer(from, to, tokenId);
    }

    /// @notice Interface of the SRC165 standard
    /// @param interfaceId is a byte4 which determine interface used
    /// @return true if this contract implements the interface defined by `interfaceId`
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(SRC721Enumerable, SRC721)
        returns (bool)
    {
        return
            SRC721.supportsInterface(interfaceId) ||
            SRC721Enumerable.supportsInterface(interfaceId);
    }

    /// @notice the Uniform Resource Identifier (URI) for `tokenId` token
    /// @param tokenId is unit256
    /// @return string of (URI) for `tokenId` token
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(SRC721URIStorage, SRC721)
        returns (string memory)
    {
        return SRC721URIStorage.tokenURI(tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        override(SRC721, SRC721URIStorage)
    {}
}

/**
 * @dev Interface of the Multiverse NFT standard as defined in the SIP.
 */
interface IMultiverseNFT {
    /**
     * @dev struct to store delegate token details
     *
     */
    struct DelegateData {
        address contractAddress;
        uint256 tokenId;
        uint256 quantity;
    }

    /**
     * @dev Emitted when one or more new delegate NFTs are added to a Multiverse NFT
     *
     */
    event Bundled(
        uint256 multiverseTokenID,
        DelegateData[] delegateData,
        address ownerAddress
    );

    /**
     * @dev Emitted when one or more delegate NFTs are removed from a Multiverse NFT
     */
    event Unbundled(uint256 multiverseTokenID, DelegateData[] delegateData);

    /**
     * @dev Accepts the tokenId of the Multiverse NFT and returns an array of delegate token data
     */
    function delegateTokens(uint256 multiverseTokenID)
        external
        view
        returns (DelegateData[] memory);

    /**
     * @dev Removes one or more delegate NFTs from a Multiverse NFT
     * This function accepts the delegate NFT details, and transfer those NFTs out of the Multiverse NFT contract to the owner's wallet
     */
    function unbundle(
        DelegateData[] memory delegateData,
        uint256 multiverseTokenID
    ) external;

    /**
     * @dev Adds one or more delegate NFTs to a Multiverse NFT
     * This function accepts the delegate NFT details, and transfers those NFTs to the Multiverse NFT contract
     * Need to ensure that approval is given to this Multiverse NFT contract for the delegate NFTs so that they can be transferred programmatically
     */
    function bundle(
        DelegateData[] memory delegateData,
        uint256 multiverseTokenID
    ) external;

    /**
     * @dev Initializes a new bundle, mints a Multiverse NFT and assigns it to msg.sender
     * Returns the token ID of a new Multiverse NFT
     * Note - When a new Multiverse NFT is initialized, it is empty, it does not contain any delegate NFTs
     */
    function initBundle(DelegateData[] memory delegateData) external;
}

abstract contract MultiverseNFT is
    IMultiverseNFT,
    Ownable,
    SRC721Full,
    ISRC1155Receiver,
    AccessControl
{
    using SafeMath for uint256;
    bytes32 public constant BUNDLER_ROLE = keccak256("BUNDLER_ROLE");

    uint256 currentMultiverseTokenID;

    mapping(uint256 => DelegateData[]) public multiverseNFTDelegateData;
    mapping(uint256 => mapping(address => mapping(uint256 => uint256)))
        public tokenBalances;

    constructor(address bundlerAddress) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(BUNDLER_ROLE, msg.sender);
        _setRoleAdmin(BUNDLER_ROLE, DEFAULT_ADMIN_ROLE);
        _setupRole(BUNDLER_ROLE, bundlerAddress);
    }

    function delegateTokens(uint256 multiverseTokenID)
        external
        view
        returns (DelegateData[] memory)
    {
        return multiverseNFTDelegateData[multiverseTokenID];
    }

    function initBundle(DelegateData[] memory delegateData) external {
        uint256 tokenId = currentMultiverseTokenID.add(1);
        for (uint256 i = 0; i < delegateData.length; i = i.add(1)) {
            bool isSRC721 = _isSRC721(delegateData[i].contractAddress);
            if (isSRC721) {
                require(
                    delegateData[i].quantity == 1,
                    "SRC721 quantity must be 1"
                );
            }
            multiverseNFTDelegateData[tokenId].push(delegateData[i]);
        }

        _incrementMultiverseTokenID();
        _safeMint(msg.sender, tokenId);
    }

    function bundle(
        DelegateData[] memory delegateData,
        uint256 multiverseTokenID
    ) external {
        require(
            hasRole(BUNDLER_ROLE, msg.sender) ||
                ownerOf(multiverseTokenID) == msg.sender,
            "msg.sender neither have bundler role nor multiversetoken owner"
        );
        _bundle(delegateData, multiverseTokenID);
    }

    function unbundle(
        DelegateData[] memory delegateData,
        uint256 multiverseTokenID
    ) external {
        require(
            ownerOf(multiverseTokenID) == msg.sender,
            "msg.sender is not a multiversetoken owner"
        );
        for (uint256 i = 0; i < delegateData.length; i = i.add(1)) {
            require(
                _ensureDelegateBelongsToMultiverseNFT(
                    delegateData[i],
                    multiverseTokenID
                ),
                "delegate not assigned to multiverse token"
            );
            uint256 balance = tokenBalances[multiverseTokenID][
                delegateData[i].contractAddress
            ][delegateData[i].tokenId];
            require(
                delegateData[i].quantity <= balance,
                "quantity exceeds balance"
            );
            require(
                _ensureMultiverseContractOwnsDelegate(delegateData[i]),
                "delegate not owned by contract"
            );

            address contractAddress = delegateData[i].contractAddress;
            uint256 tokenId = delegateData[i].tokenId;
            uint256 quantity = delegateData[i].quantity;

            _updateDelegateBalances(delegateData[i], multiverseTokenID);

            if (_isSRC721(contractAddress)) {
                SRC721Full src721Instance = SRC721Full(contractAddress);
                src721Instance.transferFrom(address(this), msg.sender, tokenId);
            } else if (_isSRC1155(contractAddress)) {
                SRC1155Supply src1155Instance = SRC1155Supply(contractAddress);
                src1155Instance.safeTransferFrom(
                    address(this),
                    msg.sender,
                    tokenId,
                    quantity,
                    ""
                );
            }
        }
        emit Unbundled(multiverseTokenID, delegateData);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControl, SRC721Full, ISRC165)
        returns (bool)
    {
        return
            AccessControl.supportsInterface(interfaceId) ||
            SRC721Full.supportsInterface(interfaceId);
    }

    function _bundle(
        DelegateData[] memory delegateData,
        uint256 multiverseTokenID
    ) internal {
        for (uint256 i = 0; i < delegateData.length; i = i.add(1)) {
            require(
                _ensureDelegateBelongsToMultiverseNFT(
                    delegateData[i],
                    multiverseTokenID
                ),
                "delegate not assigned to multiversetoken"
            );
            require(
                _ensureDelegateQuantityLimitForMMultiverseNFT(
                    delegateData[i],
                    multiverseTokenID
                ),
                "delegate quantity assigned to multiversetoken exceeds"
            );

            address contractAddress = delegateData[i].contractAddress;
            uint256 tokenId = delegateData[i].tokenId;
            uint256 quantity = delegateData[i].quantity;

            tokenBalances[multiverseTokenID][contractAddress][
                tokenId
            ] = tokenBalances[multiverseTokenID][contractAddress][tokenId].add(
                quantity
            );

            if (_isSRC721(contractAddress)) {
                require(
                    quantity == 1,
                    "SRC721 cannot have quantity more than 1"
                );
                SRC721Full src721Instance = SRC721Full(contractAddress);
                src721Instance.transferFrom(msg.sender, address(this), tokenId);
            } else if (_isSRC1155(contractAddress)) {
                SRC1155Supply src1155Instance = SRC1155Supply(contractAddress);
                src1155Instance.safeTransferFrom(
                    msg.sender,
                    address(this),
                    tokenId,
                    quantity,
                    ""
                );
            }
        }
        emit Bundled(
            multiverseTokenID,
            delegateData,
            ownerOf(multiverseTokenID)
        );
    }

    function _ensureDelegateBelongsToMultiverseNFT(
        DelegateData memory delegateData,
        uint256 multiverseTokenID
    ) internal view returns (bool) {
        DelegateData[] memory storedData = multiverseNFTDelegateData[
            multiverseTokenID
        ];
        for (uint256 i = 0; i < storedData.length; i = i.add(1)) {
            if (
                delegateData.contractAddress == storedData[i].contractAddress &&
                delegateData.tokenId == storedData[i].tokenId
            ) {
                return true;
            }
        }
        return false;
    }

    function _ensureMultiverseContractOwnsDelegate(
        DelegateData memory delegateData
    ) internal view returns (bool) {
        if (_isSRC721(delegateData.contractAddress)) {
            SRC721Full src721Instance = SRC721Full(
                delegateData.contractAddress
            );
            if (address(this) == src721Instance.ownerOf(delegateData.tokenId)) {
                return true;
            }
        } else if (_isSRC1155(delegateData.contractAddress)) {
            SRC1155Supply src1155Instance = SRC1155Supply(
                delegateData.contractAddress
            );
            if (
                src1155Instance.balanceOf(
                    address(this),
                    delegateData.tokenId
                ) >= delegateData.quantity
            ) {
                return true;
            }
        }
        return false;
    }

    function _ensureDelegateQuantityLimitForMMultiverseNFT(
        DelegateData memory delegateData,
        uint256 multiverseTokenID
    ) internal view returns (bool) {
        DelegateData[] memory storedData = multiverseNFTDelegateData[
            multiverseTokenID
        ];
        for (uint256 i = 0; i < storedData.length; i = i.add(1)) {
            if (
                delegateData.contractAddress == storedData[i].contractAddress &&
                delegateData.tokenId == storedData[i].tokenId
            ) {
                uint256 balance = tokenBalances[multiverseTokenID][
                    delegateData.contractAddress
                ][delegateData.tokenId];
                if (
                    balance.add(delegateData.quantity) <= storedData[i].quantity
                ) {
                    return true;
                }
                return false;
            }
        }
    }

    function _updateDelegateBalances(
        DelegateData memory delegateData,
        uint256 multiverseTokenID
    ) internal returns (uint256) {
        address contractAddress = delegateData.contractAddress;
        uint256 tokenId = delegateData.tokenId;
        tokenBalances[multiverseTokenID][contractAddress][
            tokenId
        ] = tokenBalances[multiverseTokenID][contractAddress][tokenId].sub(
            delegateData.quantity
        );
        return tokenBalances[multiverseTokenID][contractAddress][tokenId];
    }

    function onSRC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external pure override returns (bytes4) {
        return this.onSRC1155Received.selector;
    }

    function onSRC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external pure override returns (bytes4) {
        return this.onSRC1155BatchReceived.selector;
    }

    function _isSRC1155(address contractAddress) internal view returns (bool) {
        return ISRC1155(contractAddress).supportsInterface(0xd9b67a26);
    }

    function _isSRC721(address contractAddress) internal view returns (bool) {
        return ISRC721(contractAddress).supportsInterface(0x80ac58cd);
    }

    function _incrementMultiverseTokenID() internal {
        currentMultiverseTokenID = currentMultiverseTokenID.add(1);
    }
}
