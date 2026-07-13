// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/SRC721/SRC721.sol";
import "@openzeppelin/contracts/token/SRC20/ISRC20.sol";
import "@openzeppelin/contracts/token/SRC20/utils/SafeSRC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./ISRC5725.sol";

abstract contract SRC5725 is ISRC5725, SRC721 {
    using SafeSRC20 for ISRC20;

    /// @dev mapping for claimed payouts
    mapping(uint256 => uint256) /*tokenId*/ /*claimed*/ internal _payoutClaimed;

    /// @dev Mapping from token ID to approved tokenId operator
    mapping(uint256 => address) private _tokenIdApprovals;

    /// @dev Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) /* owner */ /*(operator, isApproved)*/ internal _operatorApprovals;

    /**
     * @notice Checks if the tokenId exists and its valid
     * @param tokenId The NFT token id
     */
    modifier validToken(uint256 tokenId) {
        require(_exists(tokenId), "SRC5725: invalid token ID");
        _;
    }

    /**
     * @dev See {ISRC5725}.
     */
    function claim(uint256 tokenId) external override(ISRC5725) validToken(tokenId) {
        require(isApprovedClaimOrOwner(msg.sender, tokenId), "SRC5725: not owner or operator");

        uint256 amountClaimed = claimablePayout(tokenId);
        require(amountClaimed > 0, "SRC5725: No pending payout");

        emit PayoutClaimed(tokenId, msg.sender, amountClaimed);

        _payoutClaimed[tokenId] += amountClaimed;
        ISRC20(payoutToken(tokenId)).safeTransfer(msg.sender, amountClaimed);
    }

    /**
     * @dev See {ISRC5725}.
     */
    function setClaimApprovalForAll(address operator, bool approved) external override(ISRC5725) {
        _setClaimApprovalForAll(operator, approved);
        emit ClaimApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * @dev See {ISRC5725}.
     */
    function setClaimApproval(
        address operator,
        bool approved,
        uint256 tokenId
    ) external override(ISRC5725) validToken(tokenId) {
        _setClaimApproval(operator, tokenId);
        emit ClaimApproval(msg.sender, operator, tokenId, approved);
    }

    /**
     * @dev See {ISRC5725}.
     */
    function vestedPayout(uint256 tokenId) public view override(ISRC5725) returns (uint256 payout) {
        return vestedPayoutAtTime(tokenId, block.timestamp);
    }

    /**
     * @dev See {ISRC5725}.
     */
    function vestedPayoutAtTime(
        uint256 tokenId,
        uint256 timestamp
    ) public view virtual override(ISRC5725) returns (uint256 payout);

    /**
     * @dev See {ISRC5725}.
     */
    function vestingPayout(
        uint256 tokenId
    ) public view override(ISRC5725) validToken(tokenId) returns (uint256 payout) {
        return _payout(tokenId) - vestedPayout(tokenId);
    }

    /**
     * @dev See {ISRC5725}.
     */
    function claimablePayout(
        uint256 tokenId
    ) public view override(ISRC5725) validToken(tokenId) returns (uint256 payout) {
        return vestedPayout(tokenId) - _payoutClaimed[tokenId];
    }

    /**
     * @dev See {ISRC5725}.
     */
    function claimedPayout(
        uint256 tokenId
    ) public view override(ISRC5725) validToken(tokenId) returns (uint256 payout) {
        return _payoutClaimed[tokenId];
    }

    /**
     * @dev See {ISRC5725}.
     */
    function vestingPeriod(
        uint256 tokenId
    ) public view override(ISRC5725) validToken(tokenId) returns (uint256 vestingStart, uint256 vestingEnd) {
        return (_startTime(tokenId), _endTime(tokenId));
    }

    /**
     * @dev See {ISRC5725}.
     */
    function payoutToken(uint256 tokenId) public view override(ISRC5725) validToken(tokenId) returns (address token) {
        return _payoutToken(tokenId);
    }

    /**
     * @dev See {ISRC165-supportsInterface}.
     * ISRC5725 interfaceId = 0xbd3a202b
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(SRC721, ISRC165) returns (bool supported) {
        return interfaceId == type(ISRC5725).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {ISRC5725}.
     */
    function getClaimApproved(uint256 tokenId) public view returns (address operator) {
        return _tokenIdApprovals[tokenId];
    }

    /**
     * @dev Returns true if `owner` has set `operator` to manage all `tokenId`s.
     * @param owner The owner allowing `operator` to manage all `tokenId`s.
     * @param operator The address who is given permission to spend tokens on behalf of the `owner`.
     */
    function isClaimApprovedForAll(address owner, address operator) public view returns (bool isClaimApproved) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev Public view which returns true if the operator has permission to claim for `tokenId`
     * @notice To remove permissions, set operator to zero address.
     *
     * @param operator The address that has permission for a `tokenId`.
     * @param tokenId The NFT `tokenId`.
     */
    function isApprovedClaimOrOwner(address operator, uint256 tokenId) public view virtual returns (bool) {
        address owner = ownerOf(tokenId);
        return (operator == owner || isClaimApprovedForAll(owner, operator) || getClaimApproved(tokenId) == operator);
    }

    /**
     * @dev Internal function to set the operator status for a given owner to manage all `tokenId`s.
     * @notice To remove permissions, set approved to false.
     *
     * @param operator The address who is given permission to spend vested tokens.
     * @param approved The approved status.
     */
    function _setClaimApprovalForAll(address operator, bool approved) internal virtual {
        _operatorApprovals[msg.sender][operator] = approved;
    }

    /**
     * @dev Internal function to set the operator status for a given tokenId.
     * @notice To remove permissions, set operator to zero address.
     *
     * @param operator The address who is given permission to spend vested tokens.
     * @param tokenId The NFT `tokenId`.
     */
    function _setClaimApproval(address operator, uint256 tokenId) internal virtual {
        require(ownerOf(tokenId) == msg.sender, "SRC5725: not owner of tokenId");
        _tokenIdApprovals[tokenId] = operator;
    }

    /**
     * @dev Internal function to hook into {ISRC721-_afterTokenTransfer}, when a token is being transferred.
     * Removes permissions to _tokenIdApprovals[tokenId] when the tokenId is transferred, burnt, but not on mint.
     *
     * @param from The address from which the tokens are being transferred.
     * @param to The address to which the tokens are being transferred.
     * @param firstTokenId The first tokenId in the batch that is being transferred.
     * @param batchSize The number of tokens being transferred in this batch.
     */
    function _beforeTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize) internal override {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
        if (from != address(0)) {
            delete _tokenIdApprovals[firstTokenId];
        }
    }

    /**
     * @dev Internal function to get the payout token of a given vesting NFT
     *
     * @param tokenId on which to check the payout token address
     * @return address payout token address
     */
    function _payoutToken(uint256 tokenId) internal view virtual returns (address);

    /**
     * @dev Internal function to get the total payout of a given vesting NFT.
     * @dev This is the total that will be paid out to the NFT owner, including historical tokens.
     *
     * @param tokenId to check
     * @return uint256 the total payout of a given vesting NFT
     */
    function _payout(uint256 tokenId) internal view virtual returns (uint256);

    /**
     * @dev Internal function to get the start time of a given vesting NFT
     *
     * @param tokenId to check
     * @return uint256 the start time in epoch timestamp
     */
    function _startTime(uint256 tokenId) internal view virtual returns (uint256);

    /**
     * @dev Internal function to get the end time of a given vesting NFT
     *
     * @param tokenId to check
     * @return uint256 the end time in epoch timestamp
     */
    function _endTime(uint256 tokenId) internal view virtual returns (uint256);
}
