// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title InsuranceEscrow
 * @dev Insurance and escrow for shipments
 */
contract InsuranceEscrow is Ownable {
    
    struct Insurance {
        uint256 shipmentId;
        address insured;
        uint256 coverageAmount;
        uint256 premium;
        uint256 startDate;
        uint256 endDate;
        bool isActive;
        bool isClaimed;
        string policyNumber;
    }
    
    mapping(uint256 => Insurance) public policies;
    mapping(uint256 => uint256) public shipmentToPolicy;
    uint256 private _policyIdCounter;
    
    event PolicyCreated(uint256 indexed policyId, uint256 shipmentId, uint256 coverageAmount);
    event ClaimFiled(uint256 indexed policyId, address indexed claimant);
    event ClaimApproved(uint256 indexed policyId, uint256 amount);
    event ClaimRejected(uint256 indexed policyId, string reason);
    
    constructor() Ownable(msg.sender) {
        _policyIdCounter = 1;
    }
    
    function createPolicy(
        uint256 _shipmentId,
        address _insured,
        uint256 _coverageAmount,
        uint256 _duration,
        string memory _policyNumber
    ) external payable returns (uint256) {
        require(_insured != address(0), "Invalid address");
        require(_coverageAmount > 0, "Invalid coverage");
        require(msg.value > 0, "Premium required");
        
        uint256 policyId = _policyIdCounter++;
        
        policies[policyId] = Insurance({
            shipmentId: _shipmentId,
            insured: _insured,
            coverageAmount: _coverageAmount,
            premium: msg.value,
            startDate: block.timestamp,
            endDate: block.timestamp + _duration,
            isActive: true,
            isClaimed: false,
            policyNumber: _policyNumber
        });
        
        shipmentToPolicy[_shipmentId] = policyId;
        
        emit PolicyCreated(policyId, _shipmentId, _coverageAmount);
        
        return policyId;
    }
    
    function fileClaim(uint256 _policyId) external {
        require(_policyId > 0 && _policyId < _policyIdCounter, "Invalid policy");
        Insurance storage policy = policies[_policyId];
        require(policy.insured == msg.sender, "Not insured");
        require(policy.isActive, "Policy not active");
        require(!policy.isClaimed, "Already claimed");
        require(block.timestamp <= policy.endDate, "Policy expired");
        
        emit ClaimFiled(_policyId, msg.sender);
    }
    
    function approveClaim(uint256 _policyId, uint256 _amount) external onlyOwner {
        require(_policyId > 0 && _policyId < _policyIdCounter, "Invalid policy");
        Insurance storage policy = policies[_policyId];
        require(policy.isActive, "Policy not active");
        require(!policy.isClaimed, "Already claimed");
        require(_amount <= policy.coverageAmount, "Exceeds coverage");
        
        policy.isClaimed = true;
        policy.isActive = false;
        
        payable(policy.insured).transfer(_amount);
        
        emit ClaimApproved(_policyId, _amount);
    }
    
    function rejectClaim(uint256 _policyId, string memory _reason) external onlyOwner {
        require(_policyId > 0 && _policyId < _policyIdCounter, "Invalid policy");
        
        emit ClaimRejected(_policyId, _reason);
    }
    
    function getPolicy(uint256 _policyId) external view returns (Insurance memory) {
        require(_policyId > 0 && _policyId < _policyIdCounter, "Invalid policy");
        return policies[_policyId];
    }
    
    receive() external payable {}
}
