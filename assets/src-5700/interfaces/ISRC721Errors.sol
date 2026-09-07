// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.16;

/// @title SRC-721 Errors Interface
interface ISRC721Errors {

    /// @notice Originating address does not own the NFT.
    error OwnerInvalid();

    /// @notice Receiving address cannot be the zero address.
    error ReceiverInvalid();

    /// @notice Receiving contract does not implement the SRC-721 wallet interface.
    error SafeTransferUnsupported();

    /// @notice Sender is not NFT owner, approved address, or owner operator.
    error SenderUnauthorized();

    /// @notice NFT supply has hit maximum capacity.
    error SupplyMaxCapacity();

    /// @notice Token has already minted.
    error TokenAlreadyMinted();

    /// @notice NFT does not exist.
    error TokenNonExistent();

}

