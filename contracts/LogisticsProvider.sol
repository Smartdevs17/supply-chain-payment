// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title LogisticsProvider
 * @dev Registry and management for logistics providers
 */
contract LogisticsProvider is Ownable {
    
    struct Provider {
        uint256 providerId;
        string name;
        string serviceType;
        address walletAddress;
        bool isVerified;
        bool isActive;
        uint256 totalShipments;
        uint256 onTimeDeliveries;
        uint256 registrationDate;
    }
    
    mapping(uint256 => Provider) public providers;
    mapping(address => uint256) public addressToProviderId;
    uint256 private _providerIdCounter;
    
    event ProviderRegistered(uint256 indexed providerId, string name);
    event ProviderVerified(uint256 indexed providerId);
    event ShipmentCompleted(uint256 indexed providerId, bool onTime);
    event ProviderDeactivated(uint256 indexed providerId);
    
    constructor() Ownable(msg.sender) {
        _providerIdCounter = 1;
    }
    
    function registerProvider(
        string memory _name,
        string memory _serviceType,
        address _walletAddress
    ) external onlyOwner returns (uint256) {
        require(_walletAddress != address(0), "Invalid address");
        require(addressToProviderId[_walletAddress] == 0, "Already registered");
        require(bytes(_name).length > 0, "Name required");
        
        uint256 providerId = _providerIdCounter++;
        
        providers[providerId] = Provider({
            providerId: providerId,
            name: _name,
            serviceType: _serviceType,
            walletAddress: _walletAddress,
            isVerified: false,
            isActive: true,
            totalShipments: 0,
            onTimeDeliveries: 0,
            registrationDate: block.timestamp
        });
        
        addressToProviderId[_walletAddress] = providerId;
        
        emit ProviderRegistered(providerId, _name);
        
        return providerId;
    }
    
    function verifyProvider(uint256 _providerId) external onlyOwner {
        require(_providerId > 0 && _providerId < _providerIdCounter, "Invalid ID");
        providers[_providerId].isVerified = true;
        emit ProviderVerified(_providerId);
    }
    
    function recordShipment(uint256 _providerId, bool _onTime) external {
        require(_providerId > 0 && _providerId < _providerIdCounter, "Invalid ID");
        Provider storage provider = providers[_providerId];
        require(provider.walletAddress == msg.sender || msg.sender == owner(), "Unauthorized");
        
        provider.totalShipments++;
        if (_onTime) {
            provider.onTimeDeliveries++;
        }
        
        emit ShipmentCompleted(_providerId, _onTime);
    }
    
    function getOnTimeRate(uint256 _providerId) external view returns (uint256) {
        require(_providerId > 0 && _providerId < _providerIdCounter, "Invalid ID");
        Provider memory provider = providers[_providerId];
        
        if (provider.totalShipments == 0) return 0;
        
        return (provider.onTimeDeliveries * 100) / provider.totalShipments;
    }
    
    function deactivateProvider(uint256 _providerId) external onlyOwner {
        require(_providerId > 0 && _providerId < _providerIdCounter, "Invalid ID");
        providers[_providerId].isActive = false;
        emit ProviderDeactivated(_providerId);
    }
    
    function getTotalProviders() external view returns (uint256) {
        return _providerIdCounter - 1;
    }
}
