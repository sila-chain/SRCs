// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.19;

import {SRC721ConduitPreapproved_Solady} from "shipyard-core/src/tokens/src721/SRC721ConduitPreapproved_Solady.sol";
import {SRC721} from "solady/src/tokens/SRC721.sol";
import {Ownable} from "solady/src/auth/Ownable.sol";
import {SRC7498NFTRedeemables} from "./lib/SRC7498NFTRedeemables.sol";
import {CampaignParams} from "./lib/RedeemablesStructs.sol";

contract SRC721ShipyardRedeemable is SRC721ConduitPreapproved_Solady, SRC7498NFTRedeemables, Ownable {
    constructor() SRC721ConduitPreapproved_Solady() {
        _initializeOwner(msg.sender);
    }

    function name() public pure override returns (string memory) {
        return "SRC721ShipyardRedeemable";
    }

    function symbol() public pure override returns (string memory) {
        return "SY-RDM";
    }

    function tokenURI(uint256 /* tokenId */ ) public pure override returns (string memory) {
        return "https://example.com/";
    }

    function createCampaign(CampaignParams calldata params, string calldata uri)
        public
        override
        onlyOwner
        returns (uint256 campaignId)
    {
        campaignId = SRC7498NFTRedeemables.createCampaign(params, uri);
    }

    function _useInternalBurn() internal pure virtual override returns (bool) {
        return true;
    }

    function _internalBurn(uint256 id, uint256 /* amount */ ) internal virtual override {
        _burn(id);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(SRC721, SRC7498NFTRedeemables)
        returns (bool)
    {
        return SRC721.supportsInterface(interfaceId) || SRC7498NFTRedeemables.supportsInterface(interfaceId);
    }
}
