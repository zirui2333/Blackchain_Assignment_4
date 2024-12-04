import { expect } from "chai"; // Add this import
import pkg from 'hardhat';
const { ethers } = pkg;



// --------------------------------------------  Initialization  --------------------------------------------------

describe("DecentralizedInsurance Contract", function () {
  let admin, nonAdmin, insurance;

  beforeEach(async () => {
    // Get the signers for admin and non-admin
    [admin, nonAdmin] = await ethers.getSigners();

    // Deploy the contract
    const Insurance = await ethers.getContractFactory("DecentralizedInsurance");
    insurance = await Insurance.deploy();
    await insurance.deployed();
  });




// --------------------------------  Test 1. Register Function----------------------------------------
// Only admin can register company, others can't

   console.log("----------------  Test 1. Register Function-------------------------");

  it("Should allow only admin to register a company", async function () {
    // Admin registers the first company
    await insurance.connect(admin).registerCompany("AdminCompany1", 10);

    // Admin registers another company
    await insurance.connect(admin).registerCompany("AdminCompany2", 15);

    // Get the companies registered by admin by companyId
    const company1 = await insurance.companies(1); // companyId 1
    const company2 = await insurance.companies(2); // companyId 2

    // Check if both companies are correctly registered and print their names
    console.log("Admin attempts to create companies...");
    console.log("Name printed: ");
    console.log("Company 1:", company1.name);
    console.log("Company 2:", company2.name);
    console.log("\n");

    // Non-admin attempts to register a company (should fail)
    try {
        console.log("Non-admin attempts to create companies...");
        await insurance.connect(nonAdmin).registerCompany("NonAdminCompany", 20);
    } catch (error) {
        // Print the message that only admin can register a company
        console.log("Error:", "Non-admin cannot register account");
    }


    
});





// ---------------------------  Test 1. User interacts with plans and requests  --------------------------------
/* Scenario:
1. Create 3 plans, conpany1 create 1 plan, company 2 creates 2 plans
2. user pull up a list of plan and interest in one plan(you decide)
3. user check the rate of the company and sends a request to the company for that plan 
4. company pull up the request
5. company check the request and check the customer’s rate.
6. The rate pass and Company send the request back with request amount (say 2000 ether)
7. User accepts the offer
*/



    it("Should allow user to view plans, submit a request, and handle negotiation process", async function () {
        await insurance.connect(admin).registerCompany("AdminCompany1", 10);
        await insurance.connect(admin).registerCompany("AdminCompany2", 15);
        const company1 = await insurance.companies(1); // companyId 1
        const company2 = await insurance.companies(2); // companyId 2
        
        // Step 1: Company1 creates a plan
        await insurance.connect(company1).createPlan("Plan A", "Coverage Plan A", ethers.utils.parseEther("1"), ethers.utils.parseEther("100"), 30);
        // Step 2: Company2 creates two plans
        await insurance.connect(company2).createPlan("Plan B", "Coverage Plan B", ethers.utils.parseEther("2"), ethers.utils.parseEther("200"), 60);
        await insurance.connect(company2).createPlan("Plan C", "Coverage Plan C", ethers.utils.parseEther("3"), ethers.utils.parseEther("300"), 90);

        // Step 3: User pulls up a list of plans and expresses interest in Plan B
        const plans = await insurance.viewPlans();
        console.log("Plans available:", plans);
        const interestedPlanId = plans[1].id; // User is interested in Plan B (Company2's second plan)
        
        // Step 4: User submits a request for Plan B
        await insurance.connect(customer).submitRequest(interestedPlanId);
        
        // Step 5: Company2 pulls up the request and checks the rate of the customer
        const requests = await insurance.connect(company2).viewRequests();
        console.log("Requests for Company2:", requests);

        // Assuming we have a check for customer’s rate
        const isApproved = await insurance.connect(company2).evaluateCustomer(requests[0].id);
        console.log("Is customer approved based on rate:", isApproved);
        
        // Step 6: If rate is passed, Company2 sends a response with a counterclaim amount (e.g., 2000 ether)
        await insurance.connect(company2).Request_Negotiation(requests[0].id, true, ethers.utils.parseEther("2000"));
        
        // Step 7: User accepts the offer
        const requestAfterNegotiation = await insurance.requests(requests[0].id);
        expect(requestAfterNegotiation.isApproved).to.be.true;
        expect(requestAfterNegotiation.claimAmount).to.equal(ethers.utils.parseEther("2000"));
    });
});
