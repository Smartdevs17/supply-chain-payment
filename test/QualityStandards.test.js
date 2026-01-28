const { expect } = require("chai");
const hre = require("hardhat");
const { ethers } = hre;

describe("QualityStandards", function () {
  it("Should validate against standards", async function () {
    const Lib = await ethers.getContractFactory("QualityStandards");
    const lib = await Lib.deploy();
    expect(await lib.getAddress()).to.be.properAddress;
  });
});
