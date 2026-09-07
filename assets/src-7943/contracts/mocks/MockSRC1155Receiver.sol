// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;
import {ISRC1155Receiver} from "@openzeppelin/contracts/token/SRC1155/ISRC1155Receiver.sol";
import {ISRC165} from "@openzeppelin/contracts/utils/introspection/ISRC165.sol";

contract MockSRC1155Receiver is ISRC1155Receiver {
    bool public shouldReject = false;
    bytes4 public constant SRC1155_RECEIVER_MAGIC = bytes4(keccak256("onSRC1155Received(address,address,uint256,uint256,bytes)"));
    bytes4 public constant SRC1155_BATCH_RECEIVER_MAGIC = bytes4(keccak256("onSRC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));

    function setShouldReject(bool _reject) external {
        shouldReject = _reject;
    }

    function onSRC1155Received(address, address, uint256, uint256, bytes memory) public view override returns (bytes4) {
        if (shouldReject) {
            return bytes4(0);
        } else {
            return SRC1155_RECEIVER_MAGIC;
        }
    }

    function onSRC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) public view override returns (bytes4) {
        if (shouldReject) {
            return bytes4(0);
        } else {
            return SRC1155_BATCH_RECEIVER_MAGIC;
        }
    }

    function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
        return interfaceId == type(ISRC1155Receiver).interfaceId || interfaceId == type(ISRC165).interfaceId;
    }
}