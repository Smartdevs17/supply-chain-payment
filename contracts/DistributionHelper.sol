// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library DistributionHelper {
    function calculateDistance(uint256 lat1, uint256 long1, uint256 lat2, uint256 long2) internal pure returns (uint256) {
        // Simplified Manhattan distance for MVP
        uint256 dLat = lat1 > lat2 ? lat1 - lat2 : lat2 - lat1;
        uint256 dLong = long1 > long2 ? long1 - long2 : long2 - long1;
        return dLat + dLong;
    }
}
