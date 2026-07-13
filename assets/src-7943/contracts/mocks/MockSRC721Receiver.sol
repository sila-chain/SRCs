// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;
import {ISRC721Receiver} from "@openzeppelin/contracts/token/SRC721/ISRC721Receiver.sol";

contract MockSRC721Receiver is ISRC721Receiver {
    bool public shouldReject = false;
    bytes4 public constant SRC721_RECEIVER_MAGIC = bytes4(keccak256("onSRC721Received(address,address,uint256,bytes)"));

    function setShouldReject(bool _reject) external {
        shouldReject = _reject;
    }

    function onSRC721Received(address, address, uint256, bytes memory) public view override returns (bytes4) {
        if (shouldReject) {
            return bytes4(0);
        } else {
            return SRC721_RECEIVER_MAGIC;
        }
    }
}