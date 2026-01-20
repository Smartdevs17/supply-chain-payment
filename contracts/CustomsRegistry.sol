// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title CustomsRegistry
 * @dev Registry for international customs tracking
 */
contract CustomsRegistry is Ownable {
    
    struct CustomsOffice {
        string countryCode; // ISO 3166-1 alpha-2
        string officeName;
        address authority;
        bool isActive;
    }
    
    mapping(bytes2 => CustomsOffice) public customsOffices;
    
    event OfficeRegistered(bytes2 indexed countryCode, address authority);
    
    constructor() Ownable(msg.sender) {}
    
    function registerOffice(string memory _countryCode, string memory _officeName, address _authority) external onlyOwner {
        require(bytes(_countryCode).length == 2, "Invalid country code");
        bytes2 code = bytes2(bytes(_countryCode));
        
        customsOffices[code] = CustomsOffice(_countryCode, _officeName, _authority, true);
        emit OfficeRegistered(code, _authority);
    }
    
    function isAuthorized(string memory _countryCode, address _caller) external view returns (bool) {
        bytes2 code = bytes2(bytes(_countryCode));
        return customsOffices[code].isActive && customsOffices[code].authority == _caller;
    }
}
