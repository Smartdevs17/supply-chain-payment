// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title CustomsCompliance
 * @dev Track customs clearance for international shipments
 */
contract CustomsCompliance is Ownable {
    
    struct CustomsDeclaration {
        uint256 shipmentId;
        string originCountry;
        string destinationCountry;
        uint256 declaredValue;
        string hsCode;
        bool isCleared;
        uint256 clearanceDate;
        string customsOfficer;
        string[] documents;
    }
    
    mapping(uint256 => CustomsDeclaration) public declarations;
    mapping(uint256 => bool) public requiresInspection;
    uint256 private _declarationIdCounter;
    
    event DeclarationFiled(uint256 indexed declarationId, uint256 shipmentId);
    event CustomsCleared(uint256 indexed declarationId, uint256 clearanceDate);
    event InspectionRequired(uint256 indexed declarationId);
    
    constructor() Ownable(msg.sender) {
        _declarationIdCounter = 1;
    }
    
    function fileDeclaration(
        uint256 _shipmentId,
        string memory _originCountry,
        string memory _destinationCountry,
        uint256 _declaredValue,
        string memory _hsCode,
        string[] memory _documents
    ) external returns (uint256) {
        uint256 declarationId = _declarationIdCounter++;
        
        declarations[declarationId] = CustomsDeclaration({
            shipmentId: _shipmentId,
            originCountry: _originCountry,
            destinationCountry: _destinationCountry,
            declaredValue: _declaredValue,
            hsCode: _hsCode,
            isCleared: false,
            clearanceDate: 0,
            customsOfficer: "",
            documents: _documents
        });
        
        emit DeclarationFiled(declarationId, _shipmentId);
        
        return declarationId;
    }
    
    function clearCustoms(uint256 _declarationId, string memory _officer) external onlyOwner {
        require(_declarationId > 0 && _declarationId < _declarationIdCounter, "Invalid ID");
        
        declarations[_declarationId].isCleared = true;
        declarations[_declarationId].clearanceDate = block.timestamp;
        declarations[_declarationId].customsOfficer = _officer;
        
        emit CustomsCleared(_declarationId, block.timestamp);
    }
    
    function flagForInspection(uint256 _declarationId) external onlyOwner {
        require(_declarationId > 0 && _declarationId < _declarationIdCounter, "Invalid ID");
        
        requiresInspection[_declarationId] = true;
        
        emit InspectionRequired(_declarationId);
    }
    
    function getDeclaration(uint256 _declarationId) external view returns (CustomsDeclaration memory) {
        require(_declarationId > 0 && _declarationId < _declarationIdCounter, "Invalid ID");
        return declarations[_declarationId];
    }
}
