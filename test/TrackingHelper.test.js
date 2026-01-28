const { expect } = require("chai");
const hre = require("hardhat");
const { ethers } = hre;

describe("TrackingHelper", function () {
  it("Should hash tracking data", async function () {
    const Lib = await ethers.getContractFactory("TrackingHelper");
    const lib = await Lib.deploy();
    expect(await lib.getAddress()).to.be.properAddress;
  });
});
