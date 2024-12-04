// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DecentralizedInsurance {
    struct InsurancePlan {
        uint id;
        uint companyId; // Changed from address to uint
        string name;
        string description;
        uint premium;
        uint coverageAmount;
        uint duration;
        bool isActive;
    }

    struct Request {
        uint id;
        address customer;
        uint planId;
        bool isApproved;
        bool isClaimed;
        uint claimAmount;
    }

    struct Company {
        uint id;
        address addr; // Using address for company
        string name;
        uint rate;
    }

    struct Customer {
        address addr;
        uint rate;
    }

    uint private platformFee = 5; // 5% platform fee
    address public admin; // Admin address
    uint public nextCompanyId;
    uint private nextPlanId = 1;
    uint private nextRequestId = 1;

    mapping(uint => InsurancePlan) public insurancePlans;
    mapping(uint => Request) public requests;
    mapping(uint => Company) public companies;
    mapping(address => uint256) public companyIds; // Mapping companies by id
    mapping(address => Customer) public customers;

    event PlanCreated(uint planId, uint companyId);
    event RequestSubmitted(uint requestId, address customer, uint planId);
    event RequestResponded(uint requestId, bool isApproved);
    event PremiumPaid(uint planId, address customer, uint amount);
    event ClaimSettled(uint requestId, uint claimAmount);

    constructor() {
        admin = msg.sender; // Set the contract deployer as the admin
        nextCompanyId = 1; // Start with company id 1
    }

    // CUSTOMER FUNCTIONS
    function viewPlans() external view returns (InsurancePlan[] memory) {
        InsurancePlan[] memory activePlans = new InsurancePlan[](
            nextPlanId - 1
        );
        uint index = 0;

        for (uint i = 1; i < nextPlanId; i++) {
            if (insurancePlans[i].isActive) {
                activePlans[index] = insurancePlans[i];
                index++;
            }
        }
        return activePlans;
    }

    function submitRequest(uint _planId) external {
        require(
            customers[msg.sender].addr != address(0),
            "Customer not registered."
        );
        require(insurancePlans[_planId].isActive, "Invalid insurance plan.");

        requests[nextRequestId] = Request({
            id: nextRequestId,
            customer: msg.sender,
            planId: _planId,
            isApproved: false,
            isClaimed: false,
            claimAmount: 0
        });

        emit RequestSubmitted(nextRequestId, msg.sender, _planId);
        nextRequestId++;
    }

    function denyOffer(uint _requestId) external {
        Request storage req = requests[_requestId];
        require(req.customer == msg.sender, "Not authorized.");
        require(!req.isApproved, "Request already approved.");
        req.isApproved = false;
    }

    function payPremium(uint _planId) external payable {
        InsurancePlan storage plan = insurancePlans[_planId];
        require(plan.isActive, "Invalid plan.");
        require(msg.value == plan.premium, "Incorrect premium amount.");

        uint fee = (msg.value * platformFee) / 100;
        payable(companies[plan.companyId].addr).transfer(msg.value - fee); // Corrected transfer line
        payable(admin).transfer(fee);

        emit PremiumPaid(_planId, msg.sender, msg.value);
    }

    // COMPANY FUNCTIONS
    function createPlan(
        string memory _name,
        string memory _description,
        uint _premium,
        uint _coverageAmount,
        uint _duration
    ) external {
        require(
            companies[nextCompanyId].addr != address(0),
            "Not a registered company."
        );

        insurancePlans[nextPlanId] = InsurancePlan({
            id: nextPlanId,
            companyId: nextCompanyId, // Use companyId here
            name: _name,
            description: _description,
            premium: _premium,
            coverageAmount: _coverageAmount,
            duration: _duration,
            isActive: true
        });

        emit PlanCreated(nextPlanId, nextCompanyId);
        nextPlanId++;
    }

    // View all requests for a company
    function viewRequests() external view returns (Request[] memory) {
        uint count = 0;
        uint256 companyId = companyIds[msg.sender];
        for (uint i = 1; i < nextRequestId; i++) {
            if (
                requests[i].planId != 0 &&
                insurancePlans[requests[i].planId].companyId == companyId
            ) {
                count++;
            }
        }

        Request[] memory companyRequests = new Request[](count);
        uint index = 0;
        for (uint i = 1; i < nextRequestId; i++) {
            if (
                requests[i].planId != 0 &&
                insurancePlans[requests[i].planId].companyId == companyId
            ) {
                companyRequests[index] = requests[i];
                index++;
            }
        }
        return companyRequests;
    }

    // Evaluate Customer (stub function)
    function evaluateCustomer(uint _requestId) external view returns (bool) {
        Request storage req = requests[_requestId];
        require(req.customer != address(0), "Request does not exist.");
        // Add your statistical model here
        // Placeholder: assuming that if the customer has a rate above 10, they are deemed low risk
        return customers[req.customer].rate > 6;
    }

    // Approve or deny customer requests, with the option for counter-offers
    function Request_Negotiation(
        uint _requestId,
        bool _approve,
        uint _counterClaimAmount
    ) external {
        Request storage req = requests[_requestId];
        require(
            companies[req.planId].addr == msg.sender,
            "Only the company can evaluate requests."
        );

        if (_approve) {
            req.isApproved = true;
        } else if (_counterClaimAmount > 0) {
            req.claimAmount = _counterClaimAmount;
        }

        emit RequestResponded(_requestId, _approve);
    }

    // Settle claims if conditions are met
    function settleClaim(uint _requestId) external {
        Request storage req = requests[_requestId];
        require(
            companies[req.planId].addr == msg.sender,
            "Only the company can settle claims."
        );
        require(req.isApproved, "Request not approved.");
        require(!req.isClaimed, "Claim already settled.");

        uint claimAmount = insurancePlans[req.planId].coverageAmount >
            req.claimAmount
            ? req.claimAmount
            : insurancePlans[req.planId].coverageAmount;

        // Transfer the claim amount to the customer
        payable(req.customer).transfer(claimAmount);
        req.isClaimed = true;

        emit ClaimSettled(_requestId, claimAmount);
    }

    // ADMIN FUNCTIONS
    function setPlatformFee(uint _fee) external {
        require(msg.sender == admin, "Only admin.");
        platformFee = _fee;
    }

    function banParticipant(uint _companyId) external {
        require(msg.sender == admin, "Only admin.");
        delete companies[_companyId]; // Deleting by companyId
        delete customers[companies[_companyId].addr]; // Delete customer by address linked to company
    }

    function registerCompany(string memory _name, uint _rate) external {
        require(msg.sender == admin, "Only admin.");

        companies[nextCompanyId] = Company({
            id: nextCompanyId,
            addr: msg.sender, // Address of the company owner (or admin registering the company)
            name: _name,
            rate: _rate
        });

        companyIds[msg.sender] = nextCompanyId;
        nextCompanyId++; // Increment to the next company id
    }
}
