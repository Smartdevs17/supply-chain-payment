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
});
