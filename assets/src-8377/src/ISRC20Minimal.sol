// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.20;

/// @notice The single SRC-20 method the guard needs: read the recipient's output balance so the
/// realized amount is measured on-chain, not reported by the route.
interface ISRC20Minimal {
    function balanceOf(address account) external view returns (uint256);
}
