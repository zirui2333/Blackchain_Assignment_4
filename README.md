# Group Members & Emails (if any):

Zirui Zheng: zirui.zheng92@myhunter.cuny.edu

Takibur Chowdhury: Takibur.Chowdhury28@myhunter.cuny.edu

Mahim Ali: Mahim.Ali32@myhunter.cuny.edu

Justin Wang: justin.wang29@myhunter.cuny.edu

James Crespo: JAMES.CRESPO64@myhunter.cuny.edu

Ashfak Uddin, ashfak.uddin26@myhunter.cuny.edu (Github username: ashfaku)

# Contract Name: ComprehensiveDonationContract

## Purpose of Contract:

The Comprehensive Donation Contract is a multifunctional blockchain-based platform designed to enhance donation systems by integrating additional features such as crowdfunding, decentralized insurance, and a lottery mechanism.

## Key Purposes:

1. Donation System: Facilitate transparent and secure donations for specific causes or projects.
2. Crowdfunding: Enable fundraising campaigns with predefined goals, ensuring funds are accessible only upon reaching the target.
3. Decentralized Insurance Pool: Allocate a portion of donations to an insurance fund, allowing contributors to request financial aid for unforeseen events.
4. Lottery System: Add an incentive for donors by automatically enrolling them into a lottery, rewarding lucky participants with a share of the funds.

This contract ensures transparency, accountability, and user engagement while maintaining a secure and decentralized structure.

# Interface of Contract with function and event headers

```solidity
Donation System

History_DonateRecived(donor, amount, projectID), history details when someone donates a project or event
Donate(projectID), enable people to send Ether to a specific project
GetTotalDonations(), return total amount of donations across all projects


Crowdfunding Platform

History_CrowdFunding_Withdrawal(owner, amount, projectID), history details when someone withdraw funds from a successful crowdfunding campaigns
Start_Crowdfunding(goal, duration), enable people to set up crowdfunding with certain amount and deadline
Withdraw_CrowdFunding(projectID), Allow owner to withdraw funding when goal amount is met


Decentralized Insurance Pool:

History_InsuranceApproved(Customer, amount), history details when insurance approved
Send_Insurance_Request(amount), enable user to claim financial request
Approve_Insurance_Request(Customer address, amount), enable company to approve the request
Check_Insurance_Pool_Balance(): Return the amount of available Ether in the current pool


Lottery Contract:

History_LotteryWin(Winner, amount), history details when someone wins a lottery
Start_Lottery(), randomly select user as winner and award Ether

```

## Detail of Interface

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
/// @title Comprehensive Donation Contract
/// @notice Combines donations, crowdfunding, decentralized insurance, and lottery systems in a single contract
/// @dev All function and event headers follow the Solidity style guide
interface IComprehensiveDonation {
// Events
/// @notice Emitted when a donation is made
/// @param donor The address of the donor
/// @param amount The amount of Ether donated
/// @param projectId The ID of the project receiving the donation
event DonationReceived(address indexed donor, uint256 amount, uint256 indexed projectId);

/// @notice Emitted when funds are withdrawn from a successful crowdfunding campaign
/// @param owner The address of the campaign owner
/// @param amount The amount withdrawn
/// @param projectId The ID of the project
event CrowdfundingWithdrawal(address indexed owner, uint256 amount, uint256 indexed projectId);

/// @notice Emitted when an insurance claim is approved
/// @param claimant The address of the claimant
/// @param amount The amount paid from the insurance pool
event InsuranceClaimApproved(address indexed claimant, uint256 amount);

/// @notice Emitted when a lottery winner is chosen
/// @param winner The address of the winner
/// @param amount The amount won
event LotteryWinnerChosen(address indexed winner, uint256 amount);

// Functions

/// @notice Donate Ether to a specific project
/// @param projectId The ID of the project to donate to
function donate(uint256 projectId) external payable;

/// @notice Start a crowdfunding campaign
/// @param goal The funding goal for the campaign
/// @param duration The duration of the campaign in seconds
/// @return The ID of the newly created project
function startCrowdfunding(uint256 goal, uint256 duration) external returns (uint256);

/// @notice Withdraw funds from a successful crowdfunding campaign
/// @param projectId The ID of the project to withdraw from
function withdrawCrowdfundingFunds(uint256 projectId) external;

/// @notice Submit a claim for financial aid from the insurance pool
/// @param amount The amount being claimed
function submitInsuranceClaim(uint256 amount) external;

/// @notice Approve a submitted insurance claim
/// @param claimant The address of the claimant
/// @param amount The amount to be paid
function approveInsuranceClaim(address claimant, uint256 amount) external;

/// @notice Trigger the lottery and choose a winner
/// @return winner The address of the lottery winner
function triggerLottery() external returns (address);

/// @notice Get the total amount donated to the contract
/// @return The total amount of Ether donated
function getTotalDonations() external view returns (uint256);

/// @notice Get the balance of the insurance pool
/// @return The total amount of Ether in the insurance pool
function getInsurancePoolBalance() external view returns (uint256);

}
```
