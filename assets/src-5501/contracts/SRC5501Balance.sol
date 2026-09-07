// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

import "./SRC5501.sol";
import "./ISRC5501Balance.sol";

/**
 * @dev Implementation of Balance extension of https://sips.sila.org/SIPS/sip-5501 with OpenZeppelin SRC721 version.
 */
contract SRC5501Balance is ISRC5501Balance, SRC5501 {
    // Mapping from address to userOf tokens
    mapping(address => uint256[]) internal _userBalances;

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
        flushExpired(user);
        super.setUser(tokenId, user, expires, isBorrowed);
        _userBalances[user].push(tokenId);
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
            interfaceId == type(ISRC5501Balance).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}
