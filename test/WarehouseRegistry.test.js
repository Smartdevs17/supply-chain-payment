const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("WarehouseRegistry", function () {
  let registry, owner, manager1, manager2;
  
  beforeEach(async function () {
    [owner, manager1, manager2] = await ethers.getSigners();
    
    const WarehouseRegistry = await ethers.getContractFactory("WarehouseRegistry");
    registry = await WarehouseRegistry.deploy();
  });
  
  describe("Warehouse Registration", function () {
    it("Should register warehouse successfully", async function () {
      await expect(registry.registerWarehouse(
        "Warehouse A",
        "New York, USA",
        manager1.address,
        10000
      )).to.emit(registry, "WarehouseRegistered");
      
      expect(await registry.getTotalWarehouses()).to.equal(1);
    });
    
    it("Should fail with invalid manager", async function () {
      await expect(
        registry.registerWarehouse(
          "Warehouse A",
          "New York",
          ethers.ZeroAddress,
          10000
        )
      ).to.be.revertedWith("Invalid manager");
    });
    
    it("Should fail if manager already assigned", async function () {
      await registry.registerWarehouse("Warehouse A", "NY", manager1.address, 10000);
      
      await expect(
        registry.registerWarehouse("Warehouse B", "LA", manager1.address, 5000)
      ).to.be.revertedWith("Manager already assigned");
    });
  });
  
  describe("Warehouse Verification", function () {
    it("Should verify warehouse", async function () {
      await registry.registerWarehouse("Warehouse A", "NY", manager1.address, 10000);
      
      await expect(registry.verifyWarehouse(1))
        .to.emit(registry, "WarehouseVerified");
      
      const warehouse = await registry.getWarehouse(1);
      expect(warehouse.isVerified).to.be.true;
    });
  });
  
  describe("Stock Management", function () {
    beforeEach(async function () {
      await registry.registerWarehouse("Warehouse A", "NY", manager1.address, 10000);
    });
    
    it("Should update stock by manager", async function () {
      await expect(registry.connect(manager1).updateStock(1, 5000))
        .to.emit(registry, "StockUpdated")
        .withArgs(1, 5000);
      
      const warehouse = await registry.getWarehouse(1);
      expect(warehouse.currentStock).to.equal(5000);
    });
    
    it("Should update stock by owner", async function () {
      await registry.updateStock(1, 3000);
      
      const warehouse = await registry.getWarehouse(1);
      expect(warehouse.currentStock).to.equal(3000);
    });
    
    it("Should fail if exceeds capacity", async function () {
      await expect(
        registry.connect(manager1).updateStock(1, 15000)
      ).to.be.revertedWith("Exceeds capacity");
    });
    
    it("Should fail if unauthorized", async function () {
      await expect(
        registry.connect(manager2).updateStock(1, 5000)
      ).to.be.revertedWith("Unauthorized");
    });
  });
});
