// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "openzeppelin-contracts/interfaces/ISRC20.sol";
import "openzeppelin-contracts/interfaces/ISRC165.sol";

/**
 * @title SRC-7410 Update Allowance By Spender Extension
 * Note: the SRC-165 identifier for this interface is 0x12860fba
 */
interface ISRC7410 is ISRC20, ISRC165 {

    /**
     * @notice Decreases any allowance by `owner` address for caller.
     * Emits an {ISRC20-Approval} event.
     *
     * Requirements:
     * - when `subtractedValue` is equal or higher than current allowance of spender the new allowance is set to 0.
     * Nullification also MUST be reflected for current allowance being type(uint256).max.
     */
    function decreaseAllowanceBySpender(address owner, uint256 subtractedValue) external;

}
