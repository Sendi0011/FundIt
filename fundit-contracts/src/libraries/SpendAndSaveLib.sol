// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title SpendAndSaveLib
 * @notice Library for Spend & Save calculations and validations
 */
library SpendAndSaveLib {
    uint256 constant MAX_PERCENTAGE = 50;
    uint256 constant MIN_PERCENTAGE = 1;
    uint256 constant PERCENTAGE_DENOMINATOR = 100;
    uint256 constant SECONDS_PER_DAY = 86400;
    uint256 constant SECONDS_PER_MONTH = SECONDS_PER_DAY * 30;

    error InvalidPercentage();
    error InvalidAmount();
    error InvalidConfiguration();

    /**
     * @notice Validate percentage value
     */
    function validatePercentage(uint256 percentage) internal pure {
        if (percentage < MIN_PERCENTAGE || percentage > MAX_PERCENTAGE) {
            revert InvalidPercentage();
        }
    }

    /**
     * @notice Validate fixed amount
     */
    function validateFixedAmount(uint256 amount) internal pure {
        if (amount == 0) revert InvalidAmount();
    }

    /**
     * @notice Validate cap configuration
     */
    function validateCaps(uint256 dailyCap, uint256 monthlyCap) internal pure {
        if (dailyCap == 0 || monthlyCap == 0) revert InvalidConfiguration();
        if (monthlyCap < dailyCap) revert InvalidConfiguration();
    }

    /**
     * @notice Calculate save amount
     */
    function calculateSaveAmount(
        uint256 spendAmount,
        uint256 value,
        bool isPercentage
    ) internal pure returns (uint256) {
        if (isPercentage) {
            return (spendAmount * value) / PERCENTAGE_DENOMINATOR;
        }
        return value;
    }

   
}