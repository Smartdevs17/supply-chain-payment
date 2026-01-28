// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title WarehouseRegistry
 * @dev Registry for verified warehouses in supply chain
 */
contract WarehouseRegistry is Ownable {
    
    /**
     * @notice Container for warehouse storage and management details
     * @param name Descriptive name of the facility
     * @param location Physical or geographic address
     * @param manager Address of the account responsible for updates
     * @param capacity Maximum total units the warehouse can hold
     * @param currentStock Number of units currently stored
     * @param isVerified True if the site has passed physical inspection
     * @param isActive True if the site is available for shipping
     * @param registrationDate UNIX timestamp of onboarding
     */
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
    
    /// @notice Maps warehouse ID to its profile
    mapping(uint256 => Warehouse) public warehouses;
    
    /// @notice Reverse lookup to find which warehouse a manager belongs to
    mapping(address => uint256) public managerToWarehouseId;
    
    /// @dev Internal tracker for assigning unique warehouse IDs
    uint256 private _warehouseIdCounter;
    
    /// @notice Emitted when a new warehouse is onboarded
    event WarehouseRegistered(uint256 indexed warehouseId, string name);
    
    /// @notice Emitted when the warehouse is certified by the admin
    event WarehouseVerified(uint256 indexed warehouseId);
    
    /// @notice Emitted when stock levels are modified
    event StockUpdated(uint256 indexed warehouseId, uint256 newStock);
    
    constructor() Ownable(msg.sender) {
        _warehouseIdCounter = 1;
    }
    
    /**
     * @notice Adds a new warehouse to the network (Admin only)
     * @param _name Label for the warehouse
     * @param _location Physical address or coordinates
     * @param _manager The account allowed to update stock
     * @param _capacity Max storage volume
     * @return The unique ID assigned
     */
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
    
    /**
     * @notice Marks a facility as verified (Admin only)
     * @param _warehouseId Unique identifier
     */
    function verifyWarehouse(uint256 _warehouseId) external onlyOwner {
        require(_warehouseId > 0 && _warehouseId < _warehouseIdCounter, "Invalid ID");
        warehouses[_warehouseId].isVerified = true;
        emit WarehouseVerified(_warehouseId);
    }
    
    /**
     * @notice Records current inventory levels
     * @dev Only the assigned manager or admin can update stock. Cannot exceed capacity.
     * @param _warehouseId Unique identifier
     * @param _newStock Current count of items in storage
     */
    function updateStock(uint256 _warehouseId, uint256 _newStock) external {
        require(_warehouseId > 0 && _warehouseId < _warehouseIdCounter, "Invalid ID");
        require(warehouses[_warehouseId].manager == msg.sender || msg.sender == owner(), "Unauthorized");
        require(_newStock <= warehouses[_warehouseId].capacity, "Exceeds capacity");
        
        warehouses[_warehouseId].currentStock = _newStock;
        emit StockUpdated(_warehouseId, _newStock);
    }
    
    /**
     * @notice Fetches the full profile for a warehouse
     * @param _warehouseId Unique identifier
     * @return The Warehouse data structure
     */
    function getWarehouse(uint256 _warehouseId) external view returns (Warehouse memory) {
        require(_warehouseId > 0 && _warehouseId < _warehouseIdCounter, "Invalid ID");
        return warehouses[_warehouseId];
    }
    
    function getTotalWarehouses() external view returns (uint256) {
        return _warehouseIdCounter - 1;
    }
}
