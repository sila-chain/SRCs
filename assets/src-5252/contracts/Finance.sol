// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

import "./interfaces/ISRC20Minimal.sol";
import "./libraries/TransferHelper.sol";
import "./interfaces/IFinance.sol";
import "./interfaces/IABT.sol";
import "./interfaces/IWSIL.sol";
import "./libraries/Initializable.sol";
import "./interfaces/IManager.sol";
import "./interfaces/IInfluencer.sol";

contract Finance is IFinance, Initializable {
    /// Address of a manager
    address public override manager;
    /// Address of a factory
    address public override factory;
    /// Address of a factory
    address public override influencer;
    /// Address of account bound token
    address public override abt;
    /// Finance global identifier
    uint256 public override financeId;
    /// Address of wrapped sil
    address public override WSIL;
    /// Finance Creation Date
    uint256 public override createdAt;
    /// Finance Last Updated Date
    uint256 public override lastUpdated;
    /// deposited amount to the account
    uint256 public override deposit;

    modifier onlyFinanceOwner() {
        require(
            IABT(abt).ownerOf(financeId) == msg.sender,
            "Finance: Finance is not owned by you"
        );
        _;
    }

    // called once by the factory at time of deployment
    function initialize(
        address manager_,
        uint256 financeId_,
        address abt_,
        uint256 amount_,
        address weth_
    ) external override initializer {
        financeId = financeId_;
        abt = abt_;
        WSIL = weth_;
        manager = manager_;
        factory = msg.sender;
        deposit = amount_;
        lastUpdated = block.timestamp;
        createdAt = block.timestamp;
        influencer = IManager(manager_).influencer();
    }

    function depositNative() external payable onlyFinanceOwner {
        // wrap deposit
        deposit += msg.value;
        IInfluencer(influencer).deposit(msg.value);
        IWSIL(WSIL).deposit{value: msg.value}();
        emit DepositFundNative(financeId, msg.value);
    }

    /// Withdraw collateral as native currency
    function withdrawNative(uint256 amount_) external virtual onlyFinanceOwner {
        deposit -= amount_;
        IInfluencer(influencer).withdraw(amount_);
        // unwrap collateral
        IWSIL(WSIL).withdraw(amount_);
        // send withdrawn native currency
        TransferHelper.safeTransferETH(msg.sender, address(this).balance);
        emit WithdrawFundNative(financeId, amount_);
    }

    receive() external payable {
        assert(msg.sender == WSIL); // only accept SIL via fallback from the WSIL contract
    }
}
