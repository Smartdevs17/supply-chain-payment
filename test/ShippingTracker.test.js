const { expect } = require("chai");
const hre = require("hardhat");
const { ethers } = hre;

describe("ShippingTracker", function () {
  let shippingTracker, owner, shipper, origin, destination;
  
  beforeEach(async function () {
    [owner, shipper, origin, destination] = await ethers.getSigners();
    
    const ShippingTracker = await ethers.getContractFactory("ShippingTracker");
    shippingTracker = await ShippingTracker.deploy();
  });
  
  describe("Shipment Creation", function () {
    it("Should create shipment successfully", async function () {
      const estimatedArrival = Math.floor(Date.now() / 1000) + 86400; // +1 day
      
      await expect(shippingTracker.createShipment(
        1, // orderId
        shipper.address,
        origin.address,
        destination.address,
        estimatedArrival,
        "TRACK-001"
      )).to.emit(shippingTracker, "ShipmentCreated");
    });
    
    it("Should fail with invalid shipper", async function () {
      await expect(
        shippingTracker.createShipment(
          1,
          ethers.ZeroAddress,
          origin.address,
          destination.address,
          123456,
          "TRACK-001"
        )
      ).to.be.revertedWith("Invalid shipper");
    });
    
    it("Should fail with duplicate tracking number", async function () {
      const estimatedArrival = Math.floor(Date.now() / 1000) + 86400;
      
      await shippingTracker.createShipment(
        1,
        shipper.address,
        origin.address,
        destination.address,
        estimatedArrival,
        "TRACK-001"
      );
      
      await expect(
        shippingTracker.createShipment(
          2,
          shipper.address,
          origin.address,
          destination.address,
          estimatedArrival,
          "TRACK-001"
        )
      ).to.be.revertedWith("Tracking number exists");
    });
  });
  
  describe("Status Updates", function () {
    beforeEach(async function () {
      const estimatedArrival = Math.floor(Date.now() / 1000) + 86400;
      await shippingTracker.createShipment(
        1,
        shipper.address,
        origin.address,
        destination.address,
        estimatedArrival,
        "TRACK-001"
      );
    });
    
    it("Should update shipment status", async function () {
      await expect(shippingTracker.updateStatus(1, "delayed"))
        .to.emit(shippingTracker, "ShipmentStatusUpdated")
        .withArgs(1, "delayed");
    });
    
    it("Should mark as delivered", async function () {
      await expect(shippingTracker.markDelivered(1))
        .to.emit(shippingTracker, "ShipmentDelivered");
      
      const shipment = await shippingTracker.shipments(1);
      expect(shipment.status).to.equal("delivered");
      expect(shipment.actualArrival).to.be.gt(0);
    });
  });
  
  describe("Tracking Lookup", function () {
    it("Should retrieve shipment by tracking number", async function () {
      const estimatedArrival = Math.floor(Date.now() / 1000) + 86400;
      await shippingTracker.createShipment(
        1,
        shipper.address,
        origin.address,
        destination.address,
        estimatedArrival,
        "TRACK-001"
      );
      
      const shipment = await shippingTracker.getShipmentByTracking("TRACK-001");
      expect(shipment.trackingNumber).to.equal("TRACK-001");
      expect(shipment.orderId).to.equal(1);
    });
  });
});
