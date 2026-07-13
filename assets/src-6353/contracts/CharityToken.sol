// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

import "./SRC20Charity.sol";

/**
*@title SRC720 charity Token
*@dev Extension of SRC720 Token that can be partially donated to a charity project
*
*This extensions keeps track of donations to charity addresses. The  whitelisted adress are from a another contract (Reserve)
 */

contract CharityToken is SRC20Charity{
    constructor() SRC20("TestToken", "TST") {
        _mint(msg.sender, 10000 * 10 ** decimals());
    }

    /** @dev Creates `amount` tokens and assigns them to `to`, increasing
     * the total supply.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     *
     * @param to The address to assign the amount to.
     * @param amount The amount of token to mint.
     */
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function selfmint() public {
        _mint(msg.sender, 100 * 10 ** decimals());
    }
    
    
    //Test support for SRC-Charity
    bytes4 private constant _INTERFACE_ID_SRC_CHARITY = type(ISRC20charity).interfaceId; // 0x557512b6
    //bytes4 private constant _INTERFACE_ID_SRCcharity =type(ISRC165).interfaceId; // SRC165S
    function checkInterface(address testContract) external view returns (bool) {
    (bool success) = ISRC165(testContract).supportsInterface(_INTERFACE_ID_SRC_CHARITY);
    return success;
    }

    /*function InterfaceId() external returns (bytes4) {
    bytes4 _INTERFACE_ID = type(ISRC20charity).interfaceId;
    return _INTERFACE_ID ;
    }*/

}
