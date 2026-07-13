// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

import "./SRC5501.sol";
import "./ISRC5501Terminable.sol";

/**
 * @dev Implementation of Terminable extension of https://sips.sila.org/SIPS/sip-5501 with OpenZeppelin SRC721 version.
 */
contract SRC5501Terminable is ISRC5501Terminable, SRC5501 {
    /**
     * @dev Structure to hold agreements from both parties to terminate a borrow.
     * @notice If both parties agree, it is possible to modify UserInfo even before it expires.
     * In such case, isBorrowed status is reverted to false.
     */
    struct BorrowTerminationInfo {
        bool lenderAgreement;
        bool borrowerAgreement;
    }

    // Mapping from token ID to BorrowTerminationInfo
    mapping(uint256 => BorrowTerminationInfo) internal _borrowTerminations;

    /**
     * @dev Initializes the contract by setting a name and a symbol to the token collection.
     */
    constructor(string memory name_, string memory symbol_)
        SRC5501(name_, symbol_)
    {}

    /**
     * @dev See {ISRC5501-setUser}.
     */
    function setUser(
        uint256 tokenId,
        address user,
        uint64 expires,
        bool isBorrowed
    ) public virtual override {
        super.setUser(tokenId, user, expires, isBorrowed);
        delete _borrowTerminations[tokenId];
        emit ResetTerminationAgreements(tokenId);
    }

    /**
     * @dev See {ISRC5501Terminable-setBorrowTermination}.
     */
    function setBorrowTermination(uint256 tokenId) public virtual override {
        UserInfo storage userInfo = _users[tokenId];
        require(
            userInfo.expires >= block.timestamp && userInfo.isBorrowed,
            "SRC5501Terminable: borrow not active"
        );

        BorrowTerminationInfo storage terminationInfo = _borrowTerminations[
            tokenId
        ];
        if (ownerOf(tokenId) == msg.sender) {
            terminationInfo.lenderAgreement = true;
            emit AgreeToTerminateBorrow(tokenId, msg.sender, true);
        }
        if (userInfo.user == msg.sender) {
            terminationInfo.borrowerAgreement = true;
            emit AgreeToTerminateBorrow(tokenId, msg.sender, false);
        }
    }

    /**
     * @dev See {ISRC5501Terminable-getBorrowTermination}.
     */
    function getBorrowTermination(uint256 tokenId)
        public
        view
        virtual
        override
        returns (bool, bool)
    {
        return (
            _borrowTerminations[tokenId].lenderAgreement,
            _borrowTerminations[tokenId].borrowerAgreement
        );
    }

    /**
     * @dev See {ISRC5501Terminable-terminateBorrow}.
     */
    function terminateBorrow(uint256 tokenId) public virtual override {
        BorrowTerminationInfo storage info = _borrowTerminations[tokenId];
        require(
            info.lenderAgreement && info.borrowerAgreement,
            "SRC5501Terminable: not agreed"
        );
        _users[tokenId].isBorrowed = false;
        delete _borrowTerminations[tokenId];
        emit ResetTerminationAgreements(tokenId);
        emit TerminateBorrow(
            tokenId,
            ownerOf(tokenId),
            _users[tokenId].user,
            msg.sender
        );
    }

    /**
     * @dev See {SIP-165: Standard Interface Detection}.
     * https://sips.sila.org/SIPS/sip-165
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(ISRC5501Terminable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Hook that is called after any token transfer.
     * If user is set and token is borrowed, reset termination agreements.
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._afterTokenTransfer(from, to, tokenId);
        if (from != to && _users[tokenId].isBorrowed) {
            delete _borrowTerminations[tokenId];
            emit ResetTerminationAgreements(tokenId);
        }
    }
}
