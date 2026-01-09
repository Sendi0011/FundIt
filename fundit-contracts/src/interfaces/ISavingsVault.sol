// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ISavingsVault
 * @notice Interface for SavingsVault contract
 */
interface ISavingsVault {
    function depositFlexible(uint256 amount) external;
    function depositTarget(uint256 amount, uint256 targetAmount) external;
    function owner() external view returns (address);
}
