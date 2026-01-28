// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title LogisticsProvider
 * @dev Registry and management for logistics providers
 */
contract LogisticsProvider is Ownable {
    
    /**
     * @notice Data structure for a registered logistics provider
     * @param providerId Unique identifier for the provider
     * @param name Company or trading name
     * @param serviceType Type of logistics (e.g., Courier, Freight, Cold Chain)
     * @param walletAddress The blockchain address for signing and receiving payments
     * @param isVerified True if the provider's credentials have been audited
     * @param isActive True if the provider is currently available for hire
     * @param totalShipments Cumulative count of handled shipments
     * @param onTimeDeliveries count of shipments delivered within SLA
     * @param registrationDate UNIX timestamp of registration
     */
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
    
    /// @notice Maps provider ID to their full profile
    mapping(uint256 => Provider) public providers;
    
    /// @notice Quick lookup to find a provider ID by wallet address
    mapping(address => uint256) public addressToProviderId;
    
    /// @dev Internal tracker for assigning unique provider IDs
    uint256 private _providerIdCounter;
    
    /// @notice Emitted when a new provider registers
    event ProviderRegistered(uint256 indexed providerId, string name);
    
    /// @notice Emitted when a provider's status is upgraded to verified
    event ProviderVerified(uint256 indexed providerId);
    
    /// @notice Emitted upon recording a completed shipment
    event ShipmentCompleted(uint256 indexed providerId, bool onTime);
    
    /// @notice Emitted when a provider is suspended or removed
    event ProviderDeactivated(uint256 indexed providerId);
    
    constructor() Ownable(msg.sender) {
        _providerIdCounter = 1;
    }
    
    /**
     * @notice Onboards a new logistics provider (Admin only)
     * @param _name Company name
     * @param _serviceType Logistics specialty
     * @param _walletAddress official blockchain address
     * @return The unique ID assigned
     */
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
    
    /**
     * @notice Marks a provider as officially verified (Admin only)
     * @param _providerId Unique identifier
     */
    function verifyProvider(uint256 _providerId) external onlyOwner {
        require(_providerId > 0 && _providerId < _providerIdCounter, "Invalid ID");
        providers[_providerId].isVerified = true;
        emit ProviderVerified(_providerId);
    }
    
    /**
     * @notice Records the completion and punctuality of a shipment
     * @dev Only the provider themselves or the admin can call this
     * @param _providerId Unique identifier
     * @param _onTime True if delivered within SLA
     */
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
    
    /**
     * @notice Calculates the percentage of shipments delivered on time
     * @param _providerId Unique identifier
     * @return The rate as a percentage (0-100)
     */
    function getOnTimeRate(uint256 _providerId) external view returns (uint256) {
        require(_providerId > 0 && _providerId < _providerIdCounter, "Invalid ID");
        Provider memory provider = providers[_providerId];
        
        if (provider.totalShipments == 0) return 0;
        
        return (provider.onTimeDeliveries * 100) / provider.totalShipments;
    }
    
    /**
     * @notice Suspends a provider from the network (Admin only)
     * @param _providerId Unique identifier
     */
    function deactivateProvider(uint256 _providerId) external onlyOwner {
        require(_providerId > 0 && _providerId < _providerIdCounter, "Invalid ID");
        providers[_providerId].isActive = false;
        emit ProviderDeactivated(_providerId);
    }
    
    /**
     * @notice Fetches the current total of registered providers
     * @return Total count
     */
    function getTotalProviders() external view returns (uint256) {
        return _providerIdCounter - 1;
    }
}
