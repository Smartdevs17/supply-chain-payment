// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

contract InsurancePolicy is Ownable {
    mapping(uint256 => uint256) public coverage;
    
    event PolicyCreated(uint256 indexed id, uint256 coverageAmount);
    
    constructor() Ownable(msg.sender) {}
    
    function createPolicy(uint256 id, uint256 amount) external onlyOwner {
        coverage[id] = amount;
        emit PolicyCreated(id, amount);
    }
}
