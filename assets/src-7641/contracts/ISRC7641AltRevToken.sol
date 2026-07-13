// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./ISRC7641.sol";

/**
 * @dev An optional extension of the SRC-7641 standard that accepts other SRC-20 revenue tokens into the contract with corresponding claim function
 */
interface ISRC7641AltRevToken is ISRC7641 {
    /**
     * @dev A function to calculate the amount of SRC-20 claimable by a token holder at certain snapshot.
     * @param account The address of the token holder
     * @param snapshotId The snapshot id
     * @param token The address of the revenue token
     * @return The amount of revenue token claimable
     */
    function claimableSRC20(address account, uint256 snapshotId, address token) external view returns (uint256);

    /**
     * @dev A function to calculate the amount of SRC-20 redeemable by a token holder upon burn
     * @param amount The amount of token to burn
     * @param token The address of the revenue token
     * @return The amount of revenue token redeemable
     */
    function redeemableSRC20OnBurn(uint256 amount, address token) external view returns (uint256);
}