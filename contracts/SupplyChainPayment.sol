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
    
    constructor() Ownable(msg.sender) {}
}
