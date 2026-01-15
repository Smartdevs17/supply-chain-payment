const { ethers } = require("hardhat");

async function main() {
    const [deployer] = await ethers.getSigners();
    
    console.log("Interacting with SupplyChainPayment contract...");
    console.log("Using account:", deployer.address);

    // Replace with your deployed contract address
    const CONTRACT_ADDRESS = process.env.CONTRACT_ADDRESS || "0x...";
    
    const SupplyChainPayment = await ethers.getContractFactory("SupplyChainPayment");
    const contract = SupplyChainPayment.attach(CONTRACT_ADDRESS);

    // Get contract info
    console.log("\n=== Contract Information ===");
    console.log("Platform Fee:", await contract.platformFeePercentage(), "%");
    console.log("Total Platform Fees:", ethers.formatEther(await contract.totalPlatformFees()), "ETH");
    console.log("Order Counter:", (await contract.orderCounter()).toString());

    // Example: Get supplier info
    const supplierAddress = process.env.SUPPLIER_ADDRESS;
    if (supplierAddress) {
        console.log("\n=== Supplier Information ===");
        const supplier = await contract.getSupplier(supplierAddress);
        console.log("Name:", supplier.name);
        console.log("Verified:", supplier.isVerified);
        console.log("Orders Completed:", supplier.totalOrdersCompleted.toString());
        console.log("Total Earned:", ethers.formatEther(supplier.totalAmountEarned), "ETH");
    }

    // Example: Get buyer orders
    const buyerAddress = process.env.BUYER_ADDRESS || deployer.address;
    console.log("\n=== Buyer Orders ===");
    const buyerOrders = await contract.getBuyerOrders(buyerAddress);
    console.log("Total Orders:", buyerOrders.length);
    
    for (let i = 0; i < Math.min(buyerOrders.length, 5); i++) {
        const orderId = buyerOrders[i];
        const order = await contract.getOrder(orderId);
        console.log(`\nOrder ${orderId}:`);
        console.log("  Amount:", ethers.formatEther(order.totalAmount), "ETH");
        console.log("  Paid:", ethers.formatEther(order.paidAmount), "ETH");
        console.log("  Status:", order.status);
    }
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
