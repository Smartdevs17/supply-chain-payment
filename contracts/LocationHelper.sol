// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library LocationHelper {
    struct Coordinates {
        int256 latitude;
        int256 longitude;
    }
    
    function isValidCoordinates(int256 lat, int256 long) internal pure returns (bool) {
        return lat >= -90000000 && lat <= 90000000 && long >= -180000000 && long <= 180000000;
    }
}
