const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("SupplyChainPayment Integration Tests", function () {
  let token, supplierRegistry, reputationSystem, productCatalog, payment;
  let owner, buyer, supplier1, supplier2;
  
  before(async function () {
    [owner, buyer, supplier1, supplier2] = await ethers.getSigners();
    
    // Deploy all contracts
    const Token = await ethers.getContractFactory("SupplyChainToken");
    token = await Token.deploy();
    
    const SupplierRegistry = await ethers.getContractFactory("SupplierRegistry");
    supplierRegistry = await SupplierRegistry.deploy();
    
    const ReputationSystem = await ethers.getContractFactory("ReputationSystem");
    reputationSystem = await ReputationSystem.deploy();
    
    const ProductCatalog = await ethers.getContractFactory("ProductCatalog");
    productCatalog = await ProductCatalog.deploy();
    
    const Payment = await ethers.getContractFactory("SupplyChainPayment");
    payment = await Payment.deploy(
      await token.getAddress(),
      await supplierRegistry.getAddress(),
      await reputationSystem.getAddress()
    );
  });
  
  describe("End-to-End Order Flow", function () {
    it("Should complete full order lifecycle", async function () {
      // 1. Register supplier
      await supplierRegistry.registerSupplier(
        "Supplier Inc",
        "Manufacturing",
        supplier1.address
      );
      
      await supplierRegistry.verifySupplier(1);
      
      // 2. Add product to catalog
      await productCatalog.addProduct(
        "Widget A",
        "High quality widget",
        ethers.parseEther("100"),
        supplier1.address
      );
      
      // 3. Mint tokens to buyer
      await token.mint(buyer.address, ethers.parseEther("1000"));
      
      // 4. Buyer approves payment contract
      await token.connect(buyer).approve(
        await payment.getAddress(),
        ethers.parseEther("1000")
      );
      
      // 5. Create order
      await payment.connect(buyer).createOrder(
        supplier1.address,
        ethers.parseEther("500"),
        2 // 2 milestones
      );
      
      // 6. Complete milestones
      await payment.connect(buyer).completeMilestone(1, 1);
      await payment.connect(buyer).completeMilestone(1, 2);
      
      // 7. Verify supplier received payment
      const supplierBalance = await token.balanceOf(supplier1.address);
      expect(supplierBalance).to.equal(ethers.parseEther("500"));
      
      // 8. Check reputation increased
      const reputation = await reputationSystem.getReputation(supplier1.address);
      expect(reputation.score).to.be.gt(0);
    });
  });
  
  describe("Multi-Supplier Scenario", function () {
    it("Should handle multiple concurrent orders", async function () {
      // Register second supplier
      await supplierRegistry.registerSupplier(
        "Supplier Two",
        "Logistics",
        supplier2.address
      );
      
      await supplierRegistry.verifySupplier(2);
      
      // Mint more tokens
      await token.mint(buyer.address, ethers.parseEther("2000"));
      await token.connect(buyer).approve(
        await payment.getAddress(),
        ethers.parseEther("2000")
      );
      
      // Create orders with both suppliers
      await payment.connect(buyer).createOrder(
        supplier1.address,
        ethers.parseEther("300"),
        1
      );
      
      await payment.connect(buyer).createOrder(
        supplier2.address,
        ethers.parseEther("400"),
        1
      );
      
      // Complete both orders
      await payment.connect(buyer).completeMilestone(2, 1);
      await payment.connect(buyer).completeMilestone(3, 1);
      
      // Verify both received payments
      expect(await token.balanceOf(supplier1.address)).to.be.gt(0);
      expect(await token.balanceOf(supplier2.address)).to.be.gt(0);
    });
  });
});
