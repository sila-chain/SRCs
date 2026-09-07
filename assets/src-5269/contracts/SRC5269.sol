// SPDX-License-Identifier: CC0-1.0
// Author: Zainan Victor Zhou <ercref@zzn.im>
// DRAFTv1
// Source https://github.com/ercref/ercref-contracts/tree/main/SRCs/sip-5269
// Deployment https://goerli.silascan.io/address/0x33F735852619E3f99E1AF069cCf3b9232b2806bE#code

pragma solidity ^0.8.9;

import "./ISRC5269.sol";

contract SRC5269 is ISRC5269 {
    bytes32 constant public SIP_STATUS = keccak256("DRAFTv1");
    constructor () {
        emit OnSupportEIP(address(0x0), 5269, bytes32(0), SIP_STATUS, "");
    }

    function _supportEIP(
        address /*caller*/,
        uint256 majorSIPIdentifier,
        bytes32 minorSIPIdentifier,
        bytes calldata /*extraData*/)
    internal virtual view returns (bytes32 eipStatus) {
        if (majorSIPIdentifier == 5269) {
            if (minorSIPIdentifier == bytes32(0)) {
                return SIP_STATUS;
            }
        }
        return bytes32(0);
    }

    function supportEIP(
        address caller,
        uint256 majorSIPIdentifier,
        bytes32 minorSIPIdentifier,
        bytes calldata extraData)
    external virtual view returns (bytes32 eipStatus) {
        return _supportEIP(caller, majorSIPIdentifier, minorSIPIdentifier, extraData);
    }
}
