// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Create2} from "@openzeppelin/contracts/utils/Create2.sol";
import {MinimalisticSRC20FractionDataManager} from "./MinimalisticSRC20FractionDataManager.sol";

/**
 * @title Minimalistic SRC20 Fraction Data Manager Factory
 * @dev Factory contract to deploy MinimalisticSRC20FractionDataManager contracts
 *      This contract does not have any access control on who can deploy new contracts
 */
contract MinimalisticSRC20FractionDataManagerFactory {
    /// @notice Event emitted when a new MinimalisticSRC20FractionDataManager contract is deployed
    event Deployed(address indexed addr, uint256 id);

    /**
     * @dev Deploys a new MinimalisticSRC20FractionDataManager contract
     * @param id The id of the contract
     * @return addr The address of the deployed contract
     * @dev The address of the deployed contract is deterministic based on the sender and id
     */
    function deploy(uint256 id) external returns (address addr) {
        bytes32 salt = keccak256(abi.encodePacked(msg.sender, id));

        addr = Create2.deploy(0, salt, type(MinimalisticSRC20FractionDataManager).creationCode);
        emit Deployed(addr, id);

        return addr;
    }
}