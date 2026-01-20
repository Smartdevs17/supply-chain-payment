// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library QualityStandards {
    struct Standard {
        uint256 minTemperature;
        uint256 maxTemperature;
        uint256 maxHumidity;
        bool requiresInspection;
    }
    
    function isValid(Standard memory s, uint256 temp, uint256 humidity) internal pure returns (bool) {
        return temp >= s.minTemperature && temp <= s.maxTemperature && humidity <= s.maxHumidity;
    }
}
