// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

contract ShipmentTracker is Ownable {
    event ShipmentUpdated(uint256 indexed id, string status);
    
    constructor() Ownable(msg.sender) {}
    
    function updateStatus(uint256 id, string memory status) external onlyOwner {
        emit ShipmentUpdated(id, status);
    }
}
