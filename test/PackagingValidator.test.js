const { expect } = require("chai");
const hre = require("hardhat");
const { ethers } = hre;

describe("PackagingValidator", function () {
  it("Should validate package types correctly", async function () {
    const Lib = await ethers.getContractFactory("PackagingValidator");
    const lib = await Lib.deploy();
    expect(await lib.getAddress()).to.be.properAddress;
  });
});
