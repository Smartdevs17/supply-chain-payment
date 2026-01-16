const { ethers } = require("hardhat");

async function main() {
    console.log("Deploying ProductCatalog contract to Base Sepolia...");

    const [deployer] = await ethers.getSigners();
    console.log("Deploying with account:", deployer.address);

    const balance = await ethers.provider.getBalance(deployer.address);
    console.log("Account balance:", ethers.formatEther(balance), "ETH");

    const ProductCatalog = await ethers.getContractFactory("ProductCatalog");
    const productCatalog = await ProductCatalog.deploy();

    await productCatalog.waitForDeployment();

    const contractAddress = await productCatalog.getAddress();
    console.log("ProductCatalog deployed to:", contractAddress);

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
