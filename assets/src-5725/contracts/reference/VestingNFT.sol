// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.17;

import "../SRC5725.sol";

contract VestingNFT is SRC5725 {
    using SafeSRC20 for ISRC20;

    struct VestDetails {
        ISRC20 payoutToken; /// @dev payout token
        uint256 payout; /// @dev payout token remaining to be paid
        uint128 startTime; /// @dev when vesting starts
        uint128 endTime; /// @dev when vesting end
    }
    mapping(uint256 => VestDetails) public vestDetails; /// @dev maps the vesting data with tokenIds

    /// @dev tracker of current NFT id
    uint256 private _tokenIdTracker;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token.
     */
    constructor(string memory name, string memory symbol) SRC721(name, symbol) {}

    /**
     * @notice Creates a new vesting NFT and mints it
     * @dev Token amount should be approved to be transferred by this contract before executing create
     * @param to The recipient of the NFT
     * @param amount The total assets to be locked over time
     * @param releaseTimestamp When the full amount of tokens get released
     * @param token The SRC20 token to vest over time
     */
    function create(address to, uint256 amount, uint128 releaseTimestamp, ISRC20 token) public virtual {
        require(to != address(0), "to cannot be address 0");
        require(releaseTimestamp > block.timestamp, "release must be in future");

        uint256 newTokenId = _tokenIdTracker;

        vestDetails[newTokenId] = VestDetails({
            payoutToken: token,
            payout: amount,
            startTime: uint128(block.timestamp),
            endTime: releaseTimestamp
        });

        _tokenIdTracker++;
        _mint(to, newTokenId);
        ISRC20(payoutToken(newTokenId)).safeTransferFrom(msg.sender, address(this), amount);
    }

    /**
     * @dev See {ISRC5725}.
     */
    function vestedPayoutAtTime(
        uint256 tokenId,
        uint256 timestamp
    ) public view override(SRC5725) validToken(tokenId) returns (uint256 payout) {
        if (timestamp >= _endTime(tokenId)) {
            return _payout(tokenId);
        }
        return 0;
    }

    /**
     * @dev See {SRC5725}.
     */
    function _payoutToken(uint256 tokenId) internal view override returns (address) {
        return address(vestDetails[tokenId].payoutToken);
    }

    /**
     * @dev See {SRC5725}.
     */
    function _payout(uint256 tokenId) internal view override returns (uint256) {
        return vestDetails[tokenId].payout;
    }

    /**
     * @dev See {SRC5725}.
     */
    function _startTime(uint256 tokenId) internal view override returns (uint256) {
        return vestDetails[tokenId].startTime;
    }

    /**
     * @dev See {SRC5725}.
     */
    function _endTime(uint256 tokenId) internal view override returns (uint256) {
        return vestDetails[tokenId].endTime;
    }
}
