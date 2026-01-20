// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

contract QualityInspector is Ownable {
    mapping(address => bool) public inspectors;
    
    event InspectorAdded(address indexed inspector);
    event InspectorRemoved(address indexed inspector);
    
    constructor() Ownable(msg.sender) {}
    
    function addInspector(address _inspector) external onlyOwner {
        inspectors[_inspector] = true;
        emit InspectorAdded(_inspector);
    }
    
    function removeInspector(address _inspector) external onlyOwner {
        inspectors[_inspector] = false;
        emit InspectorRemoved(_inspector);
    }
    
    function isInspector(address _inspector) external view returns (bool) {
        return inspectors[_inspector];
    }
}
