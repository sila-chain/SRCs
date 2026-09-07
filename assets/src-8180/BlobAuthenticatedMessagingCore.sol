// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.24;

import {ISRC_BSS} from "./ISRC_BSS.sol";
import {ISRC_BAM_Core} from "./ISRC_BAM_Core.sol";

/// @title BlobAuthenticatedMessagingCore
/// @notice Reference implementation of ISRC_BAM_Core (extends ISRC_BSS)
/// @dev Zero storage. Events are the sole record. Uses BLOBHASH opcode (SIP-4844).
///      declareBlobSegment is public so registerBlobBatch can call it internally.
contract BlobAuthenticatedMessagingCore is ISRC_BAM_Core {
    uint16 internal constant MAX_FIELD_ELEMENTS = 4096;

    /// @inheritdoc ISRC_BAM_Core
    function registerBlobBatch(
        uint256 blobIndex,
        uint16 startFE,
        uint16 endFE,
        bytes32 contentTag,
        address decoder,
        address signatureRegistry
    ) external returns (bytes32 versionedHash) {
        versionedHash = declareBlobSegment(blobIndex, startFE, endFE, contentTag);

        emit BlobBatchRegistered(versionedHash, msg.sender, decoder, signatureRegistry);
    }

    /// @inheritdoc ISRC_BAM_Core
    function registerCalldataBatch(bytes calldata batchData, address decoder, address signatureRegistry)
        external
        returns (bytes32 contentHash)
    {
        contentHash = keccak256(batchData);

        emit CalldataBatchRegistered(contentHash, msg.sender, decoder, signatureRegistry);
    }

    /// @inheritdoc ISRC_BSS
    function declareBlobSegment(uint256 blobIndex, uint16 startFE, uint16 endFE, bytes32 contentTag)
        public
        returns (bytes32 versionedHash)
    {
        if (startFE >= endFE || endFE > MAX_FIELD_ELEMENTS) {
            revert InvalidSegment(startFE, endFE);
        }

        assembly {
            versionedHash := blobhash(blobIndex)
        }
        if (versionedHash == bytes32(0)) revert NoBlobAtIndex(blobIndex);

        emit BlobSegmentDeclared(versionedHash, msg.sender, startFE, endFE, contentTag);
    }
}
