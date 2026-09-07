// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IEvalSIP712Buffer {
    function evalSIP712Buffer(bytes32 domainHash, string memory primaryType, bytes memory typedDataBuffer)
        external
        view
        returns (string[] memory);
}
