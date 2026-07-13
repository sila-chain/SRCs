// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.21;

import "@openzeppelin/contracts/utils/introspection/ISRC165.sol";

interface ISRC7590 is ISRC165 {
    /**
     * @notice Used to notify listeners that the token received SRC-20 tokens.
     * @param src20Contract The address of the SRC-20 smart contract
     * @param toTokenId The ID of the token receiving the SRC-20 tokens
     * @param from The address of the account from which the tokens are being transferred
     * @param amount The number of SRC-20 tokens received
     */
    event ReceivedSRC20(
        address indexed src20Contract,
        uint256 indexed toTokenId,
        address indexed from,
        uint256 amount
    );

    /**
     * @notice Used to notify the listeners that the SRC-20 tokens have been transferred.
     * @param src20Contract The address of the SRC-20 smart contract
     * @param fromTokenId The ID of the token from which the SRC-20 tokens have been transferred
     * @param to The address receiving the SRC-20 tokens
     * @param amount The number of SRC-20 tokens transferred
     */
    event TransferredSRC20(
        address indexed src20Contract,
        uint256 indexed fromTokenId,
        address indexed to,
        uint256 amount
    );

    /**
     * @notice Used to retrieve the given token's specific SRC-20 balance
     * @param src20Contract The address of the SRC-20 smart contract
     * @param tokenId The ID of the token being checked for SRC-20 balance
     * @return The amount of the specified SRC-20 tokens owned by a given token
     */
    function balanceOfSRC20(
        address src20Contract,
        uint256 tokenId
    ) external view returns (uint256);

    /**
     * @notice Transfer SRC-20 tokens from a specific token.
     * @dev The balance MUST be transferred from this smart contract.
     * @dev MUST increase the transfer-out-nonce for the tokenId
     * @dev MUST revert if the `msg.sender` is not the owner of the NFT or approved to manage it.
     * @param src20Contract The address of the SRC-20 smart contract
     * @param tokenId The ID of the token to transfer the SRC-20 tokens from
     * @param amount The number of SRC-20 tokens to transfer
     * @param data Additional data with no specified format, to allow for custom logic
     */
    function transferHeldSRC20FromToken(
        address src20Contract,
        uint256 tokenId,
        address to,
        uint256 amount,
        bytes memory data
    ) external;

    /**
     * @notice Transfer SRC-20 tokens to a specific token.
     * @dev The SRC-20 smart contract must have approval for this contract to transfer the SRC-20 tokens.
     * @dev The balance MUST be transferred from the `msg.sender`.
     * @param src20Contract The address of the SRC-20 smart contract
     * @param tokenId The ID of the token to transfer SRC-20 tokens to
     * @param amount The number of SRC-20 tokens to transfer
     * @param data Additional data with no specified format, to allow for custom logic
     */
    function transferSRC20ToToken(
        address src20Contract,
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    ) external;

    /**
     * @notice Nonce increased every time an SRC20 token is transferred out of a token
     * @param tokenId The ID of the token to check the nonce for
     * @return The nonce of the token
     */
    function src20TransferOutNonce(
        uint256 tokenId
    ) external view returns (uint256);
}
