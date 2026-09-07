// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {Solarray} from "solarray/Solarray.sol";
import {SRC721} from "solady/src/tokens/SRC721.sol";
import {TestSRC721} from "./utils/mocks/TestSRC721.sol";
import {OfferItem, ConsiderationItem} from "seaport-types/src/lib/ConsiderationStructs.sol";
import {ItemType, OrderType, Side} from "seaport-sol/src/SeaportEnums.sol";
import {CampaignParams, CampaignRequirements, TraitRedemption} from "../src/lib/RedeemablesStructs.sol";
import {RedeemablesErrors} from "../src/lib/RedeemablesErrors.sol";
import {SRC721RedemptionMintable} from "../src/extensions/SRC721RedemptionMintable.sol";
import {SRC721ShipyardRedeemableOwnerMintable} from "../src/test/SRC721ShipyardRedeemableOwnerMintable.sol";

contract TestSRC721ShipyardRedeemable is RedeemablesErrors, Test {
    event Redemption(
        uint256 indexed campaignId,
        uint256 requirementsIndex,
        bytes32 redemptionHash,
        uint256[] considerationTokenIds,
        uint256[] traitRedemptionTokenIds,
        address redeemedBy
    );

    SRC721ShipyardRedeemableOwnerMintable redeemToken;
    SRC721RedemptionMintable receiveToken;
    address alice;

    address constant _BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    function setUp() public {
        redeemToken = new SRC721ShipyardRedeemableOwnerMintable();
        receiveToken = new SRC721RedemptionMintable(address(redeemToken));
        alice = makeAddr("alice");

        vm.label(address(redeemToken), "redeemToken");
        vm.label(address(receiveToken), "receiveToken");
        vm.label(alice, "alice");
    }

    function testBurnInternalToken() public {
        uint256 tokenId = 2;
        redeemToken.mint(address(this), tokenId);

        OfferItem[] memory offer = new OfferItem[](1);
        offer[0] = OfferItem({
            itemType: ItemType.SRC721_WITH_CRITERIA,
            token: address(receiveToken),
            identifierOrCriteria: 0,
            startAmount: 1,
            endAmount: 1
        });

        ConsiderationItem[] memory consideration = new ConsiderationItem[](1);
        consideration[0] = ConsiderationItem({
            itemType: ItemType.SRC721_WITH_CRITERIA,
            token: address(redeemToken),
            identifierOrCriteria: 0,
            startAmount: 1,
            endAmount: 1,
            recipient: payable(_BURN_ADDRESS)
        });

        CampaignRequirements[] memory requirements = new CampaignRequirements[](
            1
        );
        requirements[0].offer = offer;
        requirements[0].consideration = consideration;

        {
            CampaignParams memory params = CampaignParams({
                requirements: requirements,
                signer: address(0),
                startTime: uint32(block.timestamp),
                endTime: uint32(block.timestamp + 1000),
                maxCampaignRedemptions: 5,
                manager: address(this)
            });

            redeemToken.createCampaign(params, "");
        }

        {
            OfferItem[] memory offerFromEvent = new OfferItem[](1);
            offerFromEvent[0] = OfferItem({
                itemType: ItemType.SRC721,
                token: address(receiveToken),
                identifierOrCriteria: tokenId,
                startAmount: 1,
                endAmount: 1
            });
            ConsiderationItem[] memory considerationFromEvent = new ConsiderationItem[](1);
            considerationFromEvent[0] = ConsiderationItem({
                itemType: ItemType.SRC721,
                token: address(redeemToken),
                identifierOrCriteria: tokenId,
                startAmount: 1,
                endAmount: 1,
                recipient: payable(_BURN_ADDRESS)
            });

            assertGt(uint256(consideration[0].itemType), uint256(considerationFromEvent[0].itemType));

            // campaignId: 1
            // requirementsIndex: 0
            // redemptionHash: bytes32(0)
            bytes memory extraData = abi.encode(1, 0, bytes32(0));
            consideration[0].identifierOrCriteria = tokenId;

            uint256[] memory considerationTokenIds = Solarray.uint256s(tokenId);
            uint256[] memory traitRedemptionTokenIds;

            vm.expectEmit(true, true, true, true);
            emit Redemption(1, 0, bytes32(0), considerationTokenIds, traitRedemptionTokenIds, address(this));
            redeemToken.redeem(considerationTokenIds, address(this), extraData);

            vm.expectRevert(SRC721.TokenDoesNotExist.selector);
            redeemToken.ownerOf(tokenId);

            assertEq(receiveToken.ownerOf(1), address(this));
        }
    }

    function testRevert721ConsiderationItemInsufficientBalance() public {
        uint256 tokenId = 2;
        uint256 invalidTokenId = tokenId + 1;
        redeemToken.mint(address(this), tokenId);
        redeemToken.mint(alice, invalidTokenId);

        OfferItem[] memory offer = new OfferItem[](1);
        offer[0] = OfferItem({
            itemType: ItemType.SRC721_WITH_CRITERIA,
            token: address(receiveToken),
            identifierOrCriteria: 0,
            startAmount: 1,
            endAmount: 1
        });

        ConsiderationItem[] memory consideration = new ConsiderationItem[](1);
        consideration[0] = ConsiderationItem({
            itemType: ItemType.SRC721_WITH_CRITERIA,
            token: address(redeemToken),
            identifierOrCriteria: 0,
            startAmount: 1,
            endAmount: 1,
            recipient: payable(_BURN_ADDRESS)
        });

        CampaignRequirements[] memory requirements = new CampaignRequirements[](
            1
        );
        requirements[0].offer = offer;
        requirements[0].consideration = consideration;

        {
            CampaignParams memory params = CampaignParams({
                requirements: requirements,
                signer: address(0),
                startTime: uint32(block.timestamp),
                endTime: uint32(block.timestamp + 1000),
                maxCampaignRedemptions: 5,
                manager: address(this)
            });

            redeemToken.createCampaign(params, "");
        }

        {
            OfferItem[] memory offerFromEvent = new OfferItem[](1);
            offerFromEvent[0] = OfferItem({
                itemType: ItemType.SRC721,
                token: address(receiveToken),
                identifierOrCriteria: tokenId,
                startAmount: 1,
                endAmount: 1
            });
            ConsiderationItem[] memory considerationFromEvent = new ConsiderationItem[](1);
            considerationFromEvent[0] = ConsiderationItem({
                itemType: ItemType.SRC721,
                token: address(redeemToken),
                identifierOrCriteria: tokenId,
                startAmount: 1,
                endAmount: 1,
                recipient: payable(_BURN_ADDRESS)
            });

            assertGt(uint256(consideration[0].itemType), uint256(considerationFromEvent[0].itemType));

            // campaignId: 1
            // requirementsIndex: 0
            // redemptionHash: bytes32(0)
            bytes memory extraData = abi.encode(1, 0, bytes32(0));
            consideration[0].identifierOrCriteria = tokenId;

            uint256[] memory tokenIds = Solarray.uint256s(invalidTokenId);

            vm.expectRevert(
                abi.encodeWithSelector(
                    ConsiderationItemInsufficientBalance.selector,
                    requirements[0].consideration[0].token,
                    0,
                    requirements[0].consideration[0].startAmount
                )
            );
            redeemToken.redeem(tokenIds, address(this), extraData);

            assertEq(redeemToken.ownerOf(tokenId), address(this));

            vm.expectRevert(SRC721.TokenDoesNotExist.selector);
            receiveToken.ownerOf(1);
        }
    }

    function testRevertConsiderationLengthNotMet() public {
        SRC721ShipyardRedeemableOwnerMintable secondRedeemToken = new SRC721ShipyardRedeemableOwnerMintable();

        uint256 tokenId = 2;
        redeemToken.mint(address(this), tokenId);

        OfferItem[] memory offer = new OfferItem[](1);
        offer[0] = OfferItem({
            itemType: ItemType.SRC721_WITH_CRITERIA,
            token: address(receiveToken),
            identifierOrCriteria: 0,
            startAmount: 1,
            endAmount: 1
        });

        ConsiderationItem[] memory consideration = new ConsiderationItem[](2);
        consideration[0] = ConsiderationItem({
            itemType: ItemType.SRC721_WITH_CRITERIA,
            token: address(redeemToken),
            identifierOrCriteria: 0,
            startAmount: 1,
            endAmount: 1,
            recipient: payable(_BURN_ADDRESS)
        });
        consideration[1] = ConsiderationItem({
            itemType: ItemType.SRC721_WITH_CRITERIA,
            token: address(secondRedeemToken),
            identifierOrCriteria: 0,
            startAmount: 1,
            endAmount: 1,
            recipient: payable(_BURN_ADDRESS)
        });

        CampaignRequirements[] memory requirements = new CampaignRequirements[](
            1
        );
        requirements[0].offer = offer;
        requirements[0].consideration = consideration;

        {
            CampaignParams memory params = CampaignParams({
                requirements: requirements,
                signer: address(0),
                startTime: uint32(block.timestamp),
                endTime: uint32(block.timestamp + 1000),
                maxCampaignRedemptions: 5,
                manager: address(this)
            });

            redeemToken.createCampaign(params, "");
        }

        {
            OfferItem[] memory offerFromEvent = new OfferItem[](1);
            offerFromEvent[0] = OfferItem({
                itemType: ItemType.SRC721,
                token: address(receiveToken),
                identifierOrCriteria: tokenId,
                startAmount: 1,
                endAmount: 1
            });
            ConsiderationItem[] memory considerationFromEvent = new ConsiderationItem[](1);
            considerationFromEvent[0] = ConsiderationItem({
                itemType: ItemType.SRC721,
                token: address(redeemToken),
                identifierOrCriteria: tokenId,
                startAmount: 1,
                endAmount: 1,
                recipient: payable(_BURN_ADDRESS)
            });

            assertGt(uint256(consideration[0].itemType), uint256(considerationFromEvent[0].itemType));

            // campaignId: 1
            // requirementsIndex: 0
            // redemptionHash: bytes32(0)
            bytes memory extraData = abi.encode(1, 0, bytes32(0));
            consideration[0].identifierOrCriteria = tokenId;

            uint256[] memory tokenIds = Solarray.uint256s(tokenId);

            vm.expectRevert(abi.encodeWithSelector(TokenIdsDontMatchConsiderationLength.selector, 2, 1));

            redeemToken.redeem(tokenIds, address(this), extraData);

            assertEq(redeemToken.ownerOf(tokenId), address(this));

            vm.expectRevert(SRC721.TokenDoesNotExist.selector);
            receiveToken.ownerOf(1);
        }
    }

    function testBurnWithSecondConsiderationItem() public {
        SRC721ShipyardRedeemableOwnerMintable secondRedeemToken = new SRC721ShipyardRedeemableOwnerMintable();
        vm.label(address(secondRedeemToken), "secondRedeemToken");
        secondRedeemToken.setApprovalForAll(address(redeemToken), true);

        uint256 tokenId = 2;
        redeemToken.mint(address(this), tokenId);
        secondRedeemToken.mint(address(this), tokenId);

        OfferItem[] memory offer = new OfferItem[](1);
        offer[0] = OfferItem({
            itemType: ItemType.SRC721_WITH_CRITERIA,
            token: address(receiveToken),
            identifierOrCriteria: 0,
            startAmount: 1,
            endAmount: 1
        });

        ConsiderationItem[] memory consideration = new ConsiderationItem[](2);
        consideration[0] = ConsiderationItem({
            itemType: ItemType.SRC721_WITH_CRITERIA,
            token: address(redeemToken),
            identifierOrCriteria: 0,
            startAmount: 1,
            endAmount: 1,
            recipient: payable(_BURN_ADDRESS)
        });
        consideration[1] = ConsiderationItem({
            itemType: ItemType.SRC721_WITH_CRITERIA,
            token: address(secondRedeemToken),
            identifierOrCriteria: 0,
            startAmount: 1,
            endAmount: 1,
            recipient: payable(_BURN_ADDRESS)
        });

        CampaignRequirements[] memory requirements = new CampaignRequirements[](
            1
        );
        requirements[0].offer = offer;
        requirements[0].consideration = consideration;

        {
            CampaignParams memory params = CampaignParams({
                requirements: requirements,
                signer: address(0),
                startTime: uint32(block.timestamp),
                endTime: uint32(block.timestamp + 1000),
                maxCampaignRedemptions: 5,
                manager: address(this)
            });

            redeemToken.createCampaign(params, "");
        }

        {
            OfferItem[] memory offerFromEvent = new OfferItem[](1);
            offerFromEvent[0] = OfferItem({
                itemType: ItemType.SRC721,
                token: address(receiveToken),
                identifierOrCriteria: tokenId,
                startAmount: 1,
                endAmount: 1
            });
            ConsiderationItem[] memory considerationFromEvent = new ConsiderationItem[](1);
            considerationFromEvent[0] = ConsiderationItem({
                itemType: ItemType.SRC721,
                token: address(redeemToken),
                identifierOrCriteria: tokenId,
                startAmount: 1,
                endAmount: 1,
                recipient: payable(_BURN_ADDRESS)
            });

            assertGt(uint256(consideration[0].itemType), uint256(considerationFromEvent[0].itemType));

            // campaignId: 1
            // requirementsIndex: 0
            // redemptionHash: bytes32(0)
            bytes memory extraData = abi.encode(1, 0, bytes32(0));
            consideration[0].identifierOrCriteria = tokenId;

            uint256[] memory tokenIds = Solarray.uint256s(tokenId, tokenId);

            redeemToken.redeem(tokenIds, address(this), extraData);

            vm.expectRevert(SRC721.TokenDoesNotExist.selector);
            redeemToken.ownerOf(tokenId);

            assertEq(secondRedeemToken.ownerOf(tokenId), _BURN_ADDRESS);

            assertEq(receiveToken.ownerOf(1), address(this));
        }
    }

    function testBurnWithSecondRequirementsIndex() public {
        SRC721ShipyardRedeemableOwnerMintable secondRedeemToken = new SRC721ShipyardRedeemableOwnerMintable();
        vm.label(address(secondRedeemToken), "secondRedeemToken");
        secondRedeemToken.setApprovalForAll(address(redeemToken), true);

        uint256 tokenId = 2;
        redeemToken.mint(address(this), tokenId);
        secondRedeemToken.mint(address(this), tokenId);

        OfferItem[] memory offer = new OfferItem[](1);
        offer[0] = OfferItem({
            itemType: ItemType.SRC721_WITH_CRITERIA,
            token: address(receiveToken),
            identifierOrCriteria: 0,
            startAmount: 1,
            endAmount: 1
        });

        ConsiderationItem[] memory consideration = new ConsiderationItem[](1);
        consideration[0] = ConsiderationItem({
            itemType: ItemType.SRC721_WITH_CRITERIA,
            token: address(redeemToken),
            identifierOrCriteria: 0,
            startAmount: 1,
            endAmount: 1,
            recipient: payable(_BURN_ADDRESS)
        });

        ConsiderationItem[] memory secondRequirementConsideration = new ConsiderationItem[](1);
        secondRequirementConsideration[0] = ConsiderationItem({
            itemType: ItemType.SRC721_WITH_CRITERIA,
            token: address(secondRedeemToken),
            identifierOrCriteria: 0,
            startAmount: 1,
            endAmount: 1,
            recipient: payable(_BURN_ADDRESS)
        });

        CampaignRequirements[] memory requirements = new CampaignRequirements[](
            2
        );
        requirements[0].offer = offer;
        requirements[0].consideration = consideration;

        requirements[1].offer = offer;
        requirements[1].consideration = secondRequirementConsideration;

        {
            CampaignParams memory params = CampaignParams({
                requirements: requirements,
                signer: address(0),
                startTime: uint32(block.timestamp),
                endTime: uint32(block.timestamp + 1000),
                maxCampaignRedemptions: 5,
                manager: address(this)
            });

            redeemToken.createCampaign(params, "");
        }

        {
            OfferItem[] memory offerFromEvent = new OfferItem[](1);
            offerFromEvent[0] = OfferItem({
                itemType: ItemType.SRC721,
                token: address(receiveToken),
                identifierOrCriteria: tokenId,
                startAmount: 1,
                endAmount: 1
            });
            ConsiderationItem[] memory considerationFromEvent = new ConsiderationItem[](1);
            considerationFromEvent[0] = ConsiderationItem({
                itemType: ItemType.SRC721,
                token: address(redeemToken),
                identifierOrCriteria: tokenId,
                startAmount: 1,
                endAmount: 1,
                recipient: payable(_BURN_ADDRESS)
            });

            assertGt(uint256(consideration[0].itemType), uint256(considerationFromEvent[0].itemType));

            // campaignId: 1
            // requirementsIndex: 0
            // redemptionHash: bytes32(0)
            bytes memory extraData = abi.encode(1, 1, bytes32(0));
            consideration[0].identifierOrCriteria = tokenId;

            uint256[] memory tokenIds = Solarray.uint256s(tokenId);

            redeemToken.redeem(tokenIds, address(this), extraData);

            assertEq(redeemToken.ownerOf(tokenId), address(this));

            assertEq(secondRedeemToken.ownerOf(tokenId), _BURN_ADDRESS);

            assertEq(receiveToken.ownerOf(1), address(this));
        }
    }
}
