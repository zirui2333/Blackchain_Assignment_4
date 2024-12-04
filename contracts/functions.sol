// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DecentralizedInsurance {
    // Structure to represent an insurance plan
    struct InsurancePlan {
        uint id; // Unique identifier for the insurance plan
        uint companyId; // ID of the company offering the plan (changed from address to uint)
        string name; // Name of the insurance plan
        string description; // Description of the insurance coverage
        uint premium; // Premium amount for the insurance plan
        uint coverageAmount; // Coverage amount provided by the plan
        uint duration; // Duration of the insurance plan in days
        bool isActive; // Status to check if the plan is active
    }

    // Structure to represent a customer's insurance request
    struct Request {
        uint id; // Unique identifier for the request
        address customer; // Address of the customer making the request
        uint planId; // ID of the insurance plan requested
        bool isApproved; // Approval status of the request by the company
        bool isClaimed; // Status to check if a claim has been made on this request
        uint claimAmount; // Amount claimed by the customer
    }

    // Structure to represent an insurance company
    struct Company {
        uint id; // Unique identifier for the company
        address addr; // Ethereum address of the company
        string name; // Name of the company
        uint rate; // Rating or score of the company
    }

    // Structure to represent a customer
    struct Customer {
        address addr; // Ethereum address of the customer
        uint rate; // Rating or risk score of the customer
        bool isRegistered; //Check to see if customer is added
    }

    uint private platformFee = 5; // Platform fee percentage (5%)
    address public admin; // Address of the platform administrator
    uint public nextCompanyId; // Counter for assigning company IDs
    uint private nextPlanId = 1; // Counter for assigning plan IDs
    uint private nextRequestId = 1; // Counter for assigning request IDs

    mapping(uint => InsurancePlan) public insurancePlans; // Mapping of plan IDs to InsurancePlan structs
    mapping(uint => Request) public requests; // Mapping of request IDs to Request structs
    mapping(uint => Company) public companies; // Mapping of company IDs to Company structs
    mapping(address => uint256) public companyIds; // Mapping of company addresses to their IDs
    mapping(address => Customer) public customers; // Mapping of customer addresses to Customer structs

    // Event emitted when a new insurance plan is created
    event PlanCreated(uint planId, uint companyId);
    // Event emitted when a customer submits a request
    event RequestSubmitted(uint requestId, address customer, uint planId);
    // Event emitted when a company responds to a request
    event RequestResponded(uint requestId, bool isApproved);
    // Event emitted when a customer pays the premium
    event PremiumPaid(uint planId, address customer, uint amount);
    // Event emitted when a claim is settled
    event ClaimSettled(uint requestId, uint claimAmount);

    // Added an event to log registrations
    event CustomerRegistered(address customer, uint rate);

    constructor() {
        admin = msg.sender; // Set the contract deployer as the admin
        nextCompanyId = 1; // Start company IDs from 1
    }
}

    // CUSTOMER FUNCTIONS

function registerCustomer(uint _rate) external {
    // Check if customer is registered
    require(!customers[msg.sender].isRegistered, "Customer already registered.");
    // Register the customer
    customers[msg.sender] = Customer({
        addr: msg.sender,
        rate: _rate,
        isRegistered: true
    });
    // Emit event
    emit CustomerRegistered(msg.sender, _rate);
}

function viewPlans() external view returns (InsurancePlan[] memory) {
    // Create an array to hold active insurance plans
    InsurancePlan[] memory activePlans = new InsurancePlan[](
        nextPlanId - 1
    );
    uint index = 0;

    // Iterate through all insurance plans
    for (uint i = 1; i < nextPlanId; i++) {
        // Check if the insurance plan is active
        if (insurancePlans[i].isActive) {
            // Add the active plan to the array
            activePlans[index] = insurancePlans[i];
            index++;
        }
    }
    // Return the array of active insurance plans
    return activePlans;
}

function submitRequest(uint _planId) external {
    // Ensure the selected insurance plan is active
    require(insurancePlans[_planId].isActive, "Invalid insurance plan.");
    require(customers[msg.sender].isRegistered, "Customer not registered.");

    // Create a new insurance request for the customer
    requests[nextRequestId] = Request({
        id: nextRequestId,
        customer: msg.sender,
        planId: _planId,
        isApproved: false,
        isClaimed: false,
        claimAmount: 0
    });

    // Emit an event indicating the request has been submitted
    emit RequestSubmitted(nextRequestId, msg.sender, _planId);
    // Increment the request ID counter
    nextRequestId++;
}

