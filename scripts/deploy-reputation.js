const { ethers } = require("hardhat");

async function main() {
    console.log("Deploying ReputationSystem contract to Base Sepolia...");

    const [deployer] = await ethers.getSigners();
    console.log("Deploying with account:", deployer.address);

    const balance = await ethers.provider.getBalance(deployer.address);
    console.log("Account balance:", ethers.formatEther(balance), "ETH");

    const ReputationSystem = await ethers.getContractFactory("ReputationSystem");
    const reputationSystem = await ReputationSystem.deploy();

    await reputationSystem.waitForDeployment();

    const contractAddress = await reputationSystem.getAddress();
    console.log("ReputationSystem deployed to:", contractAddress);

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
