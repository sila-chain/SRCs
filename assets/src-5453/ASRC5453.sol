// SPDX-License-Identifier: CC0.0 OR Apache-2.0
// Author: Zainan Victor Zhou <zzn-ercref@zzn.im>
// See a full runnable hardhat project in https://github.com/ercref/ercref-contracts/tree/main/SRCs/sip-5453
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "@openzeppelin/contracts/utils/cryptography/SIP712.sol";

import "./ISRC5453.sol";

abstract contract ASRC5453Endorsible is SIP712,
    ISRC5453EndorsementCore, ISRC5453EndorsementDigest, ISRC5453EndorsementDataTypeA, ISRC5453EndorsementDataTypeB {
    uint256 private threshold;
    uint256 private currentNonce = 0;
    bytes32 constant MAGIC_WORLD = keccak256("SRC5453-ENDORSEMENT"); // ASCII of "ENDORSED"
    uint256 constant SRC5453_TYPE_A = 1;
    uint256 constant SRC5453_TYPE_B = 2;

    constructor(
        string memory _name,
        string memory _src721Version
    ) SIP712(_name, _src721Version) {}

    function _validate(
        bytes32 msgDigest,
        SingleEndorsementData memory endersement
    ) internal virtual {
        require(
            endersement.sig.length == 65,
            "ASRC5453Endorsible: wrong signature length"
        );
        require(
            SignatureChecker.isValidSignatureNow(
                endersement.endorserAddress,
                msgDigest,
                endersement.sig
            ),
            "ASRC5453Endorsible: invalid signature"
        );
    }

    function _extractEndorsers(
        bytes32 digest,
        GeneralExtensionDataStruct memory data
    ) internal virtual returns (address[] memory endorsers) {
        require(
            data.src5453MagicWord == MAGIC_WORLD,
            "ASRC5453Endorsible: MagicWord not matched"
        );
        require(
            data.validSince <= block.number,
            "ASRC5453Endorsible: Not valid yet"
        ); // TODO consider per-Endorser validSince
        require(data.validBy >= block.number, "ASRC5453Endorsible: Expired"); // TODO consider per-Endorser validBy
        require(
            currentNonce == data.nonce,
            "ASRC5453Endorsible: Nonce not matched"
        ); // TODO consider per-Endorser nonce or range of nonce
        currentNonce += 1;

        if (data.src5453Type == SRC5453_TYPE_A) {
            SingleEndorsementData memory endersement = abi.decode(
                data.endorsementPayload,
                (SingleEndorsementData)
            );
            endorsers = new address[](1);
            endorsers[0] = endersement.endorserAddress;
            _validate(digest, endersement);
        } else if (data.src5453Type == SRC5453_TYPE_B) {
            SingleEndorsementData[] memory endorsements = abi.decode(
                data.endorsementPayload,
                (SingleEndorsementData[])
            );
            endorsers = new address[](endorsements.length);
            for (uint256 i = 0; i < endorsements.length; ++i) {
                endorsers[i] = endorsements[i].endorserAddress;
                _validate(digest, endorsements[i]);
            }
            return endorsers;
        }
    }

    function _decodeExtensionData(
        bytes memory extensionData
    ) internal pure virtual returns (GeneralExtensionDataStruct memory) {
        return abi.decode(extensionData, (GeneralExtensionDataStruct));
    }

    // Well, I know this is epensive. Let's improve it later.
    function _noRepeat(address[] memory _owners) internal pure returns (bool) {
        for (uint256 i = 0; i < _owners.length; i++) {
            for (uint256 j = i + 1; j < _owners.length; j++) {
                if (_owners[i] == _owners[j]) {
                    return false;
                }
            }
        }
        return true;
    }

    function _isEndorsed(
        bytes32 _functionParamStructHash,
        bytes calldata _extraData
    ) internal returns (bool) {
        GeneralExtensionDataStruct memory _data = _decodeExtensionData(
            _extraData
        );
        bytes32 finalDigest = _computeValidityDigest(
            _functionParamStructHash,
            _data.validSince,
            _data.validBy,
            _data.nonce
        );

        address[] memory endorsers = _extractEndorsers(finalDigest, _data);
        require(
            endorsers.length >= threshold,
            "ASRC5453Endorsable: not enough endorsers"
        );
        require(_noRepeat(endorsers));
        for (uint256 i = 0; i < endorsers.length; i++) {
            require(
                _isEligibleEndorser(endorsers[i]),
                "ASRC5453Endorsable: not eligible endorsers"
            ); // everyone must be a legit endorser
        }
        return true;
    }

    function _isEligibleEndorser(
        address /*_endorser*/
    ) internal view virtual returns (bool);

    modifier onlyEndorsed(
        bytes32 _functionParamStructHash,
        bytes calldata _extensionData
    ) {
        require(_isEndorsed(_functionParamStructHash, _extensionData));
        _;
    }

    function _computeValidityDigest(
        bytes32 _functionParamStructHash,
        uint256 _validSince,
        uint256 _validBy,
        uint256 _nonce
    ) internal view returns (bytes32) {
        return
            super._hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "ValidityBound(bytes32 functionParamStructHash,uint256 validSince,uint256 validBy,uint256 nonce)"
                        ),
                        _functionParamStructHash,
                        _validSince,
                        _validBy,
                        _nonce
                    )
                )
            );
    }

    function _computeFunctionParamHash(
        string memory _functionStructure,
        bytes memory _functionParamPacked
    ) internal pure returns (bytes32) {
        bytes32 functionParamStructHash = keccak256(
            abi.encodePacked(
                keccak256(bytes(_functionStructure)),
                _functionParamPacked
            )
        );
        return functionParamStructHash;
    }

    function _setThreshold(uint256 _threshold) internal virtual {
        threshold = _threshold;
    }

    function computeValidityDigest(
        bytes32 _functionParamStructHash,
        uint256 _validSince,
        uint256 _validBy,
        uint256 _nonce
    ) external view override returns (bytes32) {
        return
            _computeValidityDigest(
                _functionParamStructHash,
                _validSince,
                _validBy,
                _nonce
            );
    }

    function computeFunctionParamHash(
        string memory _functionName,
        bytes memory _functionParamPacked
    ) external pure override returns (bytes32) {
        return
            _computeFunctionParamHash(
                _functionName,
                _functionParamPacked
            );
    }

    function sip5453Nonce(address addr) external view override returns (uint256) {
        require(address(this) == addr, "ASRC5453Endorsable: not self");
        return currentNonce;
    }

    function isEligibleEndorser(address _endorser)
        external
        view
        override
        returns (bool)
    {
        return _isEligibleEndorser(_endorser);
    }

    function computeExtensionDataTypeA(
        uint256 nonce,
        uint256 validSince,
        uint256 validBy,
        address endorserAddress,
        bytes calldata sig
    ) external pure override returns (bytes memory) {
        return
            abi.encode(
                GeneralExtensionDataStruct(
                    MAGIC_WORLD,
                    SRC5453_TYPE_A,
                    nonce,
                    validSince,
                    validBy,
                    abi.encode(SingleEndorsementData(endorserAddress, sig))
                )
            );
    }

    function computeExtensionDataTypeB(
        uint256 nonce,
        uint256 validSince,
        uint256 validBy,
        address[] calldata endorserAddress,
        bytes[] calldata sigs
    ) external pure override returns (bytes memory) {
        require(endorserAddress.length == sigs.length);
        SingleEndorsementData[]
            memory endorsements = new SingleEndorsementData[](
                endorserAddress.length
            );
        for (uint256 i = 0; i < endorserAddress.length; ++i) {
            endorsements[i] = SingleEndorsementData(
                endorserAddress[i],
                sigs[i]
            );
        }
        return
            abi.encode(
                GeneralExtensionDataStruct(
                    MAGIC_WORLD,
                    SRC5453_TYPE_B,
                    nonce,
                    validSince,
                    validBy,
                    abi.encode(endorsements)
                )
            );
    }
}
