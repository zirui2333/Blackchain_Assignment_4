# Github Repo Link

[Link Portal](https://github.com/zirui2333/Blockchain_Assignment_4)

# Group Members & Emails (if any):

| Name              | Email Address                         | GitHub Username |
| ----------------- | ------------------------------------- | --------------- |
| Zirui Zheng       | zirui.zheng92@myhunter.cuny.edu       | zirui2333       |
| Takibur Chowdhury | Takibur.Chowdhury28@myhunter.cuny.edu | Taki127         |
| Mahim Ali         | Mahim.Ali32@myhunter.cuny.edu         | mahimali937     |
| Justin Wang       | justin.wang29@myhunter.cuny.edu       | nycjustinw (commits may show up as "Justin Wang" instead)      |
| James Crespo      | JAMES.CRESPO64@myhunter.cuny.edu      | jamcre          |
| Ashfak Uddin      | ashfak.uddin26@myhunter.cuny.edu      | ashfaku         |

# Contract Name: DonationContract

## Purpose of Contract:

The Insurance Trading System is a blockchain-based platform designed to enhance decentralized insurance systems.

## Key Purposes:

### Public Functions

1. `getCustomer`: Customer info
2. `viewPlans`: List the current active plans

### For Customers

1. `RegisterCustomer`: Customers can register an account
2. `SubmitRequest`: Submit a request for insurance.
3. `DenyOffers`: Deny offers provided by the insurance company.
4. `AcceptOffer`: Accept offers provided by the insurance company.
5. `Pay Premium`: Securely transfer funds for accepted insurance agreements.

### For Companies

1. `View Requests`: List insurance requests from customers.
2. `CreatePlans`: Add or modify insurance plans they offer.
3. `Request_decision_By_Company`: Approve or deny requests.
4. `SettleClaim`: Verify and settle claims submitted by customers if insurance conditions are met.

### Platform Administrators (Organization)

1. `SetPlatformFee`: Automatically deduct a platform fee for every successful transaction.
2. `Ban Company`: Remove companies who violate the platform's rules.
3. `Unban Company`: Restore companies who violate the platform's rules.
4. `registerCompany` : Register for new companies
