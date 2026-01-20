// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title WarehouseRegistry
 * @dev Registry for verified warehouses in supply chain
 */
contract WarehouseRegistry is Ownable {
    
    struct Warehouse {
        string name;
        string location;
        address manager;
        uint256 capacity;
        uint256 currentStock;
        bool isVerified;
        bool isActive;
        uint256 registrationDate;
    }
    
    mapping(uint256 => Warehouse) public warehouses;
    mapping(address => uint256) public managerToWarehouseId;
    uint256 private _warehouseIdCounter;
    
    event WarehouseRegistered(uint256 indexed warehouseId, string name);
    event WarehouseVerified(uint256 indexed warehouseId);
    event StockUpdated(uint256 indexed warehouseId, uint256 newStock);
    
    constructor() Ownable(msg.sender) {
        _warehouseIdCounter = 1;
    }
    
    function registerWarehouse(
        string memory _name,
        string memory _location,
        address _manager,
        uint256 _capacity
    ) external onlyOwner returns (uint256) {
        require(_manager != address(0), "Invalid manager");
        require(managerToWarehouseId[_manager] == 0, "Manager already assigned");
        
        uint256 warehouseId = _warehouseIdCounter++;
        
        warehouses[warehouseId] = Warehouse({
            name: _name,
            location: _location,
            manager: _manager,
            capacity: _capacity,
            currentStock: 0,
            isVerified: false,
            isActive: true,
            registrationDate: block.timestamp
        });
        
        managerToWarehouseId[_manager] = warehouseId;
        
        emit WarehouseRegistered(warehouseId, _name);
        
        return warehouseId;
    }
    
    function verifyWarehouse(uint256 _warehouseId) external onlyOwner {
        require(_warehouseId > 0 && _warehouseId < _warehouseIdCounter, "Invalid ID");
        warehouses[_warehouseId].isVerified = true;
        emit WarehouseVerified(_warehouseId);
    }
    
    function updateStock(uint256 _warehouseId, uint256 _newStock) external {
        require(_warehouseId > 0 && _warehouseId < _warehouseIdCounter, "Invalid ID");
        require(warehouses[_warehouseId].manager == msg.sender || msg.sender == owner(), "Unauthorized");
        require(_newStock <= warehouses[_warehouseId].capacity, "Exceeds capacity");
        
        warehouses[_warehouseId].currentStock = _newStock;
        emit StockUpdated(_warehouseId, _newStock);
    }
    
    function getWarehouse(uint256 _warehouseId) external view returns (Warehouse memory) {
        require(_warehouseId > 0 && _warehouseId < _warehouseIdCounter, "Invalid ID");
        return warehouses[_warehouseId];
    }
    
    function getTotalWarehouses() external view returns (uint256) {
        return _warehouseIdCounter - 1;
    }
}
