// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.15;

contract SRC721ReceiverMock {
    bytes4 constant SRC721_RECEIVED = 0x150b7a02;

    function onSRC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) public returns (bytes4) {
        return SRC721_RECEIVED;
    }
}
