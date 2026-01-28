const { expect } = require("chai");
const hre = require("hardhat");
const { ethers } = hre;

describe("DistributionHelper", function () {
  it("Should calculate distances", async function () {
    const Lib = await ethers.getContractFactory("DistributionHelper");
    const lib = await Lib.deploy();
    expect(await lib.getAddress()).to.be.properAddress;
  });
});
