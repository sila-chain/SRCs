// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

/**
 * @title ISRC5501Balance
 * @dev See https://sips.sila.org/SIPS/sip-5501
 * Extension for SRC5501 which adds userBalanceOf to query how many tokens address is userOf.
 * @notice the SIP-165 identifier for this interface is 0x0cb22289.
 */
interface ISRC5501Balance /* is ISRC5501 */{
    /**
     * @notice Count of all NFTs assigned to a user.
     * @dev Reverts if user is zero address.
     * @param _user an address for which to query the balance
     * @return uint256 the number of NFTs the user has
     */
    function userBalanceOf(address _user) external view returns (uint256);
}
