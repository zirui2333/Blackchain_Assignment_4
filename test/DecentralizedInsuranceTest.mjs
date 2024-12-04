import { expect } from "chai"; // Add this import
import pkg from 'hardhat';
const { ethers } = pkg;



// --------------------------------------------  Initialization  --------------------------------------------------

describe("DecentralizedInsurance Contract", function () {
  let admin, nonAdmin, insurance, customer;

  beforeEach(async () => {
    // Get the signers for admin, non-admin, and other users
    [admin, nonAdmin, customer] = await ethers.getSigners();

    // Deploy the contract
    const Insurance = await ethers.getContractFactory("DecentralizedInsurance");
    insurance = await Insurance.deploy();
    await insurance.deployed();

    await insurance.connect(admin).registerCompany("AdminCompany1", 10);
    await insurance.connect(admin).registerCompany("AdminCompany2", 15);
});




// --------------------------------  Test 1. Register Function----------------------------------------
// Only admin can register company, others can't

console.log("----------------  Test 1. Register Function-------------------------");

  it("Should allow only admin to register a company", async function () {

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





// ---------------------------  Test 2. User interacts with plans and requests  --------------------------------

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
        const company1 = await insurance.companies(1); // companyId 1
        const company2 = await insurance.companies(2); // companyId 2

        // Step 1: Company 1 creates a plan
        await insurance.connect(company1.addr).createPlan(
            "Basic Plan",
            "This is a basic plan with testing amount.",
            ethers.utils.parseEther("1.0"), // Premium = 1 ETH
            ethers.utils.parseEther("100.0"), // Coverage amount = 100 ETH
            365 // Duration = 1 year
        );

    }); 
})
