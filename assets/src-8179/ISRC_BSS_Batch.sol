// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.24;

import {ISRC_BSS} from "./ISRC_BSS.sol";

/// @title ISRC_BSS_Batch — Multi-Segment Declaration Extension
/// @notice Optional extension for declaring multiple segments in a single call.
/// @dev Useful when multiple protocols coordinate to tile a blob atomically
///      (e.g., L2 declares [0, 2000) and social protocol declares [2000, 4096)
///      in one transaction through a shared entry point).
interface ISRC_BSS_Batch is ISRC_BSS {
    /// @notice Parameters for a single segment declaration.
    /// @param blobIndex  Index of the blob within the transaction (0-based)
    /// @param startFE    Start field element (inclusive)
    /// @param endFE      End field element (exclusive)
    /// @param contentTag Protocol/content identifier
    struct BlobSegmentParams {
        uint256 blobIndex;
        uint16 startFE;
        uint16 endFE;
        bytes32 contentTag;
    }

    /// @notice Declare multiple segments in a single call.
    /// @dev Each segment is validated independently. If any segment is invalid,
    ///      the entire call reverts.
    /// @param segments Array of segment parameters
    /// @return versionedHashes Array of versioned hashes (one per segment)
    function declareBlobSegments(BlobSegmentParams[] calldata segments)
        external
        returns (bytes32[] memory versionedHashes);
}
