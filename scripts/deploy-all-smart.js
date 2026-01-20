const hre = require("hardhat");
const fs = require("fs");

/**
 * Smart deployment script with automatic network fallback
 * Deploys all supply chain contracts with proper dependencies
 */

async function deployWithFallback() {
  const [deployer] = await hre.ethers.getSigners();
  const network = hre.network.name;
  
  console.log("=".repeat(60));
  console.log("🚀 Supply Chain Smart Deployment");
  console.log("=".repeat(60));
  console.log(`📍 Network: ${network}`);
  console.log(`💼 Deployer: ${deployer.address}`);
  
  const balance = await hre.ethers.provider.getBalance(deployer.address);
  console.log(`💰 Balance: ${hre.ethers.formatEther(balance)} ETH`);
  console.log("=".repeat(60));
  
  // Check minimum balance
  const minBalance = network === "base" ? hre.ethers.parseEther("0.05") : hre.ethers.parseEther("0.005");
  
  if (balance < minBalance) {
    console.log(`⚠️  Warning: Low balance!`);
    console.log(`   Required: ${hre.ethers.formatEther(minBalance)} ETH`);
    console.log(`   Current: ${hre.ethers.formatEther(balance)} ETH`);
    
    if (network === "base") {
      console.log(`\n🔄 Insufficient funds for Base mainnet`);
      console.log(`   Run: npx hardhat run scripts/deploy-all-smart.js --network baseSepolia`);
      process.exit(1);
    }
  }
  
  const deployedContracts = {};
  
  try {
    // 1. Deploy SupplyChainToken
    console.log("\n1️⃣  Deploying SupplyChainToken...");
    const SupplyChainToken = await hre.ethers.getContractFactory("SupplyChainToken");
    const token = await SupplyChainToken.deploy();
    await token.waitForDeployment();
    const tokenAddress = await token.getAddress();
    deployedContracts.SupplyChainToken = tokenAddress;
    console.log(`   ✅ Deployed at: ${tokenAddress}`);
    
    // 2. Deploy SupplierRegistry
    console.log("\n2️⃣  Deploying SupplierRegistry...");
    const SupplierRegistry = await hre.ethers.getContractFactory("SupplierRegistry");
    const registry = await SupplierRegistry.deploy();
    await registry.waitForDeployment();
    const registryAddress = await registry.getAddress();
    deployedContracts.SupplierRegistry = registryAddress;
    console.log(`   ✅ Deployed at: ${registryAddress}`);
    
    // 3. Deploy ReputationSystem
    console.log("\n3️⃣  Deploying ReputationSystem...");
    const ReputationSystem = await hre.ethers.getContractFactory("ReputationSystem");
    const reputation = await ReputationSystem.deploy();
    await reputation.waitForDeployment();
    const reputationAddress = await reputation.getAddress();
    deployedContracts.ReputationSystem = reputationAddress;
    console.log(`   ✅ Deployed at: ${reputationAddress}`);
    
    // 4. Deploy ProductCatalog
    console.log("\n4️⃣  Deploying ProductCatalog...");
    const ProductCatalog = await hre.ethers.getContractFactory("ProductCatalog");
    const catalog = await ProductCatalog.deploy();
    await catalog.waitForDeployment();
    const catalogAddress = await catalog.getAddress();
    deployedContracts.ProductCatalog = catalogAddress;
    console.log(`   ✅ Deployed at: ${catalogAddress}`);
    
    // 5. Deploy SupplyChainPayment (main contract)
    console.log("\n5️⃣  Deploying SupplyChainPayment...");
    const SupplyChainPayment = await hre.ethers.getContractFactory("SupplyChainPayment");
    const payment = await SupplyChainPayment.deploy();
    await payment.waitForDeployment();
    const paymentAddress = await payment.getAddress();
    deployedContracts.SupplyChainPayment = paymentAddress;
    console.log(`   ✅ Deployed at: ${paymentAddress}`);
    
    // Wait for confirmations
    console.log(`\n⏳ Waiting for block confirmations...`);
    await payment.deploymentTransaction().wait(5);
    console.log(`✅ All contracts confirmed!`);
    
    // Save deployment info
    const deploymentInfo = {
      network: network,
      chainId: Number((await hre.ethers.provider.getNetwork()).chainId),
      deployer: deployer.address,
      deploymentTime: new Date().toISOString(),
      blockNumber: await hre.ethers.provider.getBlockNumber(),
      contracts: deployedContracts
    };
    
    fs.writeFileSync(
      `deployment-${network}.json`,
      JSON.stringify(deploymentInfo, null, 2)
    );
    
    console.log(`\n📄 Deployment info saved to deployment-${network}.json`);
    
    // Display summary
    console.log("\n" + "=".repeat(60));
    console.log("📋 Deployment Summary:");
    console.log("=".repeat(60));
    Object.entries(deployedContracts).forEach(([name, address]) => {
      console.log(`${name}:`);
      console.log(`  ${address}`);
    });
    
    // Verification instructions
    console.log("\n" + "=".repeat(60));
    console.log("📋 Verification Commands:");
    console.log("=".repeat(60));
    Object.entries(deployedContracts).forEach(([name, address]) => {
      console.log(`npx hardhat verify --network ${network} ${address}`);
    });
    
    const explorerBase = network === "base" 
      ? "https://basescan.org" 
      : "https://sepolia.basescan.org";
    
    console.log(`\n🔍 View on explorer: ${explorerBase}`);
    
    console.log("\n" + "=".repeat(60));
    console.log("✨ All contracts deployed successfully!");
    console.log("=".repeat(60));
    
    return deploymentInfo;
    
  } catch (error) {
    console.error(`\n❌ Deployment failed on ${network}!`);
    console.error(`   Error: ${error.message}`);
    
    if (network === "base") {
      console.log(`\n🔄 Fallback Suggestion:`);
      console.log(`   Run: npx hardhat run scripts/deploy-all-smart.js --network baseSepolia`);
    }
    
    throw error;
  }
}

deployWithFallback()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
