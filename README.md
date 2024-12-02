# Github Repo Link

[Link Portal](https://github.com/zirui2333/Blockchain_Assignment_4)

# Group Members & Emails (if any):

| Name              | Email Address                         | GitHub Username |
| ----------------- | ------------------------------------- | --------------- |
| Zirui Zheng       | zirui.zheng92@myhunter.cuny.edu       | zirui2333       |
| Takibur Chowdhury | Takibur.Chowdhury28@myhunter.cuny.edu | Taki127         |
| Mahim Ali         | Mahim.Ali32@myhunter.cuny.edu         | mahimali937     |
| Justin Wang       | justin.wang29@myhunter.cuny.edu       | nycjustinw      |
<<<<<<< HEAD
| James Crespo      | JAMES.CRESPO64@myhunter.cuny.edu      | jamcre          |
=======
| James Crespo      | JAMES.CRESPO64@myhunter.cuny.edu      | jamcre         |
>>>>>>> 2644f55a8a26d27acf3b74e568da416c3f4dff1a
| Ashfak Uddin      | ashfak.uddin26@myhunter.cuny.edu      | ashfaku         |

# Contract Name: DonationContract

## Purpose of Contract:

The Insurance Trading System is a blockchain-based platform designed to enhance decentralized insurance systems.

## Key Purposes:

### For Customers
1. View Insurance Plans: Customers can view a list of available insurance plans with details like coverage, premium, duration, and provider (company) name.
2. Request Insurance: Submit a request for insurance.
3. Deny Offers: Deny offers provided by the insurance company.
4. Pay Premium: Securely transfer funds for accepted insurance agreements.
5. Rate Company: Provide feedback or ratings for the company after the agreement ends, contributing to the trust system.
Claim Submission: Submit claims to request the claim settlements


### For Companies
1. View Requests: List insurance requests from customers.
2. Evaluate Customer: using historical data and statistical models to predict the likelihood of a future claim
3. Create Plans: Add or modify insurance plans they offer.
4. Request Negotiation: Approve or deny requests and could provide counter-offers.
5. Claim Settlement: Verify and settle claims submitted by customers if insurance conditions are met.


### Platform Administrators (Organization)
1. Charge Fees: Automatically deduct a platform fee for every successful transaction.
2. Ban Participants: Remove users or companies who violate the platform's rules.


# Interface of Contract with function and event headers

<<<<<<< HEAD
````solidity

=======
>>>>>>> 2644f55a8a26d27acf3b74e568da416c3f4dff1a
Donation System

```History_DonateRecived(donor, amount, projectID)```, history details when someone donates a project or event
Donate(projectID), enable people to send Ether to a specific project
GetTotalDonations(), return total amount of donations across all projects


Crowdfunding Platform

```History_CrowdFunding_Withdrawal(owner, amount, projectID)```, history details when someone withdraw funds from a successful crowdfunding campaigns
```Start_Crowdfunding(goal, duration)```, enable people to set up crowdfunding with certain amount and deadline
```Withdraw_CrowdFunding(projectID)```, Allow owner to withdraw funding when goal amount is met


Decentralized Insurance Pool:

```History_InsuranceApproved(Customer, amount)```, history details when insurance approved
```Send_Insurance_Request(amount)```, enable user to claim financial request
```Approve_Insurance_Request(Customer address, amount)```, enable company to approve the request
```Check_Insurance_Pool_Balance()``` Return the amount of available Ether in the current pool


Lottery Contract:

```History_LotteryWin(Winner, amount)```, history details when someone wins a lottery
```Start_Lottery()```, randomly select user as winner and award Ether

<<<<<<< HEAD
``
=======
>>>>>>> 2644f55a8a26d27acf3b74e568da416c3f4dff1a


