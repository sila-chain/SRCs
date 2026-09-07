/// SPDX-License-Identifier: CC0.0 OR Apache-2.0
// Author: Zainan Victor Zhou <zzn-ercref@zzn.im>
// See a full runnable hardhat project in https://github.com/ercref/ercref-contracts/tree/main/SRCs/sip-5453
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/SRC721/SRC721.sol";

import "./ASRC5453.sol";

contract EndorsableSRC721 is SRC721, ASRC5453Endorsible {
    mapping(address => bool) private owners;

    constructor()
        SRC721("SRC721ForTesting", "SRC721ForTesting")
        ASRC5453Endorsible("EndorsableSRC721", "v1")
    {
        owners[msg.sender] = true;
    }

    function addOwner(address _owner) external {
        require(owners[msg.sender], "EndorsableSRC721: not owner");
        owners[_owner] = true;
    }

    function mint(
        address _to,
        uint256 _tokenId,
        bytes calldata _extraData
    )
        external
        onlyEndorsed(
            _computeFunctionParamHash(
                "function mint(address _to,uint256 _tokenId)",
                abi.encode(_to, _tokenId)
            ),
            _extraData
        )
    {
        _mint(_to, _tokenId);
    }

    function _isEligibleEndorser(
        address _endorser
    ) internal view override returns (bool) {
        return owners[_endorser];
    }
}
