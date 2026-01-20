// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

contract BillOfLading is Ownable {
    struct Bill {
        uint256 id;
        uint256 shipmentId;
        string carrier;
        uint256 timestamp;
        string documentHash;
    }
    
    mapping(uint256 => Bill) public bills;
    uint256 public nextId = 1;
    
    event BillCreated(uint256 indexed id, uint256 shipmentId);
    
    constructor() Ownable(msg.sender) {}
    
    function createBill(uint256 _shipmentId, string memory _carrier, string memory _docHash) external onlyOwner {
        bills[nextId] = Bill(nextId, _shipmentId, _carrier, block.timestamp, _docHash);
        emit BillCreated(nextId, _shipmentId);
        nextId++;
    }
}
