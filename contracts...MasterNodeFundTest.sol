// SPDX-License-Identifier: MIT
// this should NOT ever be deployed to anything other than the test net for testing purposes only

pragma solidity ^0.8.0;


import "./MasterNodeFund.sol";

contract MasterNodeFundTest is MasterNodeFund {
    uint256 public testMaxFunds;
    uint256 public testMinContribution;
    uint256 public testMaxContribution;

    constructor(address gatewayTokenContract, uint256 gatekeeperNetworkSlotId, address xdcTokenAddress) 
        MasterNodeFund(gatewayTokenContract, gatekeeperNetworkSlotId, xdcTokenAddress) {
        _setUpTestValues();
    }

   function _setUpTestValues() private {
        testMaxFunds = 10 * (10**18);
        testMinContribution = 1 * (10**18);
        testMaxContribution = 10 * (10**18);
    }

    function contribute(uint256 amount) override external gated {
        require(currentFunds + amount <= testMaxFunds, "Total funds limit reached");
        require(amount >= testMinContribution && amount <= testMaxContribution, "Invalid contribution amount");

        super.contribute(amount);
    }

    function progressByOneMonth() external {
        rewardsStartTime /= 30 days;
    }


}
