// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../../src/storage/SpendAndSaveStorage.sol";

// Mock contract to expose internal storage of SpendAndSaveStorage for testing
contract MockSpendAndSaveStorage is SpendAndSaveStorage {
    // Expose internal _userConfigs mapping
    function getUserConfig(address user) public view returns (SpendAndSaveConfig memory) {
        return _userConfigs[user];
    }

    // Set _userConfigs mapping
    function setUserConfig(address user, SpendAndSaveConfig memory config) public {
        _userConfigs[user] = config;
    }

    // Expose internal _userVaults mapping
    function getUserVault(address user) public view returns (address) {
        return _userVaults[user];
    }

    // Set _userVaults mapping
    function setUserVault(address user, address vault) public {
        _userVaults[user] = vault;
    }

    // Expose internal _processedTransactions mapping
    function getProcessedTransaction(bytes32 txHash) public view returns (bool) {
        return _processedTransactions[txHash];
    }

    // Set _processedTransactions mapping
    function setProcessedTransaction(bytes32 txHash, bool status) public {
        _processedTransactions[txHash] = status;
    }

    // Expose internal _lastAutoSaveTime mapping
    function getLastAutoSaveTime(address user) public view returns (uint256) {
        return _lastAutoSaveTime[user];
    }

    // Set _lastAutoSaveTime mapping
    function setLastAutoSaveTime(address user, uint256 timestamp) public {
        _lastAutoSaveTime[user] = timestamp;
    }

    // Expose internal RATE_LIMIT_COOLDOWN constant
    function getRateLimitCooldown() public pure returns (uint256) {
        return RATE_LIMIT_COOLDOWN;
    }
}

contract SpendAndSaveStorageTest is Test {
    MockSpendAndSaveStorage public mockStorage;

    address public user1;
    address public user2;
    address public vault1;
    address public vault2;

    function setUp() public {
        mockStorage = new MockSpendAndSaveStorage();
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        vault1 = makeAddr("vault1");
        vault2 = makeAddr("vault2");
    }

    function test_InitialSpendAndSaveConfig_IsEmpty() public {
        SpendAndSaveStorage.SpendAndSaveConfig memory config = mockStorage.getUserConfig(user1);

        assertFalse(config.enabled);
        assertFalse(config.isPercentage);
        assertEq(config.value, 0);
        assertEq(config.minSpendThreshold, 0);
        assertEq(config.dailyCap, 0);
        assertEq(config.monthlyCap, 0);
        assertEq(config.dailySaved, 0);
        assertEq(config.monthlySaved, 0);
        assertEq(config.lastResetDay, 0);
        assertEq(config.lastResetMonth, 0);
        assertEq(config.destinationId, 0);
        assertEq(config.totalAutoSaved, 0);
        assertEq(config.transactionCount, 0);
    }

    function test_SetAndGetSpendAndSaveConfig() public {
        SpendAndSaveStorage.SpendAndSaveConfig memory newConfig;
        newConfig.enabled = true;
        newConfig.isPercentage = true;
        newConfig.value = 10;
        newConfig.minSpendThreshold = 100;
        newConfig.dailyCap = 1000;
        newConfig.monthlyCap = 5000;
        newConfig.dailySaved = 50;
        newConfig.monthlySaved = 200;
        newConfig.lastResetDay = 1;
        newConfig.lastResetMonth = 1;
        newConfig.destinationId = 123;
        newConfig.totalAutoSaved = 200;
        newConfig.transactionCount = 5;

        mockStorage.setUserConfig(user1, newConfig);

        SpendAndSaveStorage.SpendAndSaveConfig memory retrievedConfig = mockStorage.getUserConfig(user1);

        assertTrue(retrievedConfig.enabled);
        assertTrue(retrievedConfig.isPercentage);
        assertEq(retrievedConfig.value, 10);
        assertEq(retrievedConfig.minSpendThreshold, 100);
        assertEq(retrievedConfig.dailyCap, 1000);
        assertEq(retrievedConfig.monthlyCap, 5000);
        assertEq(retrievedConfig.dailySaved, 50);
        assertEq(retrievedConfig.monthlySaved, 200);
        assertEq(retrievedConfig.lastResetDay, 1);
        assertEq(retrievedConfig.lastResetMonth, 1);
        assertEq(retrievedConfig.destinationId, 123);
        assertEq(retrievedConfig.totalAutoSaved, 200);
        assertEq(retrievedConfig.transactionCount, 5);
    }

    function test_SetAndGetSpendAndSaveConfig_MultipleUsers() public {
        SpendAndSaveStorage.SpendAndSaveConfig memory config1;
        config1.enabled = true;
        config1.value = 5;

        SpendAndSaveStorage.SpendAndSaveConfig memory config2;
        config2.enabled = false;
        config2.value = 20;

        mockStorage.setUserConfig(user1, config1);
        mockStorage.setUserConfig(user2, config2);

        SpendAndSaveStorage.SpendAndSaveConfig memory retrievedConfig1 = mockStorage.getUserConfig(user1);
        SpendAndSaveStorage.SpendAndSaveConfig memory retrievedConfig2 = mockStorage.getUserConfig(user2);

        assertTrue(retrievedConfig1.enabled);
        assertEq(retrievedConfig1.value, 5);

        assertFalse(retrievedConfig2.enabled);
        assertEq(retrievedConfig2.value, 20);
    }

    function test_InitialUserVault_IsEmpty() public {
        address retrievedVault = mockStorage.getUserVault(user1);
        assertEq(retrievedVault, address(0));
    }

    function test_SetAndGetUserVault() public {
        mockStorage.setUserVault(user1, vault1);
        address retrievedVault = mockStorage.getUserVault(user1);
        assertEq(retrievedVault, vault1);

        mockStorage.setUserVault(user2, vault2);
        address retrievedVault2 = mockStorage.getUserVault(user2);
        assertEq(retrievedVault2, vault2);
    }

    function test_InitialProcessedTransaction_IsFalse() public {
        bytes32 txHash = keccak256("test_tx_1");
        assertFalse(mockStorage.getProcessedTransaction(txHash));
    }

    function test_SetAndGetProcessedTransaction() public {
        bytes32 txHash1 = keccak256("test_tx_1");
        bytes32 txHash2 = keccak256("test_tx_2");

        mockStorage.setProcessedTransaction(txHash1, true);
        assertTrue(mockStorage.getProcessedTransaction(txHash1));
        assertFalse(mockStorage.getProcessedTransaction(txHash2)); 

        mockStorage.setProcessedTransaction(txHash2, true);
        assertTrue(mockStorage.getProcessedTransaction(txHash2));
    }

    function test_InitialLastAutoSaveTime_IsZero() public {
        uint256 lastSaveTime = mockStorage.getLastAutoSaveTime(user1);
        assertEq(lastSaveTime, 0);
    }

    function test_SetAndGetLastAutoSaveTime() public {
        uint256 timestamp1 = 12345;
        uint256 timestamp2 = 67890;

        mockStorage.setLastAutoSaveTime(user1, timestamp1);
        assertEq(mockStorage.getLastAutoSaveTime(user1), timestamp1);

        mockStorage.setLastAutoSaveTime(user2, timestamp2);
        assertEq(mockStorage.getLastAutoSaveTime(user2), timestamp2);
    }

    function test_RateLimitCooldown_Value() public {
        assertEq(mockStorage.getRateLimitCooldown(), 60);
    }
}