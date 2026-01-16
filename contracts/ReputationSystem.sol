// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title ReputationSystem
 * @dev Supplier reputation and rating system with reviews and badges
 */
contract ReputationSystem is Ownable {
    
    struct Review {
        uint256 reviewId;
        address reviewer;
        address supplier;
        uint256 orderId;
        uint8 rating; // 1-5 stars
        string comment;
        uint256 timestamp;
        bool isVerified; // Verified if linked to completed order
    }

    struct SupplierReputation {
        uint256 totalReviews;
        uint256 totalRating;
        uint256 averageRating; // Scaled by 100 (e.g., 450 = 4.50 stars)
        uint256[] reviewIds;
        string[] badges;
    }

    // State variables
    uint256 public reviewCounter;
    
    // Mappings
    mapping(uint256 => Review) public reviews;
    mapping(address => SupplierReputation) public reputations;
    mapping(address => mapping(uint256 => bool)) public hasReviewed; // reviewer => orderId => bool
    
    // Badge definitions
    string[] public availableBadges;

    // Events
    event ReviewSubmitted(
        uint256 indexed reviewId,
        address indexed reviewer,
        address indexed supplier,
        uint8 rating,
        uint256 timestamp
    );
    
    event ReviewVerified(
        uint256 indexed reviewId,
        uint256 orderId
    );
    
    event BadgeAwarded(
        address indexed supplier,
        string badge,
        uint256 timestamp
    );
    
    event ReputationUpdated(
        address indexed supplier,
        uint256 newAverageRating,
        uint256 totalReviews
    );

    constructor() Ownable(msg.sender) {
        // Initialize default badges
        availableBadges.push("Verified Supplier");
        availableBadges.push("Top Rated");
        availableBadges.push("Fast Delivery");
        availableBadges.push("Quality Products");
        availableBadges.push("Excellent Service");
    }

    /**
     * @dev Submit a review for a supplier
     */
    function submitReview(
        address _supplier,
        uint256 _orderId,
        uint8 _rating,
        string memory _comment
    ) external returns (uint256) {
        require(_supplier != address(0), "Invalid supplier");
        require(_supplier != msg.sender, "Cannot review yourself");
        require(_rating >= 1 && _rating <= 5, "Rating must be 1-5");
        require(!hasReviewed[msg.sender][_orderId], "Already reviewed this order");

        uint256 reviewId = reviewCounter++;
        
        Review storage newReview = reviews[reviewId];
        newReview.reviewId = reviewId;
        newReview.reviewer = msg.sender;
        newReview.supplier = _supplier;
        newReview.orderId = _orderId;
        newReview.rating = _rating;
        newReview.comment = _comment;
        newReview.timestamp = block.timestamp;
        newReview.isVerified = false;

        hasReviewed[msg.sender][_orderId] = true;
        
        // Update supplier reputation
        _updateReputation(_supplier, reviewId, _rating);

        emit ReviewSubmitted(reviewId, msg.sender, _supplier, _rating, block.timestamp);
        
        return reviewId;
    }

    /**
     * @dev Verify a review (owner only)
     */
    function verifyReview(uint256 _reviewId) external onlyOwner {
        require(_reviewId < reviewCounter, "Review does not exist");
        require(!reviews[_reviewId].isVerified, "Already verified");

        reviews[_reviewId].isVerified = true;

        emit ReviewVerified(_reviewId, reviews[_reviewId].orderId);
    }

    /**
     * @dev Award badge to supplier (owner only)
     */
    function awardBadge(address _supplier, string memory _badge) external onlyOwner {
        require(_supplier != address(0), "Invalid supplier");
        
        // Check if badge exists
        bool badgeExists = false;
        for (uint256 i = 0; i < availableBadges.length; i++) {
            if (keccak256(bytes(availableBadges[i])) == keccak256(bytes(_badge))) {
                badgeExists = true;
                break;
            }
        }
        require(badgeExists, "Badge does not exist");
        
        // Check if supplier already has this badge
        string[] storage supplierBadges = reputations[_supplier].badges;
        for (uint256 i = 0; i < supplierBadges.length; i++) {
            require(
                keccak256(bytes(supplierBadges[i])) != keccak256(bytes(_badge)),
                "Supplier already has this badge"
            );
        }
        
        reputations[_supplier].badges.push(_badge);

        emit BadgeAwarded(_supplier, _badge, block.timestamp);
    }

    /**
     * @dev Add new badge type (owner only)
     */
    function addBadgeType(string memory _badge) external onlyOwner {
        availableBadges.push(_badge);
    }

    /**
     * @dev Get supplier reputation details
     */
    function getSupplierReputation(address _supplier) external view returns (
        uint256 totalReviews,
        uint256 averageRating,
        uint256[] memory reviewIds,
        string[] memory badges
    ) {
        SupplierReputation memory rep = reputations[_supplier];
        return (
            rep.totalReviews,
            rep.averageRating,
            rep.reviewIds,
            rep.badges
        );
    }

    /**
     * @dev Get review details
     */
    function getReview(uint256 _reviewId) external view returns (
        address reviewer,
        address supplier,
        uint256 orderId,
        uint8 rating,
        string memory comment,
        uint256 timestamp,
        bool isVerified
    ) {
        Review memory review = reviews[_reviewId];
        return (
            review.reviewer,
            review.supplier,
            review.orderId,
            review.rating,
            review.comment,
            review.timestamp,
            review.isVerified
        );
    }

    /**
     * @dev Get supplier reviews
     */
    function getSupplierReviews(address _supplier) external view returns (uint256[] memory) {
        return reputations[_supplier].reviewIds;
    }

    /**
     * @dev Get supplier badges
     */
    function getSupplierBadges(address _supplier) external view returns (string[] memory) {
        return reputations[_supplier].badges;
    }

    /**
     * @dev Get all available badges
     */
    function getAvailableBadges() external view returns (string[] memory) {
        return availableBadges;
    }

    /**
     * @dev Check if user has reviewed an order
     */
    function hasUserReviewedOrder(address _user, uint256 _orderId) external view returns (bool) {
        return hasReviewed[_user][_orderId];
    }

    /**
     * @dev Get total number of reviews
     */
    function getTotalReviews() external view returns (uint256) {
        return reviewCounter;
    }

    /**
     * @dev Internal function to update supplier reputation
     */
    function _updateReputation(address _supplier, uint256 _reviewId, uint8 _rating) private {
        SupplierReputation storage rep = reputations[_supplier];
        
        rep.totalReviews++;
        rep.totalRating += _rating;
        rep.reviewIds.push(_reviewId);
        
        // Calculate average rating (scaled by 100)
        rep.averageRating = (rep.totalRating * 100) / rep.totalReviews;

        emit ReputationUpdated(_supplier, rep.averageRating, rep.totalReviews);
    }
}
