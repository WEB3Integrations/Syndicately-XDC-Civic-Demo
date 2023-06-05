// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@identity.com/gateway-protocol-eth/contracts/Gated.sol";
import "./MasterNodeFundCertificate.sol";

contract MasterNodeFund is Gated, MasterNodeFundCertificate {
    using SafeERC20 for ERC20;

    uint256 private constant MAX_FUNDS = 10000100 * (10**18);
    uint256 private constant MIN_CONTRIBUTION = 150000 * (10**18);
    uint256 private constant MAX_CONTRIBUTION = 10000000 * (10**18);


    uint256 public currentFunds = 0;
    uint256 public nftCounter = 1;
    uint256 public rewardsStartTime = 0; // if this needs to be private then change it before deploying, but needs to be public for testing via test contract
    
    uint256 private constant REWARDS_PERIOD = 2628000 seconds; // roughly a month
    uint256 private constant LOCK_PERIOD = 94668408 seconds; // 3 years and 8 seconds

    address private payoutAddress;
    ERC20 private xdcToken;

    mapping(address => Investment) public investments;
    mapping(uint256 => uint256) public investmentAmounts;

    struct Investment {
        uint256 amount;
        uint256 time;
        bool claimed;
    }

    constructor(address gatewayTokenContract, uint256 gatekeeperNetworkSlotId, address xdcTokenAddress) 
        Gated(gatewayTokenContract, gatekeeperNetworkSlotId) {
            payoutAddress = msg.sender;
            xdcToken = ERC20(xdcTokenAddress);
    }

    function contribute(uint256 amount) virtual external gated {
        require(currentFunds + amount <= MAX_FUNDS, "Total funds limit reached");
        require(amount >= MIN_CONTRIBUTION && amount <= MAX_CONTRIBUTION, "Invalid contribution amount");

        xdcToken.safeTransferFrom(msg.sender, address(this), amount);

        if (investments[msg.sender].time == 0) {
            _createInvestment(msg.sender, amount);
        } else {
            investments[msg.sender].amount += amount;
        }

        currentFunds += amount;
        
        // Update rewardsStartTime if the goal is reached and rewardsStartTime is not set already
        if (currentFunds >= MAX_FUNDS && rewardsStartTime == 0) {
            rewardsStartTime = block.timestamp + LOCK_PERIOD;
        }
    }

    function _createInvestment(address investor, uint256 amount) private {
        investments[investor] = Investment(amount, block.timestamp, false);
        _mintNFT(investor);
    }

    function _mintNFT(address investor) private {
        uint256 tokenId = nftCounter;
        mint(investor, tokenId);
        nftCounter += 1;
        investmentAmounts[tokenId] = investments[investor].amount;
    }

    function distributeMonthlyRewards(uint256 totalRewardAmount) external {
        require(msg.sender == payoutAddress, "Unauthorized");
        require(block.timestamp >= rewardsStartTime, "Rewards distribution not started");
        
        xdcToken.safeTransferFrom(msg.sender, address(this), totalRewardAmount);

        uint256 tokenId = 1;
        while (tokenId < nftCounter) {
            if (!_exists(tokenId)) {
                tokenId++;
                continue;
            }
            address holder = ownerOf(tokenId);
            uint256 holderInvestment = investmentAmounts[tokenId];
            uint256 holderReward = (holderInvestment * totalRewardAmount) / MAX_FUNDS;
            xdcToken.safeTransfer(holder, holderReward);
            tokenId++;
        }

        rewardsStartTime += REWARDS_PERIOD;
    }

    function claimInitialFunds() external {
        require(block.timestamp >= investments[msg.sender].time + LOCK_PERIOD, "Lock period not ended");
        require(!investments[msg.sender].claimed, "Initial funds already claimed");

        uint256 claimAmount = investments[msg.sender].amount;
        require(claimAmount > 0, "No investment found");
        
        investments[msg.sender].claimed = true;
        xdcToken.safeTransfer(msg.sender, claimAmount);
    }
}