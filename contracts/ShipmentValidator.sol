// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library ShipmentValidator {
    function validateShipment(address sender, address receiver, uint256 weight) internal pure returns (bool) {
        return sender != address(0) && receiver != address(0) && weight > 0;
    }
}
