// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library ShippingCalculator {
    function calculateCost(uint256 weight, uint256 distance, uint256 rate) internal pure returns (uint256) {
        return weight * distance * rate;
    }
}
