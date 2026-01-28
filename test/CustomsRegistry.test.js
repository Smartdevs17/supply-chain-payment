const { expect } = require("chai");
const hre = require("hardhat");
const { ethers } = hre;

describe("CustomsRegistry", function () {
  it("Should register office", async function () {
    const CustomsRegistry = await ethers.getContractFactory("CustomsRegistry");
    const registry = await CustomsRegistry.deploy();
    const [owner, office] = await ethers.getSigners();
    
    await registry.registerOffice("US", "JFK", office.address);
    expect(await registry.isAuthorized("US", office.address)).to.be.true;
  });
});
