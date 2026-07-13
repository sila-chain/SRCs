// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/SRC721/SRC721.sol";
import "./ISRC5501.sol";
import "./ISRC5501Balance.sol";
import "./ISRC5501Enumerable.sol";
import "./ISRC5501Terminable.sol";

/**
 * @dev Implementation of SRC5501 contract with all extensions https://sips.sila.org/SIPS/sip-5501 with OpenZeppelin SRC721 version.
 */
contract SRC5501Combined is
    ISRC5501,
    ISRC5501Balance,
    ISRC5501Terminable,
    ISRC5501Enumerable,
    SRC721
{
    /**
     * @dev Structure to hold user information.
     * @notice If isBorrowed is true, UserInfo cannot be modified before it expires.
     */
    struct UserInfo {
        address user; // Address of user role
        uint64 expires; // Unix timestamp, user expires on
        bool isBorrowed; // Borrowed flag
    }

    /**
     * @dev Structure to hold agreements from both parties to terminate a borrow.
     * @notice If both parties agree, it is possible to modify UserInfo even before it expires.
     * In such case, isBorrowed status is reverted to false.
     */
    struct BorrowTerminationInfo {
        bool lenderAgreement;
        bool borrowerAgreement;
    }

    // Mapping from token ID to UserInfo
    mapping(uint256 => UserInfo) internal _users;

    // Mapping from address to userOf tokens
    mapping(address => uint256[]) internal _userBalances;

    // Mapping from token ID to BorrowTerminationInfo
    mapping(uint256 => BorrowTerminationInfo) internal _borrowTerminations;

    /**
     * @dev Initializes the contract by setting a name and a symbol to the token collection.
     */
    constructor(string memory name_, string memory symbol_)
        SRC721(name_, symbol_)
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
        // Balance extension
        flushExpired(user);

        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            "SRC5501: set user caller is not token owner or approved"
        );
        require(user != address(0), "SRC5501: set user to zero address");

        UserInfo storage info = _users[tokenId];
        require(
            !info.isBorrowed || info.expires < block.timestamp,
            "SRC5501: token is borrowed"
        );
        info.user = user;
        info.expires = expires;
        info.isBorrowed = isBorrowed;
        emit UpdateUser(tokenId, user, expires, isBorrowed);

        // Balance extension
        _userBalances[user].push(tokenId);
        // Terminable extension
        delete _borrowTerminations[tokenId];
        emit ResetTerminationAgreements(tokenId);
    }

    /**
     * @dev See {ISRC5501-userOf}.
     */
    function userOf(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        require(
            uint256(_users[tokenId].expires) >= block.timestamp,
            "SRC5501: user does not exist for this token"
        );
        return _users[tokenId].user;
    }

    /**
     * @dev See {ISRC5501-userBalanceOf}.
     */
    function userBalanceOf(address user)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            user != address(0),
            "SRC5501Balance: address zero is not a valid owner"
        );
        uint256 balance;
        uint256[] memory candidates = _userBalances[user];
        unchecked {
            for (uint256 i; i < candidates.length; ++i) {
                if (
                    _users[candidates[i]].expires >= block.timestamp &&
                    _users[candidates[i]].user == user
                ) {
                    ++balance;
                }
            }
        }
        return balance;
    }

    /**
     * @dev See {ISRC5501-tokenOfUserByIndex}.
     */
    function tokenOfUserByIndex(address user, uint256 index)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            user != address(0),
            "SRC5501Enumerable: address zero is not a valid owner"
        );
        uint256[] memory balance = _userBalances[user];
        require(
            balance.length > 0 && index < balance.length,
            "SRC5501Enumerable: owner index out of bounds"
        );
        uint256 counter;
        unchecked {
            for (uint256 i; i < balance.length; ++i) {
                if (
                    _users[balance[i]].expires >= block.timestamp &&
                    _users[balance[i]].user == user
                ) {
                    if (counter == index) {
                        return balance[i];
                    }
                    ++counter;
                }
            }
        }
        revert("SRC5501Enumerable: owner index out of bounds");
    }

    /**
     * @dev See {ISRC5501-userExpires}.
     */
    function userExpires(uint256 tokenId)
        public
        view
        virtual
        override
        returns (uint64)
    {
        return _users[tokenId].expires;
    }

    /**
     * @dev See {ISRC5501-isBorrowed}.
     */
    function userIsBorrowed(uint256 tokenId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _users[tokenId].isBorrowed;
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
     * @notice On setUser flush all expired userOf statuses.
     * @dev This function may revert out of gas if user borrows too many tokens at once.
     * There must be a way to prevent such behaviour (such as flushing by parts only).
     * @param user an address to flush
     */
    function flushExpired(address user) internal {
        uint256[] storage candidates = _userBalances[user];
        unchecked {
            for (uint256 i; i < candidates.length; ++i) {
                if (
                    _users[candidates[i]].user != user ||
                    _users[candidates[i]].expires < block.timestamp
                ) {
                    candidates[i] = candidates[candidates.length - 1];
                    candidates.pop();
                    --i; // test moved element
                }
            }
        }
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
            interfaceId == type(ISRC5501).interfaceId ||
            interfaceId == type(ISRC5501Balance).interfaceId ||
            interfaceId == type(ISRC5501Enumerable).interfaceId ||
            interfaceId == type(ISRC5501Terminable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Hook that is called after any token transfer.
     * If user is set and token is not borrowed, reset user.
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._afterTokenTransfer(from, to, tokenId);
        if (
            from != to &&
            !_users[tokenId].isBorrowed &&
            _users[tokenId].user != address(0)
        ) {
            delete _users[tokenId];
            emit UpdateUser(tokenId, address(0), 0, false);
        } else if (
            // Terminable extension
            from != to && _users[tokenId].isBorrowed
        ) {
            delete _borrowTerminations[tokenId];
            emit ResetTerminationAgreements(tokenId);
        }
    }
}
