// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

abstract contract SpendAndSaveStorage {
    
    struct SpendAndSaveConfig {
        bool enabled;
        bool isPercentage;
        uint256 value;
        uint256 minSpendThreshold;
        uint256 dailyCap;
        uint256 monthlyCap;
        uint256 dailySaved;
        uint256 monthlySaved;
        uint256 lastResetDay;
        uint256 lastResetMonth;
        uint256 destinationId;
        uint256 totalAutoSaved;
        uint256 transactionCount;
    }

    mapping(address => SpendAndSaveConfig) internal _userConfigs;
    
    mapping(address => address) internal _userVaults;
    
    mapping(bytes32 => bool) internal _processedTransactions;
    
    mapping(address => uint256) internal _lastAutoSaveTime;
    
    uint256 internal constant RATE_LIMIT_COOLDOWN = 60;

    uint256[50] private __gap;
}
