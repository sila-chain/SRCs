// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/SRC721/SRC721.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./interfaces/ISRC6672.sol";

abstract contract SRC6672 is SRC721, ISRC6672 {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    bytes4 public constant ISRC6672_ID = type(ISRC6672).interfaceId;

    mapping(address => mapping(uint256 => mapping(bytes32 => bool))) redemptionStatus;
    mapping(address => mapping(uint256 => mapping(bytes32 => string)))
        public memos;
    mapping(address => mapping(uint256 => EnumerableSet.Bytes32Set)) redemptions;

    constructor() SRC721("Multiple RedeemableNFT", "mrNFT") {}

    function isRedeemed(
        address _operator,
        bytes32 _redemptionId,
        uint256 _tokenId
    ) external view returns (bool) {
        return _isRedeemed(_operator, _redemptionId, _tokenId);
    }

    function getRedemptionIds(
        address _operator,
        uint256 _tokenId
    ) external view returns (bytes32[] memory) {
        require(
            redemptions[_operator][_tokenId].length() > 0,
            "SRC6672: token doesn't have any redemptions."
        );
        return redemptions[_operator][_tokenId].values();
    }

    function redeem(
        bytes32 _redemptionId,
        uint256 _tokenId,
        string memory _memo
    ) external {
        address _operator = msg.sender;
        require(
            !_isRedeemed(_operator, _redemptionId, _tokenId),
            "SRC6672: token already redeemed."
        );
        _update(_operator, _redemptionId, _tokenId, _memo, true);
        redemptions[_operator][_tokenId].add(_redemptionId);
        emit Redeem(
            _operator,
            _tokenId,
            ownerOf(_tokenId),
            _redemptionId,
            _memo
        );
    }

    function cancel(
        bytes32 _redemptionId,
        uint256 _tokenId,
        string memory _memo
    ) external {
        address _operator = msg.sender;
        require(
            _isRedeemed(_operator, _redemptionId, _tokenId),
            "SRC6672: token doesn't redeemed."
        );
        _update(_operator, _redemptionId, _tokenId, _memo, false);
        _removeRedemption(_operator, _redemptionId, _tokenId);
        emit Cancel(_operator, _tokenId, _redemptionId, _memo);
    }

    function _isRedeemed(
        address _operator,
        bytes32 _redemptionId,
        uint256 _tokenId
    ) internal view returns (bool) {
        require(_exists(_tokenId), "SRC6672: token doesn't exists.");
        return redemptionStatus[_operator][_tokenId][_redemptionId];
    }

    function _update(
        address _operator,
        bytes32 _redemptionId,
        uint256 _tokenId,
        string memory _memo,
        bool isRedeemed_
    ) internal {
        redemptionStatus[_operator][_tokenId][_redemptionId] = isRedeemed_;
        memos[_operator][_tokenId][_redemptionId] = _memo;
        if (isRedeemed_) {
            emit Redeem(
                _operator,
                _tokenId,
                ownerOf(_tokenId),
                _redemptionId,
                _memo
            );
        } else {
            emit Cancel(_operator, _tokenId, _redemptionId, _memo);
        }
    }

    function _removeRedemption(
        address _operator,
        bytes32 _redemptionId,
        uint256 _tokenId
    ) internal {
        redemptions[_operator][_tokenId].remove(_redemptionId);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(SRC721, ISRC165) returns (bool) {
        return
            interfaceId == type(ISRC721).interfaceId ||
            interfaceId == type(ISRC6672).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}