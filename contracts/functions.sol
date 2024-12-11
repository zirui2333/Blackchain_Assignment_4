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
        bool Company_Approved; // Approval status of the request by the company
        bool Customer_Approved; // Approval status of the request by the Customer
        int isActive; // Check the status of request wheter active (1) / draft(0) / decline(-1);
        bool isClaimed; // Status to check if a claim has been made on this request
        uint claimAmount; // Amount claimed by the customer
    }

    // Structure to represent an insurance company
    struct Company {
        uint id; // Unique identifier for the company
        address addr; // Ethereum address of the company
        string name; // Name of the company
        uint customer_rating; // Rating or score of the company
        bool isActive; //Check if company is banned or not;
    }

    // Structure to represent a customer
    struct Customer {
        address addr; // Ethereum address of the customer
        string name;
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
    mapping(string => Customer) public customers; // Mapping of customer addresses to Customer structs
    mapping(string => bool) public bannedCompanyNames; // List of banned companies, bool is set to true if banned

    // Event emitted when a new insurance plan is created
    event PlanCreated(uint planId, uint companyId);
    // Event emitted when a customer submits a request
    event RequestSubmitted(uint requestId, address customer, uint planId);
    // Event emitted when a company responds to a request
    event RequestResponded(uint requestId, bool isApproved);
    // Event emitted when a customer pays the premium
    event PremiumPaid(uint planId, address customer, uint amount);

    // Added an event to log registrations
    event CustomerRegistered(address customer, uint rate);

    constructor() {
        admin = msg.sender; // Set the contract deployer as the admin
        nextCompanyId = 1; // Start company IDs from 1
    }

    // CUSTOMER FUNCTIONS

    modifier adminCheck() {
        require(msg.sender == admin, "Only admin.");
        _;
    }

    function registerCustomer(string memory _name, uint _rate) external {
        // Register the customer (they can self register)
        require(!customers[_name].isRegistered, "Customer already registered.");
        customers[_name] = Customer({
            addr: msg.sender,
            name: _name,
            rate: _rate,
            isRegistered: true
        });
        // Emit event
        emit CustomerRegistered(msg.sender, _rate);
    }

    function getCustomer(
        string memory _name
    ) public view returns (Customer memory) {
        require(customers[_name].isRegistered, "Customer is not registered.");
        // Access control: Only the customer themselves or the admin can retrieve details
        require(
            msg.sender == customers[_name].addr || msg.sender == admin,
            "Not authorized to view customer details." // Throws error if not authorized
        );
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

    function submitRequest(string memory name_, uint _planId) external {
        require(customers[name_].isRegistered, "Customer not registered.");
        // Ensure the selected insurance plan is active
        require(insurancePlans[_planId].isActive, "Invalid insurance plan.");

        // Create a new insurance request for the customer
        requests[nextRequestId] = Request({
            id: nextRequestId,
            customer: msg.sender,
            planId: _planId,
            Company_Approved: false,
            Customer_Approved: false,
            isActive: 0,
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
        //Ensure the Request is currently active
        require(
            req.isActive == 0,
            "Request is either approved or declined. Result is final."
        );
        // Ensure the request has not already been approved
        require(!req.Customer_Approved, "Request already approved.");
        // Ensure the request has been approved by the company
        require(req.Company_Approved, "Request is not approved.");
        // Deny the offer by setting isApproved to false
        req.Customer_Approved = false;
        req.isActive = -1;
    }

    function acceptOffer(uint _requestId) external {
        Request storage req = requests[_requestId];
        // Ensure the caller is the customer who made the request
        require(req.customer == msg.sender, "Not authorized.");
        //Ensure the Request is currently active
        require(
            req.isActive == 0,
            "Request is either approved or declined. Result is final."
        );
        // Ensure the request has been approved by the company
        require(req.Company_Approved, "Request is not approved.");
        // Ensure no claim has already been made on this request
        require(!req.isClaimed, "Request already claimed.");
        // Accept the offer by setting isApproved to true
        req.isClaimed = true;
        req.Customer_Approved = true;
        req.isActive = 1;

        // payable(req.customer).transfer(req.claimAmount); // Not sure how to check this yet
    }

    function payPremium(uint _planId) external payable {
        // Retrieve the insurance plan from storage
        InsurancePlan storage plan = insurancePlans[_planId];
        // Ensure the insurance plan is active
        require(plan.isActive, "Invalid plan.");
        // Ensure the sent amount matches the premium amount
        require(msg.value == plan.premium, "Incorrect premium amount.");
        // Ensures it maps to a valid company
        require(
            companies[plan.companyId].addr != address(0),
            "Invalid company."
        );

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
        require(
            !bannedCompanyNames[companies[companyId].name],
            "Company is banned."
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
    // Approve or deny customer requests, with the option for counter-offers
    function Request_decision_By_Company(
        uint _requestId,
        bool _approve
    ) external {
        Request storage req = requests[_requestId];
        uint256 companyId = companyIds[msg.sender];
        require(
            insurancePlans[requests[_requestId].planId].companyId == companyId,
            "Only the company can evaluate requests."
        );

        //Check the request is currently active or Decline
        require(
            requests[_requestId].isActive == 0,
            "Request is either approved or declined. Result is final."
        );

        require(
            !bannedCompanyNames[companies[companyId].name],
            "Company is banned."
        );

        if (_approve) {
            req.Company_Approved = true;
        } else {
            req.Company_Approved = false;
            req.isActive = -1;
        }

        emit RequestResponded(_requestId, _approve);
    }
    // true to pause plan, false to unpause
    function changePlanStatus(uint _planId, bool _status) external {
        uint256 companyId = companyIds[msg.sender];
        require(
            companies[companyId].addr != address(0),
            "Not a registered company."
        );
        require(
            insurancePlans[_planId].companyId == companyId,
            "Not authorized."
        );
        require(
            insurancePlans[_planId].isActive != _status,
            "No change in status."
        );
        require(
            !bannedCompanyNames[companies[companyId].name],
            "Company is banned."
        );

        insurancePlans[_planId].isActive = _status;
    }

    // ADMIN FUNCTIONS

    function setPlatformFee(uint _fee) external {
        // Ensure that only the admin can call this function
        require(msg.sender == admin, "Only admin.");
        // Update the platform fee with the new value provided
        platformFee = _fee;
    }
    function unbanCompany(string memory _name) external {
        // Ensure only the admin can call this function
        require(msg.sender == admin, "Only admin.");

        // Ensure the company is currently banned
        require(!bannedCompanyNames[_name], "Company is not banned.");

        // Remove the company from the banned list
        bannedCompanyNames[_name] = false;
    }
    function banCompany(uint _companyId) external {
        // Ensure that only the admin can call this function
        require(msg.sender == admin, "Only admin.");

        // Retrieve the company's info before deletion
        string memory companyName = companies[_companyId].name;
        address companyAddress = companies[_companyId].addr;

        bannedCompanyNames[companyName] = true;

        // Delete the company from the companies mapping
        companies[_companyId].isActive = false;
    }

    function registerCompany(string memory _name, uint _rate) external {
        // Ensure that only the admin can call this function
        require(msg.sender == admin, "Only admin.");
        // Ensure that this specific name isn't banned
        require(!bannedCompanyNames[_name], "Company name is banned.");

        // Check if the company name is already registered
        for (uint i = 1; i < nextCompanyId; i++) {
            require(
                // Strings in Solidity cannot be directly compared (companies[i].name == _name is not valid)
                // So I think using keccak256 hashes the strings for better comparison.
                keccak256(abi.encodePacked(companies[i].name)) !=
                    keccak256(abi.encodePacked(_name)), // If the hashes match, names should be identical
                "Company name already registered."
            );
        }

        // Check if the address is already associated with a company
        // require(
        //     companyIds[msg.sender] == 0,
        //     "Company address already registered."
        // );

        // Register a new company and store it in the companies mapping
        companies[nextCompanyId] = Company({
            id: nextCompanyId,
            addr: msg.sender, // Address of the company owner (or admin registering the company)
            name: _name,
            isActive: true,
            customer_rating: _rate
        });

        // Map the company's address to its company ID
        companyIds[msg.sender] = nextCompanyId;
        // Increment to the next company ID for future registrations
        nextCompanyId++; // Increment to the next company id
    }

    function listBannedCompanies() external view returns (string[] memory) {
        // Count the number of banned companies
        uint count = 0;
        for (uint i = 1; i < nextCompanyId; i++) {
            if (bannedCompanyNames[companies[i].name]) {
                count++;
            }
        }

        // Create an array to store the names of banned companies
        string[] memory bannedCompanies = new string[](count);
        uint index = 0;

        // Iterate through the companies and add the banned ones to the array
        for (uint i = 1; i < nextCompanyId; i++) {
            if (bannedCompanyNames[companies[i].name]) {
                bannedCompanies[index] = companies[i].name;
                index++;
            }
        }

        return bannedCompanies; // Return the array of banned company names
    }
}
