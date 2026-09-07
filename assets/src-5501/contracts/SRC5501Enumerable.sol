// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

import "./SRC5501Balance.sol";
import "./ISRC5501Enumerable.sol";

/**
 * @dev Implementation of Enumerable extension of https://sips.sila.org/SIPS/sip-5501 with OpenZeppelin SRC721 version.
 */
contract SRC5501Enumerable is ISRC5501Enumerable, SRC5501Balance {
    /**
     * @dev Initializes the contract by setting a name and a symbol to the token collection.
     */
    constructor(string memory name_, string memory symbol_)
        SRC5501Balance(name_, symbol_)
    {}

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
            interfaceId == type(ISRC5501Enumerable).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}
