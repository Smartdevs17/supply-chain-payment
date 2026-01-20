// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library TrackingHelper {
    function generateTrackingHash(string memory carrier, uint256 timestamp) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(carrier, timestamp));
    }
}
