// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.20;

/// @notice Minimal SRC-7726 Common Quote Oracle interface.
/// @dev The full standard is at https://sips.sila.org/SIPS/sip-7726.
interface ISRC7726 {
    /// @notice Value of `baseAmount` of `base`, expressed in `quote` terms.
    /// @dev Implementations SHOULD revert when they cannot provide a reliable, fresh quote.
    function getQuote(uint256 baseAmount, address base, address quote)
        external
        view
        returns (uint256 quoteAmount);
}