function denyOffer(uint _requestId) external {
    // Retrieve the request from storage
    Request storage req = requests[_requestId];
    // Ensure the caller is the customer who made the request
    require(req.customer == msg.sender, "Not authorized.");
    // Ensure the request has not already been approved
    require(!req.isApproved, "Request already approved.");
    // Ensure the request has been approved by the company
    require(req.isApproved, "Request is not approved.");
    // Deny the offer by setting isApproved to false
    req.isApproved = false;
}

function acceptOffer(uint _requestId) external {
    Request storage req = requests[_requestId];
    // Ensure the caller is the customer who made the request
    require(req.customer == msg.sender, "Not authorized.");
    // Ensure the request has been approved by the company
    require(req.isApproved, "Request is not approved.");
    // Ensure no claim has already been made on this request
    require(!req.isClaimed, "Request already claimed.");
    // Accept the offer by setting isApproved to true
    req.isClaimed = true;

    // Set the claim amount to the approved amount
    require(req.claimAmount > 0, "Invalid claim amount.");

    payable(req.customer).transfer(req.claimAmount); // Not sure how to check this yet
}


function payPremium(uint _planId) external payable {
    // Retrieve the insurance plan from storage
    InsurancePlan storage plan = insurancePlans[_planId];
    // Ensure the insurance plan is active
    require(plan.isActive, "Invalid plan.");
    // Ensure the sent amount matches the premium amount
    require(msg.value == plan.premium, "Incorrect premium amount.");

    // Calculate the platform fee based on the premium
    uint fee = (msg.value * platformFee) / 100;
    // Transfer the premium minus the fee to the company's address
    payable(companies[plan.companyId].addr).transfer(msg.value - fee); // Corrected transfer line
    // Transfer the platform fee to the admin's address
    payable(admin).transfer(fee);

    // Emit an event indicating the premium has been paid
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
        uint256 companyId = companyIds[msg.sender];
        require(
            companies[companyId].addr != address(0),
            "Not a registered company."
        );
        

        insurancePlans[nextPlanId] = InsurancePlan({
            id: nextPlanId,
            companyId: companyId, // Use companyId here
            name: _name,
            description: _description,
            premium: _premium,
            coverageAmount: _coverageAmount,
            duration: _duration,
            isActive: true
        });

        emit PlanCreated(nextPlanId, companyId);
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
    // Ensure that only the admin can call this function
    require(msg.sender == admin, "Only admin.");
    // Update the platform fee with the new value provided
    platformFee = _fee;
}

function banParticipant(uint _companyId) external {
    // Ensure that only the admin can call this function
    require(msg.sender == admin, "Only admin.");
    // Delete the company from the companies mapping using the company ID
    delete companies[_companyId]; // Deleting by companyId
    // Delete the customer associated with the company's address
    // Note: Accessing companies[_companyId].addr after deletion may result in a default value (address(0))
    delete customers[companies[_companyId].addr]; // Delete customer by address linked to company
}

function registerCompany(string memory _name, uint _rate) external {
    // Ensure that only the admin can call this function
    require(msg.sender == admin, "Only admin.");

    // Check if the company name is already registered
    for (uint i = 1; i < nextCompanyId; i++) {
        require(
            // Strings in Solidity cannot be directly compared (companies[i].name == _name is not valid)
            // So I think using keccak256 hashes the strings for better comparison.
            keccak256(abi.encodePacked(companies[i].name)) != keccak256(abi.encodePacked(_name)), // If the hashes match, names should be identical
            "Company name already registered."
        );
    }

    // Check if the address is already associated with a company
    require(companyIds[msg.sender] == 0, "Company address already registered.");

    // Register a new company and store it in the companies mapping
    companies[nextCompanyId] = Company({
        id: nextCompanyId,
        addr: msg.sender, // Address of the company owner (or admin registering the company)
        name: _name,
        rate: _rate
    });

    // Map the company's address to its company ID
    companyIds[msg.sender] = nextCompanyId;
    // Increment to the next company ID for future registrations
    nextCompanyId++; // Increment to the next company id
}
