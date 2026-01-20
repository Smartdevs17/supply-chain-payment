// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library PackagingValidator {
    function isValidPackageType(string memory pkgType) internal pure returns (bool) {
        bytes32 hash = keccak256(bytes(pkgType));
        return hash == keccak256(bytes("Box")) || 
               hash == keccak256(bytes("Pallet")) || 
               hash == keccak256(bytes("Container"));
    }
}
