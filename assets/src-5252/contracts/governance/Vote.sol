// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/SRC20/SRC20.sol";
import "@openzeppelin/contracts/token/SRC20/extensions/draft-SRC20Permit.sol";
import "@openzeppelin/contracts/token/SRC20/extensions/SRC20Votes.sol";
import "@openzeppelin/contracts/governance/Governor.sol";
import "../interfaces/IInfluencer.sol";
import "../interfaces/IABT.sol";

contract MyToken is SRC20, SRC20Permit, SRC20Votes, Governor {
    constructor() SRC20("GovToken", "GOV") SRC20Permit("Governance Token") {}

    mapping(address => uint256[]) private _multiplier;
    address public influencer;

    // The functions below are overrides required by Solidity.

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(SRC20, SRC20Votes) {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount)
        internal
        override(SRC20, SRC20Votes)
    {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount)
        internal
        override(SRC20, SRC20Votes)
    {
        super._burn(account, amount);
    }

    function _sqrt(uint256 x) internal returns (uint256 y) {
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    function getVotes(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        uint256 pos = _checkpoints[account].length;
        uint256 vote = pos == 0 ? 0 : _checkpoints[account][pos - 1].votes;
        // 0 as None, Multiplied with
        uint256 multiplied = _multiplier[pos - 1] > 0
            ? _sqrt(vote)
            : _sqrt(vote * _multiplier[pos - 1]);
        return multiplied;
    }

    function mulInfluence(address abt, uint256 id) public {
        require(IABT(abt).ownerOf(id) == msg.sender, "Vote: not abt owner");
        uint256 pos = _checkpoints[msg.sender].length;
        _multiplier[pos - 1] = IInfluencer.getInfluence(abt, id);
    }

    function setInfluencer(address influencer_) public onlyGovernance {
        influencer = influencer_;
    }
}
