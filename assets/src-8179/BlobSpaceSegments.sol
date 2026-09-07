// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.24;

import {ISRC_BSS} from "./ISRC_BSS.sol";

/// @title BlobSpaceSegments
/// @notice Reference implementation of SRC-BSS: Blob Space Segments
/// @dev Zero storage — events are the sole record. Uses BLOBHASH opcode (SIP-4844).
contract BlobSpaceSegments is ISRC_BSS {
    /// @dev Maximum number of field elements per SIP-4844 blob.
    uint16 internal constant MAX_FIELD_ELEMENTS = 4096;

    /// @inheritdoc ISRC_BSS
    function declareBlobSegment(uint256 blobIndex, uint16 startFE, uint16 endFE, bytes32 contentTag)
        external
        returns (bytes32 versionedHash)
    {
        if (startFE >= endFE || endFE > MAX_FIELD_ELEMENTS) {
            revert InvalidSegment(startFE, endFE);
        }

        // BLOBHASH returns bytes32(0) for indices without a blob in this tx
        assembly {
            versionedHash := blobhash(blobIndex)
        }
        if (versionedHash == bytes32(0)) revert NoBlobAtIndex(blobIndex);

        emit BlobSegmentDeclared(versionedHash, msg.sender, startFE, endFE, contentTag);
    }
}
