// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.21;

import "./ISRC7590.sol";
import "@openzeppelin/contracts/token/SRC20/ISRC20.sol";

error InvalidValue();
error InvalidAddress();
error InsufficientBalance();
error InvalidAmountTransferred();

abstract contract AbstractSRC7590 is ISRC7590 {
    mapping(uint256 tokenId => mapping(address src20Address => uint256 balance))
        private _balances;
    mapping(uint256 tokenHolderId => uint256 nonce)
        private _src20TransferOutNonce;

    /**
     * @inheritdoc ISRC7590
     */
    function balanceOfSRC20(
        address src20Contract,
        uint256 tokenId
    ) external view returns (uint256) {
        return _balances[tokenId][src20Contract];
    }

    /**
     * @notice Transfer SRC-20 tokens from a specific token
     * @dev The balance MUST be transferred from this smart contract.
     * @dev Implementers should validate that the `msg.sender` is either the token owner or approved to manage it before calling this.
     * @param src20Contract The SRC-20 contract
     * @param tokenId The token to transfer from
     * @param amount The number of SRC-20 tokens to transfer
     * @param data Additional data with no specified format, to allow for custom logic
     */
    function _transferHeldSRC20FromToken(
        address src20Contract,
        uint256 tokenId,
        address to,
        uint256 amount,
        bytes memory data
    ) internal {
        if (amount == 0) {
            revert InvalidValue();
        }
        if (to == address(0) || src20Contract == address(0)) {
            revert InvalidAddress();
        }
        if (_balances[tokenId][src20Contract] < amount) {
            revert InsufficientBalance();
        }
        _beforeTransferHeldSRC20FromToken(
            src20Contract,
            tokenId,
            to,
            amount,
            data
        );
        ISRC20 src20 = ISRC20(src20Contract);
        uint256 initBalance = src20.balanceOf(address(this));
        _balances[tokenId][src20Contract] -= amount;
        _src20TransferOutNonce[tokenId]++;

        src20.transfer(to, amount);
        uint256 newBalance = src20.balanceOf(address(this));
        // Here you can either use the difference as the amount, or revert if the difference is not equal to the amount and you don't want to support transfer fees
        if (newBalance + amount != initBalance) {
            revert InvalidAmountTransferred();
        }

        emit TransferredSRC20(src20Contract, tokenId, to, amount);
        _afterTransferHeldSRC20FromToken(
            src20Contract,
            tokenId,
            to,
            amount,
            data
        );
    }

    /**
     * @inheritdoc ISRC7590
     */
    function transferSRC20ToToken(
        address src20Contract,
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    ) external {
        if (amount == 0) {
            revert InvalidValue();
        }
        if (src20Contract == address(0)) {
            revert InvalidAddress();
        }
        _beforeTransferSRC20ToToken(
            src20Contract,
            tokenId,
            msg.sender,
            amount,
            data
        );
        ISRC20 src20 = ISRC20(src20Contract);
        uint256 initBalance = src20.balanceOf(address(this));
        src20.transferFrom(msg.sender, address(this), amount);
        uint256 newBalance = src20.balanceOf(address(this));
        // Here you can either use the difference as the amount, or revert if the difference is not equal to the amount and you don't want to support transfer fees
        if (initBalance + amount != newBalance) {
            revert InvalidAmountTransferred();
        }
        _balances[tokenId][src20Contract] += amount;

        emit ReceivedSRC20(src20Contract, tokenId, msg.sender, amount);
        _afterTransferSRC20ToToken(
            src20Contract,
            tokenId,
            msg.sender,
            amount,
            data
        );
    }

    /**
     * @inheritdoc ISRC7590
     */
    function src20TransferOutNonce(
        uint256 tokenId
    ) external view returns (uint256) {
        return _src20TransferOutNonce[tokenId];
    }

    /**
     * @notice Hook that is called before any transfer of SRC-20 tokens from a token
     * @param src20Contract The SRC-20 contract
     * @param tokenId The token to transfer from
     * @param to The address to send the SRC-20 tokens to
     * @param amount The number of SRC-20 tokens to transfer
     * @param data Additional data with no specified format, to allow for custom logic
     */
    function _beforeTransferHeldSRC20FromToken(
        address src20Contract,
        uint256 tokenId,
        address to,
        uint256 amount,
        bytes memory data
    ) internal virtual {}

    /**
     * @notice Hook that is called after any transfer of SRC-20 tokens from a token
     * @param src20Contract The SRC-20 contract
     * @param tokenId The token to transfer from
     * @param to The address to send the SRC-20 tokens to
     * @param amount The number of SRC-20 tokens to transfer
     * @param data Additional data with no specified format, to allow for custom logic
     */
    function _afterTransferHeldSRC20FromToken(
        address src20Contract,
        uint256 tokenId,
        address to,
        uint256 amount,
        bytes memory data
    ) internal virtual {}

    /**
     * @notice Hook that is called before any transfer of SRC-20 tokens to a token
     * @param src20Contract The SRC-20 contract
     * @param tokenId The token to transfer from
     * @param from The address to send the SRC-20 tokens from
     * @param amount The number of SRC-20 tokens to transfer
     * @param data Additional data with no specified format, to allow for custom logic
     */
    function _beforeTransferSRC20ToToken(
        address src20Contract,
        uint256 tokenId,
        address from,
        uint256 amount,
        bytes memory data
    ) internal virtual {}

    /**
     * @notice Hook that is called after any transfer of SRC-20 tokens to a token
     * @param src20Contract The SRC-20 contract
     * @param tokenId The token to transfer from
     * @param from The address to send the SRC-20 tokens from
     * @param amount The number of SRC-20 tokens to transfer
     * @param data Additional data with no specified format, to allow for custom logic
     */
    function _afterTransferSRC20ToToken(
        address src20Contract,
        uint256 tokenId,
        address from,
        uint256 amount,
        bytes memory data
    ) internal virtual {}

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        return type(ISRC7590).interfaceId == interfaceId;
    }
}
