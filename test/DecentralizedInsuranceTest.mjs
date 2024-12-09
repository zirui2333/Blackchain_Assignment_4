import { expect } from "chai"; // Importing the Chai assertion library for test expectations
import pkg from 'hardhat'; // Importing Hardhat package to work with smart contracts
const { ethers } = pkg; // Extracting ethers from Hardhat to interact with the blockchain



// -------------------------------------------- Initialization --------------------------------------------------
// Test suite for DecentralizedInsurance contract
describe("DecentralizedInsurance Contract", function () {
let admin, nonAdmin, insurance, customer;

// Setup function that runs before each test case
beforeEach(async () => {
// Get the signers for admin, non-admin, and other users
[admin, nonAdmin, customer] = await ethers.getSigners();

// Deploy the DecentralizedInsurance contract before each test
const Insurance = await ethers.getContractFactory("DecentralizedInsurance");
insurance = await Insurance.deploy();
await insurance.deployed();

});




// -------------------------- Test 1. Register / Ban / Unban company Function---------------------------------
// Only admin can register company, others can't
// Only admin can ban and unban company
/* Scenario:
1. Admin registers a company, only admin has access to registration.
2. Admin tries to register the same company again, should fail.
3. Non-admin attempts to register a company, should fail.
4. Admin bans a company, then unbans it successfully.
*/

console.log("---------------- Test 1. Register Function-------------------------"); 

it("Should allow only admin to register a company", async function () {
await insurance.connect(admin).registerCompany("AdminCompany1", 10); // Register company by admin
await insurance.connect(admin).registerCompany("AdminCompany2", 15); // Register another company

// Duplicate test: Trying to register a company that already exists
try{
await insurance.connect(admin).registerCompany("AdminCompany1", 66666);
}catch(error){
console.log("AdminCompany1 is already registered");
}


// Get the companies registered by admin by companyId
const company1 = await insurance.companies(1); // Retrieve first company data
const company2 = await insurance.companies(2); // Retrieve second company data

// Check if both companies are correctly registered and print their names
console.log("Admin attempts to create companies...");
console.log("Name printed: ");
console.log(`Company 1: ${company1.name}, ID: ${company1.id}`);
console.log(`Company 2: ${company2.name}, ID: ${company2.id}`);
console.log("\n");

// Admin attempts to register the same company again (should fail)
try {
console.log("Admin attempts to register the same company...");
await insurance.connect(admin).registerCompany("AdminCompany1", 10);
} catch (error) {
// Print the message that duplicate registration is not allowed
console.log("Error:", "Admin cannot register the same company twice \n");
}

// Non-admin attempts to register a company (should fail)
try {
console.log("Non-admin attempts to create companies...");
await insurance.connect(nonAdmin).registerCompany("NonAdminCompany", 20);
} catch (error) {
// Print the message that only admin can register a company
console.log("Error:", "Non-admin cannot register account \n");
}


// Admin ban a company
let company_id = company1.id; // Get company ID
try{
await insurance.connect(admin).banCompany(company_id); // Admin bans the company
console.log("Admin deletes a company.");

}catch(error){
console.log(error); // Log any error that occurs while banning the company
}

// Admin unban a company 
try{
await insurance.connect(admin).unbanCompany(company_id); // Admin restores the company
console.log("Admin restore a company");

}catch(error){
console.log(error); // Log any error that occurs while unbanning the company
}

});




// --------------------------- Test 2. User interacts with plans and requests --------------------------------

/* Scenario:
1. Create 3 plans, company1 create 1 plan, company 2 creates 2 plans
2. User pull up a list of plan and interest at one plan
3. User sends a request to the company for that plan 
4. Company pull up the request
5. Company check the request and approces
6. User accepts or denies offer
7. If user accepts then they can register, if they deny do nothing
*/

it("Should allow user to view plans, submit a request, and handle request approval process", async function () {
console.log("\n\n")
console.log("---------------- Test 2. User interacts with plans and requests --------------------");

// Register companies before creating plans
await insurance.connect(admin).registerCompany("AdminCompany1", 10);
await insurance.connect(admin).registerCompany("AdminCompany2", 15);

// Retrieve the company data
const company1 = await insurance.companies(1); // Retrieve first company's data
const company2 = await insurance.companies(2); // Retrieve second company's data

// Retrieve company signers to interact with the contracts
const company1Signer = await ethers.getSigner(company1.addr); // Get signer for company1
const company2Signer = await ethers.getSigner(company2.addr); // Get signer for company2


// Create plans for the companies
await insurance.connect(company1Signer).createPlan(
"Basic Plan", // Plan name
"This is a basic plan with testing amount.", // Plan description
ethers.utils.parseEther("1.0"), // Premium amount (1 ETH)
ethers.utils.parseEther("100.0"), // Coverage amount = 100 ETH
365 // Duration of the plan (1 year)
);

console.log("Basic plan created!");

// Create multiple plans for company2
await insurance.connect(company2Signer).createPlan(
"Premium Plan", // Plan name
"This is a premium plan with higher coverage.", // Plan description
ethers.utils.parseEther("2.0"), // Premium amount = 2 ETH
ethers.utils.parseEther("200.0"), // Coverage amount = 200 ETH
365 // Duration of the plan (1 year)
);

await insurance.connect(company2Signer).createPlan(
"Ultimate Plan", // Plan name
"This is the ultimate plan with biggest coverage.", // Plan description
ethers.utils.parseEther("3.0"), // Premium amount = 3 ETH
ethers.utils.parseEther("500.0"), // Coverage amount = 500 ETH
365 // Duration of the plan (1 year)
);

console.log("Ultimate plan and premium plan created!");

// Register two customers
const customer1 = await insurance.connect(customer).registerCustomer("John", 6);
const customer2 = await insurance.connect(customer).registerCustomer("Amy", 6);

const customer1Signer = await ethers.getSigner(customer1.addr); // Signer for customer1
const customer2Signer = await ethers.getSigner(customer2.addr); // Signer for customer2

// User views the list of plans and shows interest in one of the plans
const plans = await insurance.connect(customer1Signer).viewPlans();
console.log("\nList of Plans:");
for (let i = 0; i < plans.length; i++) {
console.log(`Plan`, i + 1, `: `, plans[i].name, `(`, ethers.utils.formatEther(plans[i].premium), `ETH)`);
}

// User selects the Premium plan and submits a request
console.log("\nUser views the plans and interests at Premium plan");
const customer_name = "John"; // Customer's name
let planID = 2; // Selecting the Premium plan ID = 2
try{
await insurance.connect(customer1Signer).submitRequest(customer_name, planID); // User submits request to company
}catch(error){
console.log("Error: error in step 2: ", error);
}
console.log("User submitted a request to Premium plan company");


// Company pulls list and views existing request
console.log("\nCompany's Requests (Initial Stage):");
await LogCompanyRequests(insurance, company2Signer); // Log company requests


// Company approves request
console.log("\nCompany 2 sees the request and approve the request");
console.log("Company 2 approved the request and sends offer!");

let requestId = 1; // Assuming request ID = 1
try{
await insurance.connect(company2Signer).Request_decision_By_Company(requestId, true); // Approve the request

// Display updated request status after approval
console.log(`\nNew Updated Request Status`)
console.log("\nCompany's Requests (Company Approval):");
await LogCompanyRequests(insurance, company2Signer);
}catch(error){
console.log("Error in step 4", error.message)
}

// Customer accepts the offer
const userSigner = await ethers.getSigner(customer.addr);
await insurance.connect(userSigner).acceptOffer(requestId); // Customer accepts the offer

console.log("\nCompany's Requests (Customer Approval):");
await LogCompanyRequests(insurance, company2Signer); // Log the requests after acceptance


try{
// The company decides on the request with ID 'requestId' and approves it (true means approval)
await insurance.connect(company2Signer).Request_decision_By_Company(requestId, true);

// Print updated requests status
console.log(`\nNew Updated Request Status`)
console.log("\nCompany's Requests (Company Approval):");
// Call LogCompanyRequests to print the company's request details
await LogCompanyRequests(insurance, company2Signer);
}catch(error){
// Catch any errors that occur during the process and print them
console.log("Error in step 4", error.message)
}

// console.log("\nUser reviews the offer");
// const acceptOffer = true; // Depends on the userInput if true = accept/ false = deny


// NOTE: WHAT HAPPENS IF CUSTOMER IS HIGH RISK? WHEN SHOULD WE CHECK RATE?

// if (acceptOffer) {
// console.log("User accepts the offer");
// await insurance.connect(customer).acceptOffer(requestId);

// // User registers after accepting the offer
// console.log("User registers as a customer");
// await insurance.connect(customer).registerCustomer(8); // Constructor
// const registeredCustomer = await insurance.customers(customer.address);
// console.log(`Customer registered: ${registeredCustomer.addr}, Risk score: ${registeredCustomer.rate}`);
// expect(registeredCustomer.isRegistered).to.be.true; //Check if customer is registered
// } else {
// console.log("User denies the offer");
// await insurance.connect(customer).denyOffer(requestId);
// // Ensure the user does not register after denial
// const isRegistered = await insurance.customers(customer.address).isRegistered;
// expect(isRegistered).to.be.false;
// console.log("User did not register since the offer was denied");
// }

// console.log("Test case completed!");
});



})

// -------------------------- Test 3: getCustomer Function Test ---------------------------------

// Scenario:
// 1. Admin registers a customer and retrieves their details correctly.
// 2. Non-admin tries to access customer details, should fail.
// 3. Admin successfully retrieves customer details.
// 4. Customer successfully pays premium for an active plan and the platform fee is applied correctly.
// 5. Invalid plan or incorrect premium amount should fail the transaction.
it("Should return the correct customer details and handle access control", async function () {
console.log("---------------- Test 3: getCustomer Function Test -------------------------");

// Register a customer
await insurance.connect(customer).registerCustomer("Chill Guy", 50);
console.log("Customer registered: Chill Guy");

// Retrieve the customer details
const customerDetails = await insurance.getCustomer("Chill Guy");

// Log and check if the details are correct
console.log("Retrieved customer details:", {
addr: customerDetails.addr,
name: customerDetails.name,
rate: customerDetails.rate,
isRegistered: customerDetails.isRegistered,
});

expect(customerDetails.addr).to.equal(customer.address);
expect(customerDetails.name).to.equal("Chill Guy");
expect(customerDetails.rate).to.equal(50);
expect(customerDetails.isRegistered).to.be.true;

// Non-admin tries to access customer details
try {
await insurance.connect(nonAdmin).getCustomer("Chill Guy");
} catch (error) {
console.log("Unauthorized access attempt by non-admin:", error.message);
expect(error.message).to.include("Not authorized to view customer details.");
}

// Admin retrieves customer details
const adminAccess = await insurance.connect(admin).getCustomer("Chill Guy");
console.log("Admin successfully retrieved customer details:", adminAccess.name);
expect(adminAccess.name).to.equal("Chill Guy");
});


// -------------------------- Test 4: payPremium Function Test ----------------------------------
// Scenario:
// 1. Customer should be able to pay premium for an active plan.
// 2. If the plan does not exist, payment should fail.
// 3. If the premium amount is incorrect, payment should fail.

it("Should allow a customer to pay premium for an active plan", async function () {
console.log("---------------- Test 4: payPremium Function Test -------------------------");

// Set platform fee to 10% for testing
await insurance.connect(admin).setPlatformFee(10);
console.log("Platform fee set to 10%.");

// Get balances before the transaction
const adminBalanceBefore = await ethers.provider.getBalance(admin.address);
const companyBalanceBefore = await ethers.provider.getBalance(company.address);

// Customer pays the premium
const planId = 1;
const premiumAmount = ethers.utils.parseEther("1.0");
console.log("Customer pays premium:", premiumAmount.toString(), "ETH.");

// Pay the premium
await expect(
insurance.connect(customer).payPremium(planId, { value: premiumAmount })
).to.emit(insurance, "PremiumPaid").withArgs(planId, customer.address, premiumAmount);

console.log("Premium paid successfully.");

// Calculate expected amounts
const platformFee = premiumAmount.mul(10).div(100); // 10% fee
const companyShare = premiumAmount.sub(platformFee); // Remaining sent to company

// Get balances after the transaction
const adminBalanceAfter = await ethers.provider.getBalance(admin.address);
const companyBalanceAfter = await ethers.provider.getBalance(company.address);

// Validate balances
expect(adminBalanceAfter.sub(adminBalanceBefore)).to.equal(platformFee);
expect(companyBalanceAfter.sub(companyBalanceBefore)).to.equal(companyShare);

console.log(
`Admin received fee: ${ethers.utils.formatEther(platformFee)} ETH. Company received share: ${ethers.utils.formatEther(
companyShare
)} ETH.`
);
});

it("Should fail if the plan does not exist", async function () {
console.log("---------------- payPremium Nonexistent Plan Test -------------------------");

const premiumAmount = ethers.utils.parseEther("1.0");

// Attempt to pay for a nonexistent plan
await expect(
insurance.connect(customer).payPremium(999, { value: premiumAmount })
).to.be.revertedWith("Invalid plan.");

console.log("Payment for nonexistent plan rejected as expected.");
});

it("Should fail if the incorrect premium amount is sent", async function () {
console.log("---------------- Test 4: payPremium Incorrect Premium Amount Test -------------------------");

const incorrectAmount = ethers.utils.parseEther("0.5"); // Less than the premium
const correctAmount = ethers.utils.parseEther("1.0"); // The actual premium

// Customer sends incorrect premium amount
await expect(
insurance.connect(customer).payPremium(1, { value: incorrectAmount })
).to.be.revertedWith("Incorrect premium amount.");

console.log("Payment with incorrect premium amount rejected as expected.");

// Customer sends the correct amount
await expect(
insurance.connect(customer).payPremium(1, { value: correctAmount })
).to.emit(insurance, "PremiumPaid");

console.log("Payment with correct premium amount succeeded.");
});


// -------------------------- Helper Function: Log Company Requests --------------------------

/**
* Logs the company requests for review, including the plan ID, approval status from the company, 
* and approval status from the customer. 
* 
* @param {Object} insurance - The insurance contract instance.
* @param {Object} companySigner - The signer representing the company.
*/

async function LogCompanyRequests(insurance, companySigner) {
// Retrieve the company requests associated with the provided company signer
let companyRequests = await insurance.connect(companySigner).viewRequests();

// Print the header to indicate the columns for the company requests log
console.log(`Request ID PlanID Company_Approval Customer_Approval\n`);

// Loop through the requests and print details for each request
for (let i = 0; i < companyRequests.length; i++) {
console.log(` ${i + 1} ${companyRequests[i].planId} ${companyRequests[i].Company_Approved} ${companyRequests[i].Customer_Approved}`);
}
}