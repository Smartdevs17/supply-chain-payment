// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title ShippingTracker
 * @dev Track shipments in the supply chain
 */
contract ShippingTracker is Ownable {
    
    struct Shipment {
        uint256 orderId;
        address shipper;
        address origin;
        address destination;
        uint256 departureTime;
        uint256 estimatedArrival;
        uint256 actualArrival;
        string status; // "pending", "in_transit", "delivered", "delayed"
        string trackingNumber;
    }
    
    mapping(uint256 => Shipment) public shipments;
    mapping(string => uint256) public trackingToShipmentId;
    uint256 private _shipmentIdCounter;
    
    event ShipmentCreated(uint256 indexed shipmentId, uint256 indexed orderId, string trackingNumber);
    event ShipmentStatusUpdated(uint256 indexed shipmentId, string status);
    event ShipmentDelivered(uint256 indexed shipmentId, uint256 deliveryTime);
    
    constructor() Ownable(msg.sender) {
        _shipmentIdCounter = 1;
    }
    
    function createShipment(
        uint256 _orderId,
        address _shipper,
        address _origin,
        address _destination,
        uint256 _estimatedArrival,
        string memory _trackingNumber
    ) external returns (uint256) {
        require(_shipper != address(0), "Invalid shipper");
        require(trackingToShipmentId[_trackingNumber] == 0, "Tracking number exists");
        
        uint256 shipmentId = _shipmentIdCounter++;
        
        shipments[shipmentId] = Shipment({
            orderId: _orderId,
            shipper: _shipper,
            origin: _origin,
            destination: _destination,
            departureTime: block.timestamp,
            estimatedArrival: _estimatedArrival,
            actualArrival: 0,
            status: "in_transit",
            trackingNumber: _trackingNumber
        });
        
        trackingToShipmentId[_trackingNumber] = shipmentId;
        
        emit ShipmentCreated(shipmentId, _orderId, _trackingNumber);
        
        return shipmentId;
    }
    
    function updateStatus(uint256 _shipmentId, string memory _status) external {
        require(_shipmentId > 0 && _shipmentId < _shipmentIdCounter, "Invalid shipment ID");
        shipments[_shipmentId].status = _status;
        emit ShipmentStatusUpdated(_shipmentId, _status);
    }
    
    function markDelivered(uint256 _shipmentId) external {
        require(_shipmentId > 0 && _shipmentId < _shipmentIdCounter, "Invalid shipment ID");
        shipments[_shipmentId].status = "delivered";
        shipments[_shipmentId].actualArrival = block.timestamp;
        emit ShipmentDelivered(_shipmentId, block.timestamp);
    }
    
    function getShipmentByTracking(string memory _trackingNumber) external view returns (Shipment memory) {
        uint256 shipmentId = trackingToShipmentId[_trackingNumber];
        require(shipmentId > 0, "Shipment not found");
        return shipments[shipmentId];
    }
}
