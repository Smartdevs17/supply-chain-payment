// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title SupplierRegistry
 * @dev Enhanced supplier registration and profile management system
 */
contract SupplierRegistry is Ownable {
    
    struct SupplierProfile {
        address supplierAddress;
        string businessName;
        string contactEmail;
        string businessAddress;
        string documentHash; // IPFS hash for verification documents
        string[] categories;
        string[] tags;
        bool isVerified;
        bool isActive;
        uint256 registrationDate;
        uint256 lastUpdated;
    }

    // Mappings
    mapping(address => SupplierProfile) public suppliers;
    mapping(string => address[]) public categoryToSuppliers;
    mapping(string => address[]) public tagToSuppliers;
    
    address[] public allSuppliers;
    string[] public availableCategories;
    
    // Events
    event SupplierRegistered(
        address indexed supplier,
        string businessName,
        uint256 timestamp
    );
    
    event SupplierVerified(
        address indexed supplier,
        uint256 timestamp
    );
    
    event SupplierUpdated(
        address indexed supplier,
        uint256 timestamp
    );
    
    event CategoryAdded(
        address indexed supplier,
        string category
    );
    
    event TagAdded(
        address indexed supplier,
        string tag
    );
    
    event SupplierDeactivated(
        address indexed supplier,
        uint256 timestamp
    );

    constructor() Ownable(msg.sender) {}

    /**
     * @dev Register as a supplier
     */
    function registerSupplier(
        string memory _businessName,
        string memory _contactEmail,
        string memory _businessAddress,
        string memory _documentHash
    ) external {
        require(suppliers[msg.sender].supplierAddress == address(0), "Already registered");
        require(bytes(_businessName).length > 0, "Business name required");
        require(bytes(_contactEmail).length > 0, "Contact email required");

        SupplierProfile storage newSupplier = suppliers[msg.sender];
        newSupplier.supplierAddress = msg.sender;
        newSupplier.businessName = _businessName;
        newSupplier.contactEmail = _contactEmail;
        newSupplier.businessAddress = _businessAddress;
        newSupplier.documentHash = _documentHash;
        newSupplier.isVerified = false;
        newSupplier.isActive = true;
        newSupplier.registrationDate = block.timestamp;
        newSupplier.lastUpdated = block.timestamp;

        allSuppliers.push(msg.sender);

        emit SupplierRegistered(msg.sender, _businessName, block.timestamp);
    }

    /**
     * @dev Update supplier profile
     */
    function updateProfile(
        string memory _contactEmail,
        string memory _businessAddress,
        string memory _documentHash
    ) external {
        require(suppliers[msg.sender].supplierAddress != address(0), "Not registered");
        
        SupplierProfile storage supplier = suppliers[msg.sender];
        supplier.contactEmail = _contactEmail;
        supplier.businessAddress = _businessAddress;
        supplier.documentHash = _documentHash;
        supplier.lastUpdated = block.timestamp;

        emit SupplierUpdated(msg.sender, block.timestamp);
    }

    /**
     * @dev Add category to supplier (owner only)
     */
    function addCategory(address _supplier, string memory _category) external onlyOwner {
        require(suppliers[_supplier].supplierAddress != address(0), "Supplier not found");
        
        suppliers[_supplier].categories.push(_category);
        categoryToSuppliers[_category].push(_supplier);
        
        // Add to available categories if new
        bool categoryExists = false;
        for (uint256 i = 0; i < availableCategories.length; i++) {
            if (keccak256(bytes(availableCategories[i])) == keccak256(bytes(_category))) {
                categoryExists = true;
                break;
            }
        }
        if (!categoryExists) {
            availableCategories.push(_category);
        }

        emit CategoryAdded(_supplier, _category);
    }

    /**
     * @dev Add tag to supplier profile
     */
    function addTag(string memory _tag) external {
        require(suppliers[msg.sender].supplierAddress != address(0), "Not registered");
        
        suppliers[msg.sender].tags.push(_tag);
        tagToSuppliers[_tag].push(msg.sender);

        emit TagAdded(msg.sender, _tag);
    }

    /**
     * @dev Verify supplier (owner only)
     */
    function verifySupplier(address _supplier) external onlyOwner {
        require(suppliers[_supplier].supplierAddress != address(0), "Supplier not found");
        require(!suppliers[_supplier].isVerified, "Already verified");

        suppliers[_supplier].isVerified = true;
        suppliers[_supplier].lastUpdated = block.timestamp;

        emit SupplierVerified(_supplier, block.timestamp);
    }

    /**
     * @dev Deactivate supplier (owner only)
     */
    function deactivateSupplier(address _supplier) external onlyOwner {
        require(suppliers[_supplier].supplierAddress != address(0), "Supplier not found");
        require(suppliers[_supplier].isActive, "Already deactivated");

        suppliers[_supplier].isActive = false;
        suppliers[_supplier].lastUpdated = block.timestamp;

        emit SupplierDeactivated(_supplier, block.timestamp);
    }

    /**
     * @dev Get supplier profile
     */
    function getSupplier(address _supplier) external view returns (
        address supplierAddress,
        string memory businessName,
        string memory contactEmail,
        string memory businessAddress,
        string memory documentHash,
        bool isVerified,
        bool isActive,
        uint256 registrationDate
    ) {
        SupplierProfile memory supplier = suppliers[_supplier];
        return (
            supplier.supplierAddress,
            supplier.businessName,
            supplier.contactEmail,
            supplier.businessAddress,
            supplier.documentHash,
            supplier.isVerified,
            supplier.isActive,
            supplier.registrationDate
        );
    }

    /**
     * @dev Get supplier categories
     */
    function getSupplierCategories(address _supplier) external view returns (string[] memory) {
        return suppliers[_supplier].categories;
    }

    /**
     * @dev Get supplier tags
     */
    function getSupplierTags(address _supplier) external view returns (string[] memory) {
        return suppliers[_supplier].tags;
    }

    /**
     * @dev Get suppliers by category
     */
    function getSuppliersByCategory(string memory _category) external view returns (address[] memory) {
        return categoryToSuppliers[_category];
    }

    /**
     * @dev Get suppliers by tag
     */
    function getSuppliersByTag(string memory _tag) external view returns (address[] memory) {
        return tagToSuppliers[_tag];
    }

    /**
     * @dev Get all available categories
     */
    function getAvailableCategories() external view returns (string[] memory) {
        return availableCategories;
    }

    /**
     * @dev Get total number of suppliers
     */
    function getTotalSuppliers() external view returns (uint256) {
        return allSuppliers.length;
    }

    /**
     * @dev Get all supplier addresses
     */
    function getAllSuppliers() external view returns (address[] memory) {
        return allSuppliers;
    }

    /**
     * @dev Check if supplier is verified
     */
    function isSupplierVerified(address _supplier) external view returns (bool) {
        return suppliers[_supplier].isVerified;
    }
}
