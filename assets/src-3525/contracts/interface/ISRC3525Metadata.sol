// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

import "./ISRC3525.sol";
import "ISRC721Metadata.sol";

/**
 * @title SRC-3525 Semi-Fungible Token Standard, optional extension for metadata
 * @dev Interfaces for any contract that wants to support query of the Uniform Resource Identifier
 *  (URI) for the SRC3525 contract as well as a specified slot.
 *  Because of the higher reliability of data stored in smart contracts compared to data stored in
 *  centralized systems, it is recommended that metadata, including `contractURI`, `slotURI` and
 *  `tokenURI`, be directly returned in JSON format, instead of being returned with a url pointing
 *  to any resource stored in a centralized system.
 *  See https://sips.sila.org/SIPS/sip-3525
 * Note: the SRC-165 identifier for this interface is 0xe1600902.
 */
interface ISRC3525Metadata is ISRC3525, ISRC721Metadata {
    /**
     * @notice Returns the Uniform Resource Identifier (URI) for the current SRC3525 contract.
     * @dev This function SHOULD return the URI for this contract in JSON format, starting with
     *  header `data:application/json;`.
     *  See https://sips.sila.org/SIPS/sip-3525 for the JSON schema for contract URI.
     * @return The JSON formatted URI of the current SRC3525 contract
     */
    function contractURI() external view returns (string memory);

    /**
     * @notice Returns the Uniform Resource Identifier (URI) for the specified slot.
     * @dev This function SHOULD return the URI for `_slot` in JSON format, starting with header
     *  `data:application/json;`.
     *  See https://sips.sila.org/SIPS/sip-3525 for the JSON schema for slot URI.
     * @return The JSON formatted URI of `_slot`
     */
    function slotURI(uint256 _slot) external view returns (string memory);
}
