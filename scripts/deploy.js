const { ethers } = require("hardhat");

async function main() {
    console.log("Deploying SupplyChainPayment contract to Base Sepolia...");

    const [deployer] = await ethers.getSigners();
    console.log("Deploying with account:", deployer.address);

    const balance = await ethers.provider.getBalance(deployer.address);
    console.log("Account balance:", ethers.formatEther(balance), "ETH");

    const SupplyChainPayment = await ethers.getContractFactory("SupplyChainPayment");
    const supplyChainPayment = await SupplyChainPayment.deploy();

    await supplyChainPayment.waitForDeployment();

    const contractAddress = await supplyChainPayment.getAddress();
    console.log("SupplyChainPayment deployed to:", contractAddress);

    console.log("\n✅ Deployment successful!");
    console.log("📝 Contract Address:", contractAddress);
    console.log("\n🔍 To verify on BaseScan, run:");
    console.log(`npx hardhat verify --network baseSepolia ${contractAddress}`);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
