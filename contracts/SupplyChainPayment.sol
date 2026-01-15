// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title SupplyChainPayment
 * @dev Automated supply chain payment system with milestone-based payments and escrow
 */
contract SupplyChainPayment is Ownable, ReentrancyGuard {
    
    // Structs
    struct Supplier {
        address supplierAddress;
        string name;
        string contactInfo;
        bool isVerified;
        uint256 totalOrdersCompleted;
        uint256 totalAmountEarned;
        uint256 registrationDate;
    }
    
    struct Milestone {
        string description;
        uint256 paymentPercentage;
        bool isCompleted;
        bool isApproved;
        uint256 completionDate;
        uint256 approvalDate;
    }
    
    struct Order {
        uint256 orderId;
        address buyer;
        address supplier;
        string productDescription;
        uint256 totalAmount;
        uint256 paidAmount;
        uint256 createdDate;
        OrderStatus status;
        Milestone[] milestones;
        bool disputeRaised;
        string disputeReason;
    }
    
    // Enums
    enum OrderStatus {
        Created,
        InProgress,
        Completed,
        Cancelled,
        Disputed
    }
    
    // State variables
    mapping(address => Supplier) public suppliers;
    mapping(uint256 => Order) public orders;
    mapping(address => uint256[]) public buyerOrders;
    mapping(address => uint256[]) public supplierOrders;
    
    uint256 public orderCounter;
    uint256 public platformFeePercentage = 1;
    uint256 public totalPlatformFees;
    
    // Events
    event SupplierRegistered(address indexed supplier, string name, uint256 timestamp);
    event SupplierVerified(address indexed supplier, uint256 timestamp);
    event OrderCreated(uint256 indexed orderId, address indexed buyer, address indexed supplier, uint256 amount);
    event MilestoneAdded(uint256 indexed orderId, uint256 milestoneIndex, string description, uint256 percentage);
    event MilestoneCompleted(uint256 indexed orderId, uint256 milestoneIndex, uint256 timestamp);
    event MilestoneApproved(uint256 indexed orderId, uint256 milestoneIndex, uint256 paymentAmount);
    event PaymentReleased(uint256 indexed orderId, address indexed supplier, uint256 amount);
    event DisputeRaised(uint256 indexed orderId, address indexed raisedBy, string reason);
    event DisputeResolved(uint256 indexed orderId, address indexed resolvedBy, bool inFavorOfSupplier);
    event OrderCompleted(uint256 indexed orderId, uint256 timestamp);
    event OrderCancelled(uint256 indexed orderId, uint256 refundAmount);
    
    // Modifiers
    modifier onlyBuyer(uint256 _orderId) {
        require(orders[_orderId].buyer == msg.sender, "Only buyer can perform this action");
        _;
    }
    
    modifier onlySupplier(uint256 _orderId) {
        require(orders[_orderId].supplier == msg.sender, "Only supplier can perform this action");
        _;
    }
    
    modifier orderExists(uint256 _orderId) {
        require(_orderId < orderCounter, "Order does not exist");
        _;
    }
    
    modifier validSupplier(address _supplier) {
        require(suppliers[_supplier].supplierAddress != address(0), "Supplier not registered");
        require(suppliers[_supplier].isVerified, "Supplier not verified");
        _;
    }
    
    constructor() Ownable(msg.sender) {}
    
    /**
     * @dev Register as a supplier
     * @param _name Supplier name
     * @param _contactInfo Contact information
     */
    function registerSupplier(string memory _name, string memory _contactInfo) external {
        require(suppliers[msg.sender].supplierAddress == address(0), "Supplier already registered");
        require(bytes(_name).length > 0, "Name cannot be empty");
        
        suppliers[msg.sender] = Supplier({
            supplierAddress: msg.sender,
            name: _name,
            contactInfo: _contactInfo,
            isVerified: false,
            totalOrdersCompleted: 0,
            totalAmountEarned: 0,
            registrationDate: block.timestamp
        });
        
        emit SupplierRegistered(msg.sender, _name, block.timestamp);
    }
    
    /**
     * @dev Verify a supplier (only owner)
     * @param _supplier Supplier address to verify
     */
    function verifySupplier(address _supplier) external onlyOwner {
        require(suppliers[_supplier].supplierAddress != address(0), "Supplier not registered");
        require(!suppliers[_supplier].isVerified, "Supplier already verified");
        
        suppliers[_supplier].isVerified = true;
        emit SupplierVerified(_supplier, block.timestamp);
    }
    
    /**
     * @dev Create a new order with escrow
     * @param _supplier Supplier address
     * @param _productDescription Description of products/services
     */
    function createOrder(
        address _supplier,
        string memory _productDescription
    ) external payable validSupplier(_supplier) {
        require(msg.value > 0, "Order amount must be greater than 0");
        require(bytes(_productDescription).length > 0, "Product description required");
        require(_supplier != msg.sender, "Cannot create order with yourself");
        
        uint256 orderId = orderCounter++;
        
        Order storage newOrder = orders[orderId];
        newOrder.orderId = orderId;
        newOrder.buyer = msg.sender;
        newOrder.supplier = _supplier;
        newOrder.productDescription = _productDescription;
        newOrder.totalAmount = msg.value;
        newOrder.paidAmount = 0;
        newOrder.createdDate = block.timestamp;
        newOrder.status = OrderStatus.Created;
        newOrder.disputeRaised = false;
        
        buyerOrders[msg.sender].push(orderId);
        supplierOrders[_supplier].push(orderId);
        
        emit OrderCreated(orderId, msg.sender, _supplier, msg.value);
    }
    
    /**
     * @dev Add milestone to an order
     * @param _orderId Order ID
     * @param _description Milestone description
     * @param _paymentPercentage Percentage of total amount (0-100)
     */
    function addMilestone(
        uint256 _orderId,
        string memory _description,
        uint256 _paymentPercentage
    ) external orderExists(_orderId) onlyBuyer(_orderId) {
        Order storage order = orders[_orderId];
        require(order.status == OrderStatus.Created, "Can only add milestones to created orders");
        require(_paymentPercentage > 0 && _paymentPercentage <= 100, "Invalid percentage");
        require(bytes(_description).length > 0, "Description required");
        
        // Check total percentage doesn't exceed 100%
        uint256 totalPercentage = 0;
        for (uint256 i = 0; i < order.milestones.length; i++) {
            totalPercentage += order.milestones[i].paymentPercentage;
        }
        require(totalPercentage + _paymentPercentage <= 100, "Total percentage exceeds 100%");
        
        order.milestones.push(Milestone({
            description: _description,
            paymentPercentage: _paymentPercentage,
            isCompleted: false,
            isApproved: false,
            completionDate: 0,
            approvalDate: 0
        }));
        
        emit MilestoneAdded(_orderId, order.milestones.length - 1, _description, _paymentPercentage);
    }
    
    /**
     * @dev Start order (move to InProgress)
     * @param _orderId Order ID
     */
    function startOrder(uint256 _orderId) external orderExists(_orderId) onlyBuyer(_orderId) {
        Order storage order = orders[_orderId];
        require(order.status == OrderStatus.Created, "Order already started");
        require(order.milestones.length > 0, "Must add at least one milestone");
        
        // Verify milestones add up to 100%
        uint256 totalPercentage = 0;
        for (uint256 i = 0; i < order.milestones.length; i++) {
            totalPercentage += order.milestones[i].paymentPercentage;
        }
        require(totalPercentage == 100, "Milestones must total 100%");
        
        order.status = OrderStatus.InProgress;
    }
    
    /**
     * @dev Mark milestone as completed (supplier)
     * @param _orderId Order ID
     * @param _milestoneIndex Milestone index
     */
    function completeMilestone(
        uint256 _orderId,
        uint256 _milestoneIndex
    ) external orderExists(_orderId) onlySupplier(_orderId) {
        Order storage order = orders[_orderId];
        require(order.status == OrderStatus.InProgress, "Order not in progress");
        require(_milestoneIndex < order.milestones.length, "Invalid milestone index");
        require(!order.milestones[_milestoneIndex].isCompleted, "Milestone already completed");
        
        order.milestones[_milestoneIndex].isCompleted = true;
        order.milestones[_milestoneIndex].completionDate = block.timestamp;
        
        emit MilestoneCompleted(_orderId, _milestoneIndex, block.timestamp);
    }
}
