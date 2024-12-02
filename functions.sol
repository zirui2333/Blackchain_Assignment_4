// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DecentralizedInsurance {

    struct InsurancePlan {
        uint id; 
        address company;  // Provider name
        string name;  // Plan name
        string description;  // What does this plan do
        uint premium; // in ether
        uint coverageAmount; // Amount covered
        uint duration; // in days
        bool isActive;
    }

    struct Request {
        uint id;
        address customer; 
        uint planId; 
        bool isApproved; // If request is approved or not
    }

    struct Company {
        address addr;  
        string name;
        uint rate;  // Rating and trusting purpose
    }

    struct Customer {
        address addr;
        uint rate;  // Rating and trusting purpose
    }

    uint private platformFee = 5; // 5% platform fee on each transaction
    address private admin;
    uint private next_plan_id = 1;
    uint private next_request_id = 1;

    mapping(uint => InsurancePlan) public insurancePlans;
    mapping(uint => Request) public requests;
    mapping(address => Company) public companies;
    mapping(address => Customer) public customers;

    event PlanCreated(uint planId, address company);
    event RequestSubmitted(uint requestId, address customer, uint planId);
    event RequestResponded(uint requestId, bool isApproved);
    event PremiumPaid(uint planId, address customer, uint amount);

    constructor() {
        admin = msg.sender;
    }

    // CUSTOMER FUNCTIONS

    // Return a list of active plan 
    function viewPlans() external view returns (InsurancePlan[] memory) {
        InsurancePlan[] memory activePlans = new InsurancePlan[](next_plan_id - 1);
        uint index = 0;

        for (uint i = 1; i < next_plan_id; i++) {
            if (insurancePlans[i].isActive) {
                activePlans[index] = insurancePlans[i];
                index++;
            }
        }

        return activePlans;
    }

    // Set a limitation of request a customer can submit
    function submitRequest(uint _planId) external {
        require(insurancePlans[_planId].isActive, "Invalid insurance plan.");

        requests[next_request_id] = Request({
            id: next_request_id,
            customer: msg.sender,
            planId: _planId,
            isApproved: false,
        });

        emit RequestSubmitted(next_request_id, msg.sender, _planId);
        next_request_id++;
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
        payable(plan.company).transfer(msg.value - fee);
        payable(admin).transfer(fee);

        emit PremiumPaid(_planId, msg.sender, msg.value);
    }

    // COMPANY FUNCTIONS

    function createPlan(string memory _name, string memory _description, uint _premium, uint _coverageAmount, uint _duration) external {
        require(companies[msg.sender].addr != address(0), "Not a registered company.");

        insurancePlans[next_plan_id] = InsurancePlan({
            id: next_plan_id,
            company: msg.sender,
            name: _name,
            description: _description,
            premium: _premium,
            coverageAmount: _coverageAmount,
            duration: _duration,
            isActive: true
        });

        emit PlanCreated(next_plan_id, msg.sender);
        next_plan_id++;
    }

    function respondToRequest(uint _requestId, bool _approve) external {
        Request storage req = requests[_requestId];
        InsurancePlan storage plan = insurancePlans[req.planId];
        require(plan.company == msg.sender, "Not authorized.");

        if (_approve) {
            req.isApproved = true;
        } else {
            req.isApproved = false;
        }

        emit RequestResponded(_requestId, req.isApproved);
    }

    // ADMIN FUNCTIONS

    function setPlatformFee(uint _fee) external {
        require(msg.sender == admin, "Only admin.");
        platformFee = _fee;
    }

    function banParticipant(address _addr) external {
        require(msg.sender == admin, "Only admin.");
        delete companies[_addr];
        delete customers[_addr];
    }
}