const { expect } = require("chai");
const { ethers } = require("hardhat");
const { loadFixture } = require("@nomicfoundation/hardhat-toolbox/network-helpers");

describe("ReputationSystem", function () {
  async function deployFixture() {
    const [owner, supplier, user, user2] = await ethers.getSigners();

    const ReputationSystem = await ethers.getContractFactory("ReputationSystem");
    const reputation = await ReputationSystem.deploy();

    return { reputation, owner, supplier, user, user2 };
  }

  describe("Review Submission", function () {
    it("Should submit review successfully", async function () {
      const { reputation, supplier, user } = await loadFixture(deployFixture);
      
      const orderId = 123;
      await expect(reputation.connect(user).submitReview(supplier.address, orderId, 5, "Great service!"))
        .to.emit(reputation, "ReviewSubmitted")
        .withArgs(0, user.address, supplier.address, 5, (await ethers.provider.getBlock('latest')).timestamp + 1);
        
      const rep = await reputation.getSupplierReputation(supplier.address);
      expect(rep.totalReviews).to.equal(1);
      expect(rep.averageRating).to.equal(500); // 5.00 * 100
    });

    it("Should calculate average rating correctly", async function () {
      const { reputation, supplier, user, user2 } = await loadFixture(deployFixture);
      
      await reputation.connect(user).submitReview(supplier.address, 1, 5, "Great");
      await reputation.connect(user2).submitReview(supplier.address, 2, 3, "Average");
      
      const rep = await reputation.getSupplierReputation(supplier.address);
      expect(rep.totalReviews).to.equal(2);
      // (5 + 3) / 2 = 4.00 * 100 = 400
      expect(rep.averageRating).to.equal(400);
    });

    it("Should revert if self-review", async function () {
      const { reputation, supplier } = await loadFixture(deployFixture);
      
      await expect(
        reputation.connect(supplier).submitReview(supplier.address, 1, 5, "Self praise")
      ).to.be.revertedWith("Cannot review yourself");
    });

    it("Should revert if rating is invalid", async function () {
      const { reputation, supplier, user } = await loadFixture(deployFixture);
      
      await expect(
        reputation.connect(user).submitReview(supplier.address, 1, 6, "Too high")
      ).to.be.revertedWith("Rating must be 1-5");
    });
  });

  describe("Badges", function () {
    it("Should award badge successfully", async function () {
      const { reputation, owner, supplier } = await loadFixture(deployFixture);
      
      await expect(reputation.connect(owner).awardBadge(supplier.address, "Top Rated"))
        .to.emit(reputation, "BadgeAwarded")
        .withArgs(supplier.address, "Top Rated", (await ethers.provider.getBlock('latest')).timestamp + 1);
        
      const badges = await reputation.getSupplierBadges(supplier.address);
      expect(badges[0]).to.equal("Top Rated");
    });

    it("Should revert if badge does not exist", async function () {
      const { reputation, owner, supplier } = await loadFixture(deployFixture);
      
      await expect(
        reputation.connect(owner).awardBadge(supplier.address, "Fake Badge")
      ).to.be.revertedWith("Badge does not exist");
    });
  });
});
