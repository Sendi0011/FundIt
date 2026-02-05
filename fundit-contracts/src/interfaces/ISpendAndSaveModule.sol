// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ISpendAndSaveModule {
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

    function autoDepositSpendAndSave(address user, uint256 originalSpendAmount) external;
    function getUserConfig(address user) external view returns (SpendAndSaveConfig memory);
    function isSpendAndSaveEnabled(address user) external view returns (bool);
}