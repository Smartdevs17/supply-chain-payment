// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title SupplierRegistry
 * @dev Enhanced supplier registration and profile management system
 */
contract SupplierRegistry is Ownable {
    
    /**
     * @notice Comprehensive profile for a registered supplier
     * @param supplierAddress Unique wallet address of the business owner
     * @param businessName Registered legal/trading name
     * @param contactEmail Public contact correspondence
     * @param businessAddress Physical or headquarters location
     * @param documentHash IPFS link to legal/business verification files
     * @param categories High-level industry groupings (e.g., Raw Materials, Logistics)
     * @param tags Specific search keywords or labels
     * @param isVerified True if owner has audited the documents
     * @param isActive True if the supplier is currently operational
     * @param registrationDate UNIX timestamp of first registration
     * @param lastUpdated UNIX timestamp of most recent profile modification
     */
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
    /// @notice Quick lookup for profile by wallet address
    mapping(address => SupplierProfile) public suppliers;
    
    /// @notice Index of suppliers grouped by business category
    mapping(string => address[]) public categoryToSuppliers;
    
    /// @notice Index of suppliers grouped by descriptive tags
    mapping(string => address[]) public tagToSuppliers;
    
    address[] public allSuppliers;
    string[] public availableCategories;
    
    // Events
    /// @notice Emitted when a new business registers
    event SupplierRegistered(
        address indexed supplier,
        string businessName,
        uint256 timestamp
    );
    
    /// @notice Emitted when the admin confirms a supplier's validity
    event SupplierVerified(
        address indexed supplier,
        uint256 timestamp
    );
    
    /// @notice Emitted when a supplier modifies their profile details
    event SupplierUpdated(
        address indexed supplier,
        uint256 timestamp
    );
    
    /// @notice Emitted when a new category label is assigned to a profile
    event CategoryAdded(
        address indexed supplier,
        string category
    );
    
    /// @notice Emitted when a search tag is added to a profile
    event TagAdded(
        address indexed supplier,
        string tag
    );
    
    /// @notice Emitted when a profile is hidden or suspended
    event SupplierDeactivated(
        address indexed supplier,
        uint256 timestamp
    );

    constructor() Ownable(msg.sender) {}

    /**
     * @dev Register as a supplier
     */
    /**
     * @notice Onboards a new business entity to the network
     * @dev Reverts if the caller is already registered
     * @param _businessName Official trading name
     * @param _contactEmail Primary official email
     * @param _businessAddress Physical headquarters or warehouse address
     * @param _documentHash IPFS reference to business registration/licenses
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
    /**
     * @notice Modifies existing contact and verification details
     * @param _contactEmail New public email
     * @param _businessAddress Updated physical address
     * @param _documentHash Updated IPFS reference for new documents
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
    /**
     * @notice Categorizes a supplier for easier filtering (Admin only)
     * @dev Also adds to the global `availableCategories` tracker
     * @param _supplier Address of the profile to modify
     * @param _category Industry label to apply
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
    /**
     * @notice Appends a searchable tag to the caller's profile
     * @param _tag Keyword to add
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
    /**
     * @notice Marks a profile as verified after off-chain audit (Admin only)
     * @param _supplier Address to verify
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
    /**
     * @notice Prevents a supplier from participating in the network (Admin only)
     * @param _supplier Address to deactivate
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
    /**
     * @notice Fetches core profile details for a specific supplier
     * @param _supplier Address of the entity
     * @return supplierAddress Original wallet address
     * @return businessName Legal name
     * @return contactEmail Public email
     * @return businessAddress Location
     * @return documentHash Verification link
     * @return isVerified Audit status
     * @return isActive Operation status
     * @return registrationDate UNIX timestamp
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
    /**
     * @notice Retrieves all category labels applied to a supplier
     * @param _supplier Address of the entity
     * @return Array of category strings
     */
    function getSupplierCategories(address _supplier) external view returns (string[] memory) {
        return suppliers[_supplier].categories;
    }

    /**
     * @dev Get supplier tags
     */
    /**
     * @notice Retrieves all searchable tags applied to a supplier
     * @param _supplier Address of the entity
     * @return Array of tag strings
     */
    function getSupplierTags(address _supplier) external view returns (string[] memory) {
        return suppliers[_supplier].tags;
    }

    /**
     * @dev Get suppliers by category
     */
    /**
     * @notice Finds all suppliers registered under a specific category
     * @param _category The label to search for
     * @return Array of matching wallet addresses
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
    /**
     * @notice Quick check for audit status
     * @param _supplier Address to check
     * @return True if verified by admin
     */
    function isSupplierVerified(address _supplier) external view returns (bool) {
        return suppliers[_supplier].isVerified;
    }
}
