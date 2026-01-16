const { ethers } = require("hardhat");

async function main() {
    console.log("Deploying SupplyChainToken contract to Base Sepolia...");

    const [deployer] = await ethers.getSigners();
    console.log("Deploying with account:", deployer.address);

    const balance = await ethers.provider.getBalance(deployer.address);
    console.log("Account balance:", ethers.formatEther(balance), "ETH");

    const SupplyChainToken = await ethers.getContractFactory("SupplyChainToken");
    const token = await SupplyChainToken.deploy();

    await token.waitForDeployment();

    const contractAddress = await token.getAddress();
    console.log("SupplyChainToken deployed to:", contractAddress);

    // Get token details
    const name = await token.name();
    const symbol = await token.symbol();
    const totalSupply = await token.totalSupply();
    
    console.log("\n📊 Token Details:");
    console.log("Name:", name);
    console.log("Symbol:", symbol);
    console.log("Total Supply:", ethers.formatEther(totalSupply), "SCT");

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
