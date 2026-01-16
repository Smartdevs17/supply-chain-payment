// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title ProductCatalog
 * @dev Product listing and inventory management system for suppliers
 */
contract ProductCatalog is Ownable {
    
    struct Product {
        uint256 productId;
        address supplier;
        string name;
        string description;
        string imageHash; // IPFS hash for product images
        string category;
        uint256 price; // Price in wei
        uint256 inventory;
        bool isActive;
        uint256 createdDate;
        uint256 lastUpdated;
    }

    // State variables
    uint256 public productCounter;
    
    // Mappings
    mapping(uint256 => Product) public products;
    mapping(address => uint256[]) public supplierProducts;
    mapping(string => uint256[]) public categoryProducts;
    
    string[] public availableCategories;

    // Events
    event ProductAdded(
        uint256 indexed productId,
        address indexed supplier,
        string name,
        uint256 price,
        uint256 timestamp
    );
    
    event ProductUpdated(
        uint256 indexed productId,
        uint256 timestamp
    );
    
    event InventoryUpdated(
        uint256 indexed productId,
        uint256 newInventory,
        uint256 timestamp
    );
    
    event PriceUpdated(
        uint256 indexed productId,
        uint256 newPrice,
        uint256 timestamp
    );
    
    event ProductDeactivated(
        uint256 indexed productId,
        uint256 timestamp
    );

    constructor() Ownable(msg.sender) {}

    /**
     * @dev Add a new product
     */
    function addProduct(
        string memory _name,
        string memory _description,
        string memory _imageHash,
        string memory _category,
        uint256 _price,
        uint256 _inventory
    ) external returns (uint256) {
        require(bytes(_name).length > 0, "Product name required");
        require(_price > 0, "Price must be greater than 0");

        uint256 productId = productCounter++;
        
        Product storage newProduct = products[productId];
        newProduct.productId = productId;
        newProduct.supplier = msg.sender;
        newProduct.name = _name;
        newProduct.description = _description;
        newProduct.imageHash = _imageHash;
        newProduct.category = _category;
        newProduct.price = _price;
        newProduct.inventory = _inventory;
        newProduct.isActive = true;
        newProduct.createdDate = block.timestamp;
        newProduct.lastUpdated = block.timestamp;

        supplierProducts[msg.sender].push(productId);
        categoryProducts[_category].push(productId);
        
        // Add category if new
        _addCategoryIfNew(_category);

        emit ProductAdded(productId, msg.sender, _name, _price, block.timestamp);
        
        return productId;
    }

    /**
     * @dev Update product details
     */
    function updateProduct(
        uint256 _productId,
        string memory _description,
        string memory _imageHash,
        string memory _category
    ) external {
        Product storage product = products[_productId];
        require(product.supplier == msg.sender, "Not product owner");
        require(product.isActive, "Product not active");

        product.description = _description;
        product.imageHash = _imageHash;
        
        // Update category if changed
        if (keccak256(bytes(product.category)) != keccak256(bytes(_category))) {
            product.category = _category;
            categoryProducts[_category].push(_productId);
            _addCategoryIfNew(_category);
        }
        
        product.lastUpdated = block.timestamp;

        emit ProductUpdated(_productId, block.timestamp);
    }

    /**
     * @dev Update product inventory
     */
    function updateInventory(uint256 _productId, uint256 _newInventory) external {
        Product storage product = products[_productId];
        require(product.supplier == msg.sender, "Not product owner");
        require(product.isActive, "Product not active");

        product.inventory = _newInventory;
        product.lastUpdated = block.timestamp;

        emit InventoryUpdated(_productId, _newInventory, block.timestamp);
    }

    /**
     * @dev Increase inventory
     */
    function increaseInventory(uint256 _productId, uint256 _amount) external {
        Product storage product = products[_productId];
        require(product.supplier == msg.sender, "Not product owner");
        require(product.isActive, "Product not active");

        product.inventory += _amount;
        product.lastUpdated = block.timestamp;

        emit InventoryUpdated(_productId, product.inventory, block.timestamp);
    }

    /**
     * @dev Decrease inventory
     */
    function decreaseInventory(uint256 _productId, uint256 _amount) external {
        Product storage product = products[_productId];
        require(product.supplier == msg.sender, "Not product owner");
        require(product.isActive, "Product not active");
        require(product.inventory >= _amount, "Insufficient inventory");

        product.inventory -= _amount;
        product.lastUpdated = block.timestamp;

        emit InventoryUpdated(_productId, product.inventory, block.timestamp);
    }

    /**
     * @dev Update product price
     */
    function updatePrice(uint256 _productId, uint256 _newPrice) external {
        Product storage product = products[_productId];
        require(product.supplier == msg.sender, "Not product owner");
        require(product.isActive, "Product not active");
        require(_newPrice > 0, "Price must be greater than 0");

        product.price = _newPrice;
        product.lastUpdated = block.timestamp;

        emit PriceUpdated(_productId, _newPrice, block.timestamp);
    }

    /**
     * @dev Deactivate product
     */
    function deactivateProduct(uint256 _productId) external {
        Product storage product = products[_productId];
        require(product.supplier == msg.sender, "Not product owner");
        require(product.isActive, "Already deactivated");

        product.isActive = false;
        product.lastUpdated = block.timestamp;

        emit ProductDeactivated(_productId, block.timestamp);
    }

    /**
     * @dev Get product details
     */
    function getProduct(uint256 _productId) external view returns (
        uint256 productId,
        address supplier,
        string memory name,
        string memory description,
        string memory imageHash,
        string memory category,
        uint256 price,
        uint256 inventory,
        bool isActive
    ) {
        Product memory product = products[_productId];
        return (
            product.productId,
            product.supplier,
            product.name,
            product.description,
            product.imageHash,
            product.category,
            product.price,
            product.inventory,
            product.isActive
        );
    }

    /**
     * @dev Get products by supplier
     */
    function getProductsBySupplier(address _supplier) external view returns (uint256[] memory) {
        return supplierProducts[_supplier];
    }

    /**
     * @dev Get products by category
     */
    function getProductsByCategory(string memory _category) external view returns (uint256[] memory) {
        return categoryProducts[_category];
    }

    /**
     * @dev Get all available categories
     */
    function getAvailableCategories() external view returns (string[] memory) {
        return availableCategories;
    }

    /**
     * @dev Get total number of products
     */
    function getTotalProducts() external view returns (uint256) {
        return productCounter;
    }

    /**
     * @dev Check if product is in stock
     */
    function isInStock(uint256 _productId) external view returns (bool) {
        return products[_productId].inventory > 0 && products[_productId].isActive;
    }

    /**
     * @dev Internal function to add category if new
     */
    function _addCategoryIfNew(string memory _category) private {
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
    }
}
