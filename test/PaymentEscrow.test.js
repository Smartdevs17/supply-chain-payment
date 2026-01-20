import { expect } from "chai";
import { ethers } from "hardhat";
import { loadFixture } from "@nomicfoundation/hardhat-toolbox/network-helpers.js";

describe("PaymentEscrow", function () {
  async function deployFixture() {
    const [owner, buyer, seller] = await ethers.getSigners();
    const PaymentEscrow = await ethers.getContractFactory("PaymentEscrow");
    const escrow = await PaymentEscrow.deploy();
    return { escrow, owner, buyer, seller };
  }
  
  it("Should create escrow", async function () {
    const { escrow, buyer, seller } = await loadFixture(deployFixture);
    await expect(escrow.connect(buyer).createEscrow(1, seller.address, ethers.ZeroAddress, 100, 3600))
      .to.emit(escrow, "EscrowCreated");
  });
});
