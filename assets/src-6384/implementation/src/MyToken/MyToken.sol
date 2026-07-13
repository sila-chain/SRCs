// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/SRC20/SRC20.sol";
import "@openzeppelin/contracts/utils/cryptography/SIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {IEvalSIP712Buffer} from "../IEvalSIP712Buffer.sol";
import {MyToken712ParserHelper} from "./MyToken712ParserHelper.sol";
import {TransferParameters} from "./MyTokenStructs.sol";

contract MyToken is SRC20, SIP712, IEvalSIP712Buffer {
    mapping(address => uint256) private _nonces;
    address public sip712TransalatorContract;

    bytes32 private constant TYPE_HASH =
        keccak256("SIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    bytes32 private constant TRANSFER_TYPEHASH =
        keccak256("Transfer(address from,address to,uint256 amount,uint256 nonce,uint256 deadline)");

    constructor(address _sip712Transaltor) SRC20("MyToken", "MT") SIP712("MyToken", "1") {
        sip712TransalatorContract = _sip712Transaltor;
        _mint(msg.sender, 1e18);
    }

    function mintToCaller() public {
        _mint(msg.sender, 1e18);
    }

    function nonces(address owner) public view returns (uint256) {
        return _nonces[owner];
    }

    function transferWithSig(address from, address to, uint256 amount, uint256 deadline, uint8 r, bytes32 v, bytes32 s)
        public
    {
        require(block.timestamp <= deadline, "TransferSig: expired deadline");
        bytes32 structHash = keccak256(abi.encode(TRANSFER_TYPEHASH, from, to, amount, _nonces[from]++, deadline));
        // _hashTypedDataV4 is a helper function from SIP712.sol that gets the strcutHash and uses the domain separator in order to hash the message
        bytes32 hash = _hashTypedDataV4(structHash);
        address signer = ECDSA.recover(hash, r, v, s);
        require(signer == from, "TransferSig: unauthorized");
        _transfer(from, to, amount);
    }

    function DOMAIN_SEPARATOR() public view returns (bytes32) {
        return _domainSeparatorV4();
    }

    function evalSIP712Buffer(
        bytes32 domainSeparator,
        string memory primaryType,
        bytes memory typedDataBuffer
    ) public view override returns (string[] memory) {
        require(
            keccak256(abi.encodePacked(primaryType)) == keccak256(abi.encodePacked("Transfer")),
            "MyToken: invalid primary type"
        );
        require(domainSeparator == _domainSeparatorV4(), "MyToken: Invalid domain");
        return MyToken712ParserHelper(sip712TransalatorContract).parseSig(encodedData);
    }
}
