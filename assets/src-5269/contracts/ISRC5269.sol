// SPDX-License-Identifier: CC0-1.0
// Author: Zainan Victor Zhou <ercref@zzn.im>
// DRAFTv1
// Source https://github.com/ercref/ercref-contracts/tree/main/SRCs/sip-5269
// Deployment https://goerli.silascan.io/address/0x33F735852619E3f99E1AF069cCf3b9232b2806bE#code
pragma solidity ^0.8.9;

interface ISRC5269 {
  event OnSupportEIP(
      address indexed caller, // when emitted with `address(0x0)` means all callers.
      uint256 indexed majorSIPIdentifier,
      bytes32 indexed minorSIPIdentifier, // 0 means the entire SIP
      bytes32 eipStatus,
      bytes extraData
  );

  /// @dev The core method of SIP/SRC Interface Detection
  /// @param caller, a `address` value of the address of a caller being queried whether the given SIP is supported.
  /// @param majorSIPIdentifier, a `uint256` value and SHOULD BE the SIP number being queried. Unless superseded by future SIP, such SIP number SHOULD BE less or equal to (0, 2^32-1]. For a function call to `supportEIP`, any value outside of this range is deemed unspecified and open to implementation's choice or for future SIPs to specify.
  /// @param minorSIPIdentifier, a `bytes32` value reserved for authors of individual SIP to specify. For example the author of [SIP-721](/SIPS/sip-721) MAY specify `keccak256("SRC721Metadata")` or `keccak256("SRC721Metadata.tokenURI")` as `minorSIPIdentifier` to be quired for support. Author could also use this minorSIPIdentifier to specify different versions, such as SIP-712 has its V1-V4 with different behavior.
  /// @param extraData, a `bytes` for [SIP-5750](/SIPS/sip-5750) for future extensions.
  /// @return eipStatus a bytes32 indicating the status of SIP the contract supports.
  ///                    - For FINAL SIPs, it MUST return `keccak256("FINAL")`.
  ///                    - For non-FINAL SIPs, it SHOULD return `keccak256("DRAFT")`.
  ///                      During SIP procedure, SIP authors are allowed to specify their own
  ///                      eipStatus other than `FINAL` or `DRAFT` at their discretion such as `keccak256("DRAFTv1")`
  ///                      or `keccak256("DRAFT-option1")`and such value of eipStatus MUST be documented in the SIP body
  function supportEIP(
    address caller,
    uint256 majorSIPIdentifier,
    bytes32 minorSIPIdentifier,
    bytes calldata extraData)
  external view returns (bytes32 eipStatus);
}
