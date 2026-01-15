const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("SupplyChainPayment", function () {
    let supplyChainPayment;
    let owner;
    let supplier;
    let buyer;
    let addr1;

    beforeEach(async function () {
        [owner, supplier, buyer, addr1] = await ethers.getSigners();
        
        const SupplyChainPayment = await ethers.getContractFactory("SupplyChainPayment");
        supplyChainPayment = await SupplyChainPayment.deploy();
    });

    describe("Deployment", function () {
        it("Should set the right owner", async function () {
            expect(await supplyChainPayment.owner()).to.equal(owner.address);
        });

        it("Should initialize with correct platform fee", async function () {
            expect(await supplyChainPayment.platformFeePercentage()).to.equal(1);
        });

        it("Should start with zero total platform fees", async function () {
            expect(await supplyChainPayment.totalPlatformFees()).to.equal(0);
        });
    });

    describe("Supplier Registration", function () {
        it("Should allow supplier to register", async function () {
            await supplyChainPayment.connect(supplier).registerSupplier("Test Supplier", "test@supplier.com");
            
            const supplierData = await supplyChainPayment.getSupplier(supplier.address);
            expect(supplierData.name).to.equal("Test Supplier");
            expect(supplierData.contactInfo).to.equal("test@supplier.com");
            expect(supplierData.isVerified).to.equal(false);
        });

        it("Should emit SupplierRegistered event", async function () {
            await expect(supplyChainPayment.connect(supplier).registerSupplier("Test Supplier", "test@supplier.com"))
                .to.emit(supplyChainPayment, "SupplierRegistered")
                .withArgs(supplier.address, "Test Supplier", await ethers.provider.getBlock('latest').then(b => b.timestamp + 1));
        });

        it("Should not allow duplicate registration", async function () {
            await supplyChainPayment.connect(supplier).registerSupplier("Test Supplier", "test@supplier.com");
            
            await expect(
                supplyChainPayment.connect(supplier).registerSupplier("Test Supplier 2", "test2@supplier.com")
            ).to.be.revertedWith("Supplier already registered");
        });

        it("Should not allow empty name", async function () {
            await expect(
                supplyChainPayment.connect(supplier).registerSupplier("", "test@supplier.com")
            ).to.be.revertedWith("Name cannot be empty");
        });
    });
});
