const { expect } = require("chai");
const { ethers } = require("hardhat");
const { loadFixture } = require("@nomicfoundation/hardhat-toolbox/network-helpers");

describe("SupplierRegistry", function () {
  async function deployFixture() {
    const [owner, supplier, otherAccount] = await ethers.getSigners();

    const SupplierRegistry = await ethers.getContractFactory("SupplierRegistry");
    const registry = await SupplierRegistry.deploy();

    return { registry, owner, supplier, otherAccount };
  }

  describe("Registration", function () {
    it("Should register a new supplier successfully", async function () {
      const { registry, supplier } = await loadFixture(deployFixture);
      
      await expect(registry.connect(supplier).registerSupplier(
        "Acme Corp",
        "contact@acme.com",
        "123 Supply St",
        "QmHash123"
      )).to.emit(registry, "SupplierRegistered")
        .withArgs(supplier.address, "Acme Corp", (await ethers.provider.getBlock('latest')).timestamp + 1);
        
      const profile = await registry.getSupplier(supplier.address);
      expect(profile.businessName).to.equal("Acme Corp");
      expect(profile.isActive).to.equal(true);
      expect(profile.isVerified).to.equal(false);
    });

    it("Should revert if already registered", async function () {
      const { registry, supplier } = await loadFixture(deployFixture);
      
      await registry.connect(supplier).registerSupplier(
        "Acme Corp",
        "contact@acme.com",
        "123 Supply St",
        "QmHash123"
      );
      
      await expect(registry.connect(supplier).registerSupplier(
        "Acme Inc",
        "new@acme.com",
        "456 Supply St",
        "QmHash456"
      )).to.be.revertedWith("Already registered");
    });

    it("Should revert if business name is empty", async function () {
      const { registry, supplier } = await loadFixture(deployFixture);
      
      await expect(registry.connect(supplier).registerSupplier(
        "",
        "contact@acme.com",
        "123 Supply St",
        "QmHash123"
      )).to.be.revertedWith("Business name required");
    });
  });

  describe("Verification", function () {
    it("Should allow owner to verify supplier", async function () {
      const { registry, owner, supplier } = await loadFixture(deployFixture);
      
      await registry.connect(supplier).registerSupplier("Acme", "email", "addr", "hash");
      
      await expect(registry.connect(owner).verifySupplier(supplier.address))
        .to.emit(registry, "SupplierVerified");
        
      expect(await registry.isSupplierVerified(supplier.address)).to.equal(true);
    });

    it("Should revert if non-owner verifies", async function () {
      const { registry, supplier, otherAccount } = await loadFixture(deployFixture);
      
      await registry.connect(supplier).registerSupplier("Acme", "email", "addr", "hash");
      
      await expect(
        registry.connect(otherAccount).verifySupplier(supplier.address)
      ).to.be.revertedWithCustomError(registry, "OwnableUnauthorizedAccount")
      .withArgs(otherAccount.address);
    });
  });

  describe("Profile Management", function () {
    it("Should update profile successfully", async function () {
      const { registry, supplier } = await loadFixture(deployFixture);
      
      await registry.connect(supplier).registerSupplier("Acme", "email", "addr", "hash");
      
      await expect(registry.connect(supplier).updateProfile(
        "new@acme.com",
        "New Address",
        "NewHash"
      )).to.emit(registry, "SupplierUpdated");
      
      const profile = await registry.getSupplier(supplier.address);
      expect(profile.contactEmail).to.equal("new@acme.com");
      expect(profile.businessAddress).to.equal("New Address");
      expect(profile.documentHash).to.equal("NewHash");
    });

    it("Should add category successfully", async function () {
      const { registry, owner, supplier } = await loadFixture(deployFixture);
      
      await registry.connect(supplier).registerSupplier("Acme", "email", "addr", "hash");
      
      await expect(registry.connect(owner).addCategory(supplier.address, "Logistics"))
        .to.emit(registry, "CategoryAdded")
        .withArgs(supplier.address, "Logistics");
        
      const categories = await registry.getSupplierCategories(supplier.address);
      expect(categories[0]).to.equal("Logistics");
    });
  });
});
