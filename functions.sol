// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DecentralizedInsurance {

    struct InsurancePlan {
        uint id;
        address company;
        string name;
        string description;
        uint premium; // in Wei
        uint coverageAmount; // Amount insured
        uint duration; // in days
        bool isActive;
    }

    struct Request {
        uint id;
        address customer;
        uint planId;
        bool isApproved;
        bool isDenied;
    }

    struct Company {
        address addr;
        string name;
        uint trustScore;
    }

    struct Customer {
        address addr;
        uint trustScore;
    }

    uint private platformFee = 5; // 5% platform fee on each transaction
    address private admin;
    uint private nextPlanId = 1;
    uint private nextRequestId = 1;

    mapping(uint => InsurancePlan) public insurancePlans;
    mapping(uint => Request) public requests;
    mapping(address => Company) public companies;
    mapping(address => Customer) public customers;

    event PlanCreated(uint planId, address company);
    event RequestSubmitted(uint requestId, address customer, uint planId);
    event RequestResponded(uint requestId, bool isApproved, bool isDenied);
    event PremiumPaid(uint planId, address customer, uint amount);

    constructor() {
        admin = msg.sender;
    }

    // CUSTOMER FUNCTIONS

    function viewPlans() external view returns (InsurancePlan[] memory) {
        InsurancePlan[] memory activePlans = new InsurancePlan[](nextPlanId - 1);
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
        require(insurancePlans[_planId].isActive, "Invalid insurance plan.");

        requests[nextRequestId] = Request({
            id: nextRequestId,
            customer: msg.sender,
            planId: _planId,
            isApproved: false,
            isDenied: false
        });

        emit RequestSubmitted(nextRequestId, msg.sender, _planId);
        nextRequestId++;
    }

    function denyOffer(uint _requestId) external {
        Request storage req = requests[_requestId];
        require(req.customer == msg.sender, "Not authorized.");
        require(!req.isApproved, "Request already approved.");
        req.isDenied = true;
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

        insurancePlans[nextPlanId] = InsurancePlan({
            id: nextPlanId,
            company: msg.sender,
            name: _name,
            description: _description,
            premium: _premium,
            coverageAmount: _coverageAmount,
            duration: _duration,
            isActive: true
        });

        emit PlanCreated(nextPlanId, msg.sender);
        nextPlanId++;
    }

    function respondToRequest(uint _requestId, bool _approve) external {
        Request storage req = requests[_requestId];
        InsurancePlan storage plan = insurancePlans[req.planId];
        require(plan.company == msg.sender, "Not authorized.");

        if (_approve) {
            req.isApproved = true;
        } else {
            req.isDenied = true;
        }

        emit RequestResponded(_requestId, req.isApproved, req.isDenied);
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