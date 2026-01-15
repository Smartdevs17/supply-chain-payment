const { ethers } = require("hardhat");

async function main() {
    const [deployer, supplier, buyer] = await ethers.getSigners();
    
    console.log("Running demo scenario...\n");

    // Deploy contract
    console.log("1. Deploying contract...");
    const SupplyChainPayment = await ethers.getContractFactory("SupplyChainPayment");
    const contract = await SupplyChainPayment.deploy();
    await contract.waitForDeployment();
    console.log("   Contract deployed to:", await contract.getAddress());

    // Register supplier
    console.log("\n2. Registering supplier...");
    await contract.connect(supplier).registerSupplier("ACME Corp", "contact@acme.com");
    console.log("   Supplier registered:", supplier.address);

    // Verify supplier
    console.log("\n3. Verifying supplier (owner)...");
    await contract.connect(deployer).verifySupplier(supplier.address);
    console.log("   Supplier verified");

    // Create order
    console.log("\n4. Creating order (buyer)...");
    const orderAmount = ethers.parseEther("1.0");
    await contract.connect(buyer).createOrder(
        supplier.address,
        "100 widgets",
        { value: orderAmount }
    );
    console.log("   Order created with", ethers.formatEther(orderAmount), "ETH");

    // Add milestones
    console.log("\n5. Adding milestones...");
    await contract.connect(buyer).addMilestone(0, "Design approval", 30);
    await contract.connect(buyer).addMilestone(0, "Prototype delivery", 40);
    await contract.connect(buyer).addMilestone(0, "Final delivery", 30);
    console.log("   3 milestones added (30%, 40%, 30%)");

    // Start order
    console.log("\n6. Starting order...");
    await contract.connect(buyer).startOrder(0);
    console.log("   Order started");

    // Complete first milestone
    console.log("\n7. Completing first milestone (supplier)...");
    await contract.connect(supplier).completeMilestone(0, 0);
    console.log("   Milestone 0 marked complete");

    // Approve first milestone
    console.log("\n8. Approving first milestone (buyer)...");
    const balanceBefore = await ethers.provider.getBalance(supplier.address);
    await contract.connect(buyer).approveMilestone(0, 0);
    const balanceAfter = await ethers.provider.getBalance(supplier.address);
    const payment = balanceAfter - balanceBefore;
    console.log("   Milestone 0 approved");
    console.log("   Payment released:", ethers.formatEther(payment), "ETH");

    // Get final stats
    console.log("\n9. Final Statistics:");
    const supplierData = await contract.getSupplier(supplier.address);
    console.log("   Supplier total earned:", ethers.formatEther(supplierData.totalAmountEarned), "ETH");
    console.log("   Platform fees collected:", ethers.formatEther(await contract.totalPlatformFees()), "ETH");
    
    const order = await contract.getOrder(0);
    console.log("   Order paid amount:", ethers.formatEther(order.paidAmount), "ETH");
    console.log("   Order status:", order.status);

    console.log("\n✅ Demo completed successfully!");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
