const { expect } = require("chai");
const { ethers } = require("hardhat");
const { loadFixture } = require("@nomicfoundation/hardhat-toolbox/network-helpers");

describe("ProductCatalog", function () {
  async function deployFixture() {
    const [owner, supplier, otherAccount] = await ethers.getSigners();

    const ProductCatalog = await ethers.getContractFactory("ProductCatalog");
    const catalog = await ProductCatalog.deploy();

    return { catalog, owner, supplier, otherAccount };
  }

  describe("Product Management", function () {
    it("Should add product successfully", async function () {
      const { catalog, supplier } = await loadFixture(deployFixture);
      
      await expect(catalog.connect(supplier).addProduct(
        "Widget",
        "A useful widget",
        "QmImageHash",
        "Electronics",
        ethers.parseEther("0.1"),
        100
      )).to.emit(catalog, "ProductAdded")
        .withArgs(0, supplier.address, "Widget", ethers.parseEther("0.1"), (await ethers.provider.getBlock('latest')).timestamp + 1);
        
      const product = await catalog.getProduct(0);
      expect(product.name).to.equal("Widget");
      expect(product.supplier).to.equal(supplier.address);
      expect(product.inventory).to.equal(100);
    });

    it("Should update product details", async function () {
      const { catalog, supplier } = await loadFixture(deployFixture);
      
      await catalog.connect(supplier).addProduct("Widget", "Desc", "Hash", "Cat", 100, 10);
      
      await expect(catalog.connect(supplier).updateProduct(
        0,
        "New Desc",
        "NewHash",
        "NewCat"
      )).to.emit(catalog, "ProductUpdated");
      
      const product = await catalog.getProduct(0);
      expect(product.description).to.equal("New Desc");
      expect(product.category).to.equal("NewCat");
    });

    it("Should revert if non-owner updates", async function () {
      const { catalog, supplier, otherAccount } = await loadFixture(deployFixture);
      
      await catalog.connect(supplier).addProduct("Widget", "Desc", "Hash", "Cat", 100, 10);
      
      await expect(
        catalog.connect(otherAccount).updateProduct(0, "Desc", "Hash", "Cat")
      ).to.be.revertedWith("Not product owner");
    });
  });

  describe("Inventory Management", function () {
    it("Should increase inventory successfully", async function () {
      const { catalog, supplier } = await loadFixture(deployFixture);
      
      await catalog.connect(supplier).addProduct("Widget", "Desc", "Hash", "Cat", 100, 10);
      
      await expect(catalog.connect(supplier).increaseInventory(0, 5))
        .to.emit(catalog, "InventoryUpdated")
        .withArgs(0, 15, (await ethers.provider.getBlock('latest')).timestamp + 1);
        
      const product = await catalog.getProduct(0);
      expect(product.inventory).to.equal(15);
    });

    it("Should decrease inventory successfully", async function () {
      const { catalog, supplier } = await loadFixture(deployFixture);
      
      await catalog.connect(supplier).addProduct("Widget", "Desc", "Hash", "Cat", 100, 10);
      
      await expect(catalog.connect(supplier).decreaseInventory(0, 3))
        .to.emit(catalog, "InventoryUpdated")
        .withArgs(0, 7, (await ethers.provider.getBlock('latest')).timestamp + 1);
        
      const product = await catalog.getProduct(0);
      expect(product.inventory).to.equal(7);
    });

    it("Should revert if insufficient inventory", async function () {
      const { catalog, supplier } = await loadFixture(deployFixture);
      
      await catalog.connect(supplier).addProduct("Widget", "Desc", "Hash", "Cat", 100, 10);
      
      await expect(
        catalog.connect(supplier).decreaseInventory(0, 15)
      ).to.be.revertedWith("Insufficient inventory");
    });
  });

  describe("Pricing", function () {
    it("Should update price successfully", async function () {
      const { catalog, supplier } = await loadFixture(deployFixture);
      
      await catalog.connect(supplier).addProduct("Widget", "Desc", "Hash", "Cat", 100, 10);
      
      const newPrice = ethers.parseEther("0.2");
      await expect(catalog.connect(supplier).updatePrice(0, newPrice))
        .to.emit(catalog, "PriceUpdated")
        .withArgs(0, newPrice, (await ethers.provider.getBlock('latest')).timestamp + 1);
        
      const product = await catalog.getProduct(0);
      expect(product.price).to.equal(newPrice);
    });

    it("Should revert if price is zero", async function () {
      const { catalog, supplier } = await loadFixture(deployFixture);
      
      await catalog.connect(supplier).addProduct("Widget", "Desc", "Hash", "Cat", 100, 10);
      
      await expect(
        catalog.connect(supplier).updatePrice(0, 0)
      ).to.be.revertedWith("Price must be greater than 0");
    });
  });
});
