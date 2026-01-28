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
    /**
     * @notice Stores information about a registered supplier
     * @param supplierAddress Address of the supplier account
     * @param name Registered name of the supplier
     * @param contactInfo Encrypted or public contact details
     * @param isVerified Whether the supplier has passed KYC/compliance
     * @param totalOrdersCompleted Cumulative count of successfully finished orders
     * @param totalAmountEarned Total funds paid out to this supplier in WEI
     * @param registrationDate Timestamp of registration
     */
    struct Supplier {
        address supplierAddress;
        string name;
        string contactInfo;
        bool isVerified;
        uint256 totalOrdersCompleted;
        uint256 totalAmountEarned;
        uint256 registrationDate;
    }
    
    /**
     * @notice Represents a specific stage/deliverable in an order
     * @param description Narrative of what needs to be achieved
     * @param paymentPercentage Portion of total order amount released on completion (0-100)
     * @param isCompleted True if supplier has finished the milestone
     * @param isApproved True if buyer has verified and released funds for the milestone
     * @param completionDate Timestamp when supplier marked as complete
     * @param approvalDate Timestamp when buyer approved payment
     */
    struct Milestone {
        string description;
        uint256 paymentPercentage;
        bool isCompleted;
        bool isApproved;
        uint256 completionDate;
        uint256 approvalDate;
    }
    
    /**
     * @notice Full data for an active or past order
     * @param orderId Unique identifier for the order
     * @param buyer Address of the client/importer
     * @param supplier Address of the vendor/manufacturer
     * @param productDescription Summary of the goods being procured
     * @param totalAmount Total value of the order locked in escrow
     * @param paidAmount Amount already released to the supplier
     * @param createdDate Timestamp of order initiation
     * @param status Current lifecycle state of the order
     * @param milestones Array of deliverables for this order
     * @param disputeRaised True if an active dispute is open
     * @param disputeReason Text description of the conflict
     */
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
    /**
     * @notice Possible states an order can transition through
     */
    enum OrderStatus {
        Created,      // Just opened, milestones being defined
        InProgress,   // Active production/shipping
        Completed,    // All milestones approved and funds released
        Cancelled,    // Refunded before start or after dispute
        Disputed      // Paused due to conflict
    }
    
    // State variables
    /// @notice Maps supplier address to their profile data
    mapping(address => Supplier) public suppliers;
    
    /// @notice Maps order ID to the full Order struct
    mapping(uint256 => Order) public orders;
    
    /// @notice Maps buyer address to a list of their order IDs
    mapping(address => uint256[]) public buyerOrders;
    
    /// @notice Maps supplier address to a list of their order IDs
    mapping(address => uint256[]) public supplierOrders;
    
    /// @notice Incremental counter for generating unique order IDs
    uint256 public orderCounter;
    
    /// @notice Fee percentage taken by the platform (e.g. 1 = 1%)
    uint256 public platformFeePercentage = 1;
    
    /// @notice Cumulative platform fees stored in the contract in WEI
    uint256 public totalPlatformFees;
    
    // Events
    /// @notice Emitted when a new supplier registers
    /// @param supplier Address of the supplier
    /// @param name Name of the supplier
    /// @param timestamp Registration time
    event SupplierRegistered(address indexed supplier, string name, uint256 timestamp);
    
    /// @notice Emitted when a supplier is verified by the owner
    /// @param supplier Address of the verified supplier
    /// @param timestamp Verification time
    event SupplierVerified(address indexed supplier, uint256 timestamp);
    
    /// @notice Emitted when a buyer creates a new order
    /// @param orderId Unique ID of the order
    /// @param buyer Address of the buyer
    /// @param supplier Address of the supplier
    /// @param amount Total amount locked in escrow
    event OrderCreated(uint256 indexed orderId, address indexed buyer, address indexed supplier, uint256 amount);
    
    /// @notice Emitted when a milestone is added to an order
    /// @param orderId ID of the order
    /// @param milestoneIndex Index of the new milestone
    /// @param description Description of the milestone
    /// @param percentage Payment percentage for this milestone
    event MilestoneAdded(uint256 indexed orderId, uint256 milestoneIndex, string description, uint256 percentage);
    
    /// @notice Emitted when a supplier marks a milestone as completed
    /// @param orderId ID of the order
    /// @param milestoneIndex Index of the completed milestone
    /// @param timestamp Completion time
    event MilestoneCompleted(uint256 indexed orderId, uint256 milestoneIndex, uint256 timestamp);
    
    /// @notice Emitted when a buyer approves a milestone and releases funds
    /// @param orderId ID of the order
    /// @param milestoneIndex Index of the approved milestone
    /// @param paymentAmount Amount released to the supplier
    event MilestoneApproved(uint256 indexed orderId, uint256 milestoneIndex, uint256 paymentAmount);
    
    /// @notice Emitted when funds are physically released to a supplier
    /// @param orderId ID of the order
    /// @param supplier Recipient address
    /// @param amount Amount paid out
    event PaymentReleased(uint256 indexed orderId, address indexed supplier, uint256 amount);
    
    /// @notice Emitted when a party raises a dispute on an order
    /// @param orderId ID of the order
    /// @param raisedBy Address of the account raising the dispute
    /// @param reason Text reason for the dispute
    event DisputeRaised(uint256 indexed orderId, address indexed raisedBy, string reason);
    
    /// @notice Emitted when a dispute is resolved by the owner
    /// @param orderId ID of the order
    /// @param resolvedBy Address of the resolver (owner)
    /// @param inFavorOfSupplier True if supplier received the remaining funds
    event DisputeResolved(uint256 indexed orderId, address indexed resolvedBy, bool inFavorOfSupplier);
    
    /// @notice Emitted when an order is fully completed
    /// @param orderId ID of the order
    /// @param timestamp Completion time
    event OrderCompleted(uint256 indexed orderId, uint256 timestamp);
    
    /// @notice Emitted when an order is cancelled
    /// @param orderId ID of the order
    /// @param refundAmount Amount refunded to the buyer
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
    
    /**
     * @dev Approve milestone and release payment (buyer)
     * @param _orderId Order ID
     * @param _milestoneIndex Milestone index
     */
    function approveMilestone(
        uint256 _orderId,
        uint256 _milestoneIndex
    ) external orderExists(_orderId) onlyBuyer(_orderId) nonReentrant {
        Order storage order = orders[_orderId];
        require(order.status == OrderStatus.InProgress, "Order not in progress");
        require(_milestoneIndex < order.milestones.length, "Invalid milestone index");
        require(order.milestones[_milestoneIndex].isCompleted, "Milestone not completed");
        require(!order.milestones[_milestoneIndex].isApproved, "Milestone already approved");
        
        Milestone storage milestone = order.milestones[_milestoneIndex];
        milestone.isApproved = true;
        milestone.approvalDate = block.timestamp;
        
        // Calculate payment amount
        uint256 paymentAmount = (order.totalAmount * milestone.paymentPercentage) / 100;
        uint256 platformFee = (paymentAmount * platformFeePercentage) / 100;
        uint256 supplierPayment = paymentAmount - platformFee;
        
        order.paidAmount += paymentAmount;
        totalPlatformFees += platformFee;
        
        // Update supplier stats
        suppliers[order.supplier].totalAmountEarned += supplierPayment;
        
        // Transfer payment to supplier
        (bool success, ) = payable(order.supplier).call{value: supplierPayment}("");
        require(success, "Payment transfer failed");
        
        emit MilestoneApproved(_orderId, _milestoneIndex, supplierPayment);
        emit PaymentReleased(_orderId, order.supplier, supplierPayment);
        
        // Check if all milestones are approved
        bool allApproved = true;
        for (uint256 i = 0; i < order.milestones.length; i++) {
            if (!order.milestones[i].isApproved) {
                allApproved = false;
                break;
            }
        }
        
        if (allApproved) {
            order.status = OrderStatus.Completed;
            suppliers[order.supplier].totalOrdersCompleted++;
            emit OrderCompleted(_orderId, block.timestamp);
        }
    }
    
    /**
     * @dev Raise a dispute
     * @param _orderId Order ID
     * @param _reason Dispute reason
     */
    function raiseDispute(
        uint256 _orderId,
        string memory _reason
    ) external orderExists(_orderId) {
        Order storage order = orders[_orderId];
        require(
            msg.sender == order.buyer || msg.sender == order.supplier,
            "Only buyer or supplier can raise dispute"
        );
        require(order.status == OrderStatus.InProgress, "Can only dispute in-progress orders");
        require(!order.disputeRaised, "Dispute already raised");
        require(bytes(_reason).length > 0, "Reason required");
        
        order.disputeRaised = true;
        order.disputeReason = _reason;
        order.status = OrderStatus.Disputed;
        
        emit DisputeRaised(_orderId, msg.sender, _reason);
    }
    
    /**
     * @dev Resolve dispute (only owner)
     * @param _orderId Order ID
     * @param _inFavorOfSupplier True if resolving in favor of supplier
     */
    function resolveDispute(
        uint256 _orderId,
        bool _inFavorOfSupplier
    ) external orderExists(_orderId) onlyOwner nonReentrant {
        Order storage order = orders[_orderId];
        require(order.status == OrderStatus.Disputed, "Order not in dispute");
        
        uint256 remainingAmount = order.totalAmount - order.paidAmount;
        
        if (_inFavorOfSupplier) {
            // Pay remaining amount to supplier
            if (remainingAmount > 0) {
                uint256 platformFee = (remainingAmount * platformFeePercentage) / 100;
                uint256 supplierPayment = remainingAmount - platformFee;
                
                totalPlatformFees += platformFee;
                suppliers[order.supplier].totalAmountEarned += supplierPayment;
                
                (bool success, ) = payable(order.supplier).call{value: supplierPayment}("");
                require(success, "Payment transfer failed");
                
                order.paidAmount = order.totalAmount;
            }
            order.status = OrderStatus.Completed;
            suppliers[order.supplier].totalOrdersCompleted++;
        } else {
            // Refund remaining amount to buyer
            if (remainingAmount > 0) {
                (bool success, ) = payable(order.buyer).call{value: remainingAmount}("");
                require(success, "Refund transfer failed");
            }
            order.status = OrderStatus.Cancelled;
        }
        
        emit DisputeResolved(_orderId, msg.sender, _inFavorOfSupplier);
    }
    
    /**
     * @dev Cancel order (only if not started)
     * @param _orderId Order ID
     */
    function cancelOrder(uint256 _orderId) external orderExists(_orderId) onlyBuyer(_orderId) nonReentrant {
        Order storage order = orders[_orderId];
        require(order.status == OrderStatus.Created, "Can only cancel created orders");
        
        order.status = OrderStatus.Cancelled;
        uint256 refundAmount = order.totalAmount;
        
        (bool success, ) = payable(order.buyer).call{value: refundAmount}("");
        require(success, "Refund transfer failed");
        
        emit OrderCancelled(_orderId, refundAmount);
    }
    
    /**
     * @dev Withdraw platform fees (only owner)
     */
    function withdrawPlatformFees() external onlyOwner nonReentrant {
        uint256 amount = totalPlatformFees;
        require(amount > 0, "No fees to withdraw");
        
        totalPlatformFees = 0;
        
        (bool success, ) = payable(owner()).call{value: amount}("");
        require(success, "Withdrawal failed");
    }
    
    /**
     * @dev Update platform fee percentage (only owner)
     * @param _newFeePercentage New fee percentage (0-10)
     */
    function updatePlatformFee(uint256 _newFeePercentage) external onlyOwner {
        require(_newFeePercentage <= 10, "Fee cannot exceed 10%");
        platformFeePercentage = _newFeePercentage;
    }
    
    // View functions
    
    function getSupplier(address _supplier) external view returns (Supplier memory) {
        return suppliers[_supplier];
    }
    
    function getOrder(uint256 _orderId) external view returns (
        uint256 orderId,
        address buyer,
        address supplier,
        string memory productDescription,
        uint256 totalAmount,
        uint256 paidAmount,
        uint256 createdDate,
        OrderStatus status,
        bool disputeRaised
    ) {
        Order storage order = orders[_orderId];
        return (
            order.orderId,
            order.buyer,
            order.supplier,
            order.productDescription,
            order.totalAmount,
            order.paidAmount,
            order.createdDate,
            order.status,
            order.disputeRaised
        );
    }
    
    function getMilestone(uint256 _orderId, uint256 _milestoneIndex) external view returns (Milestone memory) {
        require(_milestoneIndex < orders[_orderId].milestones.length, "Invalid milestone index");
        return orders[_orderId].milestones[_milestoneIndex];
    }
    
    function getMilestoneCount(uint256 _orderId) external view returns (uint256) {
        return orders[_orderId].milestones.length;
    }
    
    function getBuyerOrders(address _buyer) external view returns (uint256[] memory) {
        return buyerOrders[_buyer];
    }
    
    function getSupplierOrders(address _supplier) external view returns (uint256[] memory) {
        return supplierOrders[_supplier];
    }
}
