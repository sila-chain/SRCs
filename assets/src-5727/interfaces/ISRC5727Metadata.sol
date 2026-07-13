//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../../SRC3525/interfaces/ISRC3525Metadata.sol";
import "./ISRC5727.sol";

/**
 * @title SRC5727 Soulbound Token Metadata Interface
 * @dev This extension allows querying the metadata of soulbound tokens.
 */
interface ISRC5727Metadata is ISRC3525Metadata, ISRC5727 {

}
