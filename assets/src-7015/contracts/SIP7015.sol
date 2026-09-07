// SPDX-License-Identifier: CC0-1.0
pragma solidity 0.8.20;
import "@openzeppelin/contracts/utils/cryptography/SIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/interfaces/ISRC1271.sol";

abstract contract SRC7015 is SIP712 {
  error Invalid_Signature();
  event CreatorAttribution(
    bytes32 structHash,
    string domainName,
    string version,
    address creator,
    bytes signature
  );

  /// @notice Define magic value to verify smart contract signatures (SRC1271).
  bytes4 internal constant MAGIC_VALUE =
    bytes4(keccak256("isValidSignature(bytes32,bytes)"));

  function _validateSignature(
    bytes32 structHash,
    address creator,
    bytes memory signature
  ) internal {
    if (!_isValid(structHash, creator, signature)) revert Invalid_Signature();
    emit CreatorAttribution(structHash, "SRC7015", "1", creator, signature);
  }

  function _isValid(
    bytes32 structHash,
    address signer,
    bytes memory signature
  ) internal view returns (bool) {
    require(signer != address(0), "cannot validate");

    bytes32 digest = _hashTypedDataV4(structHash);

    // if smart contract is the signer, verify using SRC-1271 smart-contract
    /// signature verification method
    if (signer.code.length != 0) {
      try ISRC1271(signer).isValidSignature(digest, signature) returns (
        bytes4 magicValue
      ) {
        return MAGIC_VALUE == magicValue;
      } catch {
        return false;
      }
    }

    // otherwise, recover signer and validate that it matches the expected
    // signer
    address recoveredSigner = ECDSA.recover(digest, signature);
    return recoveredSigner == signer;
  }
}
