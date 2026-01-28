// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title DistributionHelper
 * @notice Utility library for calculating logistical metrics
 */
library DistributionHelper {
    /**
     * @notice Calculates the simplified distance between two coordinates
     * @dev Uses Manhattan distance for gas efficiency (suitable for grid-based logistics)
     * @param lat1 Latitude of point A
     * @param long1 Longitude of point A
     * @param lat2 Latitude of point B
     * @param long2 Longitude of point B
     * @return The calculated distance value
     */
    function calculateDistance(uint256 lat1, uint256 long1, uint256 lat2, uint256 long2) internal pure returns (uint256) {
        // Simplified Manhattan distance for MVP
        uint256 dLat = lat1 > lat2 ? lat1 - lat2 : lat2 - lat1;
        uint256 dLong = long1 > long2 ? long1 - long2 : long2 - long1;
        return dLat + dLong;
    }
}
