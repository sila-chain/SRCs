// SPDX-License-Identifier: CC0-1.0
// Author: Zainan Victor Zhou <srcref@zzn.im>
// DRAFTv1
// Source https://github.com/srcref/srcref-contracts/tree/main/SRCs/sip-5269
// Deployment https://goerli.silascan.io/address/0x33F735852619E3f99E1AF069cCf3b9232b2806bE#code
pragma solidity ^0.8.9;
// import 721
import "@openzeppelin/contracts/token/SRC721/SRC721.sol";
// impport 5269
import "../SRC5269.sol";

contract SRC721ForTesting is SRC721, SRC5269 {

    bytes32 constant public SIP_FINAL = keccak256("FINAL");
    constructor() SRC721("SRC721ForTesting", "E721FT") SRC5269() {
        _mint(msg.sender, 0);
        emit OnSupportSIP(address(0x0), 721, bytes32(0), SIP_FINAL, "");
        emit OnSupportSIP(address(0x0), 721, keccak256("SRC721Metadata"), SIP_FINAL, "");
        emit OnSupportSIP(address(0x0), 721, keccak256("SRC721Enumerable"), SIP_FINAL, "");
    }

  function supportSIP(
    address caller,
    uint256 majorSIPIdentifier,
    bytes32 minorSIPIdentifier,
    bytes calldata extraData)
  external
  override
  view
  returns (bytes32 sipStatus) {
    if (majorSIPIdentifier == 721) {
      if (minorSIPIdentifier == 0) {
        return keccak256("FINAL");
      } else if (minorSIPIdentifier == keccak256("SRC721Metadata")) {
        return keccak256("FINAL");
      } else if (minorSIPIdentifier == keccak256("SRC721Enumerable")) {
        return keccak256("FINAL");
      }
    }
    return super._supportSIP(caller, majorSIPIdentifier, minorSIPIdentifier, extraData);
  }
}
