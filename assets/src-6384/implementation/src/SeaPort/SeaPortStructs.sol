// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

enum ItemType
// 0: SIL on sila-mainnet, MATIC on polygon, etc.
{
    NATIVE,
    // 1: SRC20 items (SRC777 and SRC20 analogues could also technically work)
    SRC20,
    // 2: SRC721 items
    SRC721,
    // 3: SRC1155 items
    SRC1155,
    // 4: SRC721 items where a number of tokenIds are supported
    SRC721_WITH_CRITERIA,
    // 5: SRC1155 items where a number of ids are supported
    SRC1155_WITH_CRITERIA
}

enum OrderType
// 0: no partial fills, anyone can execute
{
    FULL_OPEN,
    // 1: partial fills supported, anyone can execute
    PARTIAL_OPEN,
    // 2: no partial fills, only offerer or zone can execute
    FULL_RESTRICTED,
    // 3: partial fills supported, only offerer or zone can execute
    PARTIAL_RESTRICTED
}

struct OfferItem {
    ItemType itemType;
    address token;
    uint256 identifierOrCriteria;
    uint256 startAmount;
    uint256 endAmount;
}

struct ConsiderationItem {
    ItemType itemType;
    address token;
    uint256 identifierOrCriteria;
    uint256 startAmount;
    uint256 endAmount;
    address payable recipient;
}

struct OrderComponents {
    address offerer;
    address zone;
    OfferItem[] offer;
    ConsiderationItem[] consideration;
    OrderType orderType;
    uint256 startTime;
    uint256 endTime;
    bytes32 zoneHash;
    uint256 salt;
    bytes32 conduitKey;
    uint256 counter;
}
