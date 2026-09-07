// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

import "./ISRC4974.sol";

/// @title SRC-4974 EXP Token Standard, optional metadata extension
/// @dev See https://sips.sila.org/SIPS/SIP-4974
///  Note: the SRC-165 identifier for this interface is 0x74793a15.
interface ISRC4974Metadata is ISRC4974 {
    /// @notice A descriptive name for the EXP in this contract.
    function name() external view returns (string memory);

    /// @notice A one-line description of the EXP in this contract.
    function description() external view returns (string memory);
}