// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title PaymentEscrow
 * @dev Escrow service for supply chain payments
 */
contract PaymentEscrow is Ownable, ReentrancyGuard {
    
    /// @notice Lifecycle stages of an escrow arrangement
    enum EscrowStatus { Created, Funded, Completed, Refunded, Disputed }
    
    /**
     * @notice Container for individual escrow transaction data
     * @param orderId External reference to the business order
     * @param buyer The party paying for the goods/services
     * @param seller The party providing the goods/services
     * @param token Address of the payment token (address(0) for Native/ETH)
     * @param amount Total value held in escrow
     * @param releaseTime Earliest possible time for automatic release (if implemented)
     * @param status Current phase in the lifecycle
     * @param buyerApproval True if buyer has signed off on release
     * @param sellerApproval True if seller has signed off on release
     */
    struct Escrow {
        uint256 orderId;
        address buyer;
        address seller;
        address token;
        uint256 amount;
        uint256 releaseTime;
        EscrowStatus status;
        bool buyerApproval;
        bool sellerApproval;
    }
    
    /// @notice Maps unique escrow IDs to their respective records
    mapping(uint256 => Escrow) public escrows;
    
    /// @dev Internal counter for assigning unique escrow identifiers
    uint256 private _escrowIdCounter;
    
    /// @notice Emitted when a new escrow agreement is recorded
    event EscrowCreated(uint256 indexed escrowId, uint256 orderId, address buyer, address seller, uint256 amount);
    
    /// @notice Emitted when the buyer deposits the required funds
    event EscrowFunded(uint256 indexed escrowId, uint256 amount);
    
    /// @notice Emitted when funds are successfully released to the seller
    event EscrowReleased(uint256 indexed escrowId, address recipient, uint256 amount);
    
    /// @notice Emitted when funds are returned to the buyer (refund)
    event EscrowRefunded(uint256 indexed escrowId, address recipient, uint256 amount);
    
    /// @notice Emitted when a dispute is formally raised by either party
    event EscrowDisputed(uint256 indexed escrowId);
    
    constructor() Ownable(msg.sender) {
        _escrowIdCounter = 1;
    }
    
    function createEscrow(
        uint256 _orderId,
        address _seller,
        address _token,
        uint256 _amount,
        uint256 _lockDuration
    ) external returns (uint256) {
        require(_seller != address(0), "Invalid seller");
        require(_amount > 0, "Amount must be > 0");
        
        uint256 escrowId = _escrowIdCounter++;
        
        escrows[escrowId] = Escrow({
            orderId: _orderId,
            buyer: msg.sender,
            seller: _seller,
            token: _token,
            amount: _amount,
            releaseTime: block.timestamp + _lockDuration,
            status: EscrowStatus.Created,
            buyerApproval: false,
            sellerApproval: false
        });
        
        emit EscrowCreated(escrowId, _orderId, msg.sender, _seller, _amount);
        
        return escrowId;
    }
    
    function fundEscrow(uint256 _escrowId) external payable nonReentrant {
        Escrow storage escrow = escrows[_escrowId];
        require(escrow.status == EscrowStatus.Created, "Invalid status");
        require(msg.sender == escrow.buyer, "Not buyer");
        
        if (escrow.token == address(0)) {
            require(msg.value == escrow.amount, "Incorrect amount");
        } else {
            IERC20(escrow.token).transferFrom(msg.sender, address(this), escrow.amount);
        }
        
        escrow.status = EscrowStatus.Funded;
        emit EscrowFunded(_escrowId, escrow.amount);
    }
    
    function approveRelease(uint256 _escrowId) external {
        Escrow storage escrow = escrows[_escrowId];
        require(escrow.status == EscrowStatus.Funded, "Invalid status");
        
        if (msg.sender == escrow.buyer) {
            escrow.buyerApproval = true;
        } else if (msg.sender == escrow.seller) {
            escrow.sellerApproval = true;
        } else {
            revert("Unauthorized");
        }
        
        if (escrow.buyerApproval && escrow.sellerApproval) {
            _releaseFunds(_escrowId);
        }
    }
    
    function _releaseFunds(uint256 _escrowId) internal {
        Escrow storage escrow = escrows[_escrowId];
        escrow.status = EscrowStatus.Completed;
        
        if (escrow.token == address(0)) {
            payable(escrow.seller).transfer(escrow.amount);
        } else {
            IERC20(escrow.token).transfer(escrow.seller, escrow.amount);
        }
        
        emit EscrowReleased(_escrowId, escrow.seller, escrow.amount);
    }
    
    function refundBuyer(uint256 _escrowId) external onlyOwner {
        Escrow storage escrow = escrows[_escrowId];
        require(escrow.status == EscrowStatus.Funded || escrow.status == EscrowStatus.Disputed, "Invalid status");
        
        escrow.status = EscrowStatus.Refunded;
        
        if (escrow.token == address(0)) {
            payable(escrow.buyer).transfer(escrow.amount);
        } else {
            IERC20(escrow.token).transfer(escrow.buyer, escrow.amount);
        }
        
        emit EscrowRefunded(_escrowId, escrow.buyer, escrow.amount);
    }
    
    function raiseDispute(uint256 _escrowId) external {
        Escrow storage escrow = escrows[_escrowId];
        require(msg.sender == escrow.buyer || msg.sender == escrow.seller, "Unauthorized");
        require(escrow.status == EscrowStatus.Funded, "Invalid status");
        
        escrow.status = EscrowStatus.Disputed;
        emit EscrowDisputed(_escrowId);
    }
}
