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

});




// --------------------------------  Test 1. Register Function----------------------------------------
// Only admin can register company, others can't

console.log("----------------  Test 1. Register Function-------------------------");

  it("Should allow only admin to register a company", async function () {
    await insurance.connect(admin).registerCompany("AdminCompany1", 10);
    await insurance.connect(admin).registerCompany("AdminCompany2", 15);

    // Duplicate test
    try{
        await insurance.connect(admin).registerCompany("AdminCompany1", 66666);
    }catch(error){
        console.log("AdminCompany1 is already registered");
    }
    

    // Get the companies registered by admin by companyId
    const company1 = await insurance.companies(1); // companyId 1
    const company2 = await insurance.companies(2); // companyId 2

    // Check if both companies are correctly registered and print their names
    console.log("Admin attempts to create companies...");
    console.log("Name printed: ");
    console.log("Company 1:", company1.name);
    console.log("Company 2:", company2.name);
    console.log("\n");

    // Admin attempts to register the same company again (should fail)
    try {
        console.log("Admin attempts to register the same company...");
        await insurance.connect(admin).registerCompany("AdminCompany1", 10);
    } catch (error) {
        // Print the message that duplicate registration is not allowed
        console.log("Error:", "Admin cannot register the same company twice");
    }

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
1. Create 3 plans, company1 create 1 plan, company 2 creates 2 plans
2. User pull up a list of plan and interest at one plan
3. User sends a request to the company for that plan 
4. Company pull up the request
5. Company check the request and approces
6. User accepts or denies offer
7. If user accepts then they can register, if they deny do nothing
*/


   it("Should allow user to view plans, submit a request, and handle negotiation process", async function () {
        console.log("\n\n")
        console.log("----------------  Test 2. User interacts with plans and requests --------------------");

        // Register companies
        await insurance.connect(admin).registerCompany("AdminCompany1", 10);
        await insurance.connect(admin).registerCompany("AdminCompany2", 15);

        // Retrieve the company data
        const company1 = await insurance.companies(1); // companyId 1
        const company2 = await insurance.companies(2); // companyId 2

        // Retrieve company data
        const company1Signer = await ethers.getSigner(company1.addr); // Get signer for company1
        const company2Signer = await ethers.getSigner(company2.addr); // Get signer for company2


        // Creates plans
        await insurance.connect(company1Signer).createPlan(
            "Basic Plan",
            "This is a basic plan with testing amount.",
            ethers.utils.parseEther("1.0"), // Premium = 1 ETH
            ethers.utils.parseEther("100.0"), // Coverage amount = 100 ETH
            365 // Duration = 1 year
        );

        console.log("Basic plan created!");
        
        await insurance.connect(company2Signer).createPlan(
            "Premium Plan",
            "This is a premium plan with higher coverage.",
            ethers.utils.parseEther("2.0"), // Premium = 2 ETH
            ethers.utils.parseEther("200.0"), // Coverage amount = 200 ETH
            365 // Duration = 1 year
        );

        await insurance.connect(company2Signer).createPlan(
            "Ultimate Plan",
            "This is the ultimate plan with biggest coverage.",
            ethers.utils.parseEther("3.0"), // Premium = 3 ETH
            ethers.utils.parseEther("500.0"), // Coverage amount = 500 ETH
            365 // Duration = 1 year
        );

        console.log("Ultimate plan and premium plan created!");


        // User view plan and sumbit request
        const plans = await insurance.viewPlans();
        console.log("\nList of Plans:");
        for (let i = 0; i < plans.length; i++) {
            console.log(`Plan`, i + 1, `: `, plans[i].name, `(`, ethers.utils.formatEther(plans[i].premium), `ETH)`);
        }

        // User selects plan and submits request
        console.log("\nUser views the plans and interests at Premium plan");
        let planID = 2;  // Premium plan ID = 2
        try{
            await insurance.connect(customer).submitRequest(planID);
        }catch(error){
            console.log("Error: error in step 2: ", error);
        }
        console.log("User submitted a request to Premium plan company");
        

        // Company pull list and view existing request
        const company2Requests = await insurance.connect(company2Signer).viewRequests();
        console.log("\nCompany 2's Requests:");
        for (let i = 0; i < company2Requests.length; i++) {
            console.log(`Request ${i + 1}: ID: ${company2Requests[i].planId}`);
        }

 
        // Company approves request
        console.log("\nCompany 2 sees the request and approve the request");
        // const requestId = company2Requests[0].id;
        console.log("Company 2 approved the request and sends offer!");

        // try{
        //     await insurance.connect(company2Signer).Request_Negotiation(requestId, true, 0);
        // }catch(error){
        //     console.log("Error in step 4")
        // }

        // const userSigner = await ethers.getSigner(customer.addr);
        // await insurance.connect(userSigner).denyOffer(requestId);

        // console.log("\nUser reviews the offer");
        // const acceptOffer = true; // Depends on the userInput if true = accept/ false = deny


        // NOTE: WHAT HAPPENS IF CUSTOMER IS HIGH RISK? WHEN SHOULD WE CHECK RATE?

    //     if (acceptOffer) {
    //         console.log("User accepts the offer");
    //         await insurance.connect(customer).acceptOffer(requestId);

    //         // User registers after accepting the offer
    //         console.log("User registers as a customer");
    //         await insurance.connect(customer).registerCustomer(8); // Constructor
    //         const registeredCustomer = await insurance.customers(customer.address);
    //         console.log(`Customer registered: ${registeredCustomer.addr}, Risk score: ${registeredCustomer.rate}`);
    //         expect(registeredCustomer.isRegistered).to.be.true; //Check if customer is registered
    //     } else {
    //         console.log("User denies the offer");
    //         await insurance.connect(customer).denyOffer(requestId);
    //         // Ensure the user does not register after denial
    //         const isRegistered = await insurance.customers(customer.address).isRegistered;
    //         expect(isRegistered).to.be.false;
    //         console.log("User did not register since the offer was denied");
    //     }

    //     console.log("Test case completed!");
    });

    
    
})
