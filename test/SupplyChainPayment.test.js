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

    describe("Supplier Verification", function () {
        beforeEach(async function () {
            await supplyChainPayment.connect(supplier).registerSupplier("Test Supplier", "test@supplier.com");
        });

        it("Should allow owner to verify supplier", async function () {
            await supplyChainPayment.connect(owner).verifySupplier(supplier.address);
            
            const supplierData = await supplyChainPayment.getSupplier(supplier.address);
            expect(supplierData.isVerified).to.equal(true);
        });

        it("Should emit SupplierVerified event", async function () {
            await expect(supplyChainPayment.connect(owner).verifySupplier(supplier.address))
                .to.emit(supplyChainPayment, "SupplierVerified");
        });

        it("Should not allow non-owner to verify", async function () {
            await expect(
                supplyChainPayment.connect(buyer).verifySupplier(supplier.address)
            ).to.be.reverted;
        });

        it("Should not verify unregistered supplier", async function () {
            await expect(
                supplyChainPayment.connect(owner).verifySupplier(addr1.address)
            ).to.be.revertedWith("Supplier not registered");
        });
    });

    describe("Order Creation", function () {
        beforeEach(async function () {
            await supplyChainPayment.connect(supplier).registerSupplier("Test Supplier", "test@supplier.com");
            await supplyChainPayment.connect(owner).verifySupplier(supplier.address);
        });

        it("Should allow buyer to create order", async function () {
            const orderAmount = ethers.parseEther("1.0");
            await supplyChainPayment.connect(buyer).createOrder(
                supplier.address,
                "100 widgets",
                { value: orderAmount }
            );

            const order = await supplyChainPayment.getOrder(0);
            expect(order.buyer).to.equal(buyer.address);
            expect(order.supplier).to.equal(supplier.address);
            expect(order.totalAmount).to.equal(orderAmount);
        });

        it("Should emit OrderCreated event", async function () {
            const orderAmount = ethers.parseEther("1.0");
            await expect(
                supplyChainPayment.connect(buyer).createOrder(
                    supplier.address,
                    "100 widgets",
                    { value: orderAmount }
                )
            ).to.emit(supplyChainPayment, "OrderCreated");
        });

        it("Should not allow order with unverified supplier", async function () {
            await supplyChainPayment.connect(addr1).registerSupplier("Unverified", "test@test.com");
            
            await expect(
                supplyChainPayment.connect(buyer).createOrder(
                    addr1.address,
                    "Test order",
                    { value: ethers.parseEther("1.0") }
                )
            ).to.be.revertedWith("Supplier not verified");
        });

        it("Should not allow zero value order", async function () {
            await expect(
                supplyChainPayment.connect(buyer).createOrder(
                    supplier.address,
                    "Test order",
                    { value: 0 }
                )
            ).to.be.revertedWith("Order amount must be greater than 0");
        });
    });

    describe("Milestone Management", function () {
        beforeEach(async function () {
            await supplyChainPayment.connect(supplier).registerSupplier("Test Supplier", "test@supplier.com");
            await supplyChainPayment.connect(owner).verifySupplier(supplier.address);
            await supplyChainPayment.connect(buyer).createOrder(
                supplier.address,
                "100 widgets",
                { value: ethers.parseEther("1.0") }
            );
        });

        it("Should allow buyer to add milestone", async function () {
            await supplyChainPayment.connect(buyer).addMilestone(0, "Design approval", 30);
            
            const milestoneCount = await supplyChainPayment.getMilestoneCount(0);
            expect(milestoneCount).to.equal(1);
            
            const milestone = await supplyChainPayment.getMilestone(0, 0);
            expect(milestone.description).to.equal("Design approval");
            expect(milestone.paymentPercentage).to.equal(30);
        });

        it("Should emit MilestoneAdded event", async function () {
            await expect(
                supplyChainPayment.connect(buyer).addMilestone(0, "Design approval", 30)
            ).to.emit(supplyChainPayment, "MilestoneAdded");
        });

        it("Should not allow non-buyer to add milestone", async function () {
            await expect(
                supplyChainPayment.connect(supplier).addMilestone(0, "Test", 30)
            ).to.be.revertedWith("Only buyer can perform this action");
        });

        it("Should not allow milestones exceeding 100%", async function () {
            await supplyChainPayment.connect(buyer).addMilestone(0, "Milestone 1", 60);
            await supplyChainPayment.connect(buyer).addMilestone(0, "Milestone 2", 30);
            
            await expect(
                supplyChainPayment.connect(buyer).addMilestone(0, "Milestone 3", 20)
            ).to.be.revertedWith("Total percentage exceeds 100%");
        });
    });
});
