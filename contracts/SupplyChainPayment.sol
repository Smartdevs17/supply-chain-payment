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
    
    constructor() Ownable(msg.sender) {}
}
