// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/SpendAndSaveModule.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title MockUSDC
 * @notice Mock USDC token for testing
 */
contract MockUSDC is ERC20 {
    constructor() ERC20("USD Coin", "USDC") {
        _mint(msg.sender, 1_000_000 * 10**6); // 1M USDC
    }

    function decimals() public pure override returns (uint8) {
        return 6;
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

/**
 * @title MockSavingsVault
 * @notice Mock vault for testing
 */
contract MockSavingsVault {
    address public owner;
    
    constructor(address _owner) {
        owner = _owner;
    }

    function depositFlexible(uint256) external pure {}
    function depositTarget(uint256, uint256) external pure {}
}

/**
 * @title SpendAndSaveModuleTest
 * @notice Comprehensive test suite for SpendAndSaveModule
 */
contract SpendAndSaveModuleTest is Test {
    SpendAndSaveModule public spendAndSave;
    MockUSDC public usdc;
    MockSavingsVault public vault;
    
    address public owner;
    address public user1;
    address public user2;
    address public automationService;
    
    // Test constants
    uint256 constant INITIAL_BALANCE = 10_000 * 10**6; // 10,000 USDC
    uint256 constant MIN_THRESHOLD = 10 * 10**6; // 10 USDC
    uint256 constant DAILY_CAP = 50 * 10**6; // 50 USDC
    uint256 constant MONTHLY_CAP = 500 * 10**6; // 500 USDC

    event SpendAndSaveEnabled(
        address indexed user,
        bool isPercentage,
        uint256 value,
        uint256 minSpendThreshold,
        uint256 dailyCap,
        uint256 monthlyCap,
        uint256 timestamp
    );

    event AutoSaveTriggered(
        address indexed user,
        uint256 originalSpendAmount,
        uint256 savedAmount,
        uint256 timestamp,
        uint256 newTotalSaved,
        bytes32 transactionHash
    );

    event AutoSaveSkipped(
        address indexed user,
        uint256 originalSpendAmount,
        string reason,
        uint256 timestamp
    );

    function setUp() public {
        owner = address(this);
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        automationService = makeAddr("automationService");

        // Deploy contracts
        usdc = new MockUSDC();
        spendAndSave = new SpendAndSaveModule(address(usdc));
        
        // Setup automation service
        spendAndSave.grantAutomationRole(automationService);
        
        // Fund users
        usdc.mint(user1, INITIAL_BALANCE);
        usdc.mint(user2, INITIAL_BALANCE);
        
        // Create vaults for users
        vault = new MockSavingsVault(user1);
    }

    // ============ Configuration Tests ============

    function test_EnableSpendAndSave_Success() public {
        vm.startPrank(user1);
        
        // Link vault
        spendAndSave.linkVault(address(vault));
        
        // Approve USDC
        usdc.approve(address(spendAndSave), type(uint256).max);
        
        // Enable Spend & Save
        vm.expectEmit(true, true, true, true);
        emit SpendAndSaveEnabled(user1, true, 10, MIN_THRESHOLD, DAILY_CAP, MONTHLY_CAP, block.timestamp);
        
        spendAndSave.enableSpendAndSave(
            10,           // 10%
            true,         // isPercentage
            MIN_THRESHOLD,
            DAILY_CAP,
            MONTHLY_CAP,
            0             // flexible savings
        );
        
        // Verify configuration
        ISpendAndSaveModule.SpendAndSaveConfig memory config = spendAndSave.getUserConfig(user1);
        assertTrue(config.enabled);
        assertTrue(config.isPercentage);
        assertEq(config.value, 10);
        assertEq(config.minSpendThreshold, MIN_THRESHOLD);
        assertEq(config.dailyCap, DAILY_CAP);
        assertEq(config.monthlyCap, MONTHLY_CAP);
        
        vm.stopPrank();
    }

    function test_EnableSpendAndSave_RevertWhenAlreadyEnabled() public {
        vm.startPrank(user1);
        
        spendAndSave.linkVault(address(vault));
        usdc.approve(address(spendAndSave), type(uint256).max);
        
        spendAndSave.enableSpendAndSave(10, true, MIN_THRESHOLD, DAILY_CAP, MONTHLY_CAP, 0);
        
        // Try to enable again
        vm.expectRevert(SpendAndSaveModule.SpendAndSaveAlreadyEnabled.selector);
        spendAndSave.enableSpendAndSave(10, true, MIN_THRESHOLD, DAILY_CAP, MONTHLY_CAP, 0);
        
        vm.stopPrank();
    }

    function test_EnableSpendAndSave_RevertWithoutVault() public {
        vm.startPrank(user1);
        
        vm.expectRevert(SpendAndSaveModule.VaultNotLinked.selector);
        spendAndSave.enableSpendAndSave(10, true, MIN_THRESHOLD, DAILY_CAP, MONTHLY_CAP, 0);
        
        vm.stopPrank();
    }

    function test_EnableSpendAndSave_RevertWithInvalidPercentage() public {
        vm.startPrank(user1);
        spendAndSave.linkVault(address(vault));
        
        // Test 0%
        vm.expectRevert(SpendAndSaveLib.InvalidPercentage.selector);
        spendAndSave.enableSpendAndSave(0, true, MIN_THRESHOLD, DAILY_CAP, MONTHLY_CAP, 0);
        
        // Test 51%
        vm.expectRevert(SpendAndSaveLib.InvalidPercentage.selector);
        spendAndSave.enableSpendAndSave(51, true, MIN_THRESHOLD, DAILY_CAP, MONTHLY_CAP, 0);
        
        vm.stopPrank();
    }

    function test_EnableSpendAndSave_RevertWithInvalidCaps() public {
        vm.startPrank(user1);
        spendAndSave.linkVault(address(vault));
        
        // Monthly cap less than daily cap
        vm.expectRevert(SpendAndSaveLib.InvalidConfiguration.selector);
        spendAndSave.enableSpendAndSave(10, true, MIN_THRESHOLD, 100 * 10**6, 50 * 10**6, 0);
        
        vm.stopPrank();
    }

    function test_UpdateSpendAndSaveConfig_Success() public {
        _setupUser1WithSpendAndSave();
        
        vm.prank(user1);
        spendAndSave.updateSpendAndSaveConfig(
            20,           // 20%
            true,
            MIN_THRESHOLD * 2,
            DAILY_CAP * 2,
            MONTHLY_CAP * 2,
            0
        );
        
        ISpendAndSaveModule.SpendAndSaveConfig memory config = spendAndSave.getUserConfig(user1);
        assertEq(config.value, 20);
        assertEq(config.minSpendThreshold, MIN_THRESHOLD * 2);
    }

    function test_PauseAndResume_Success() public {
        _setupUser1WithSpendAndSave();
        
        vm.startPrank(user1);
        
        // Pause
        spendAndSave.pauseSpendAndSave();
        assertFalse(spendAndSave.isSpendAndSaveEnabled(user1));
        
        // Resume
        spendAndSave.resumeSpendAndSave();
        assertTrue(spendAndSave.isSpendAndSaveEnabled(user1));
        
        vm.stopPrank();
    }

    function test_DisableSpendAndSave_Success() public {
        _setupUser1WithSpendAndSave();
        
        vm.prank(user1);
        spendAndSave.disableSpendAndSave();
        
        assertFalse(spendAndSave.isSpendAndSaveEnabled(user1));
        
        ISpendAndSaveModule.SpendAndSaveConfig memory config = spendAndSave.getUserConfig(user1);
        assertEq(config.value, 0);
    }

    // ============ Vault Management Tests ============

    function test_LinkVault_Success() public {
        vm.prank(user1);
        spendAndSave.linkVault(address(vault));
        
        assertEq(spendAndSave.getUserVault(user1), address(vault));
    }

    function test_LinkVault_RevertWithWrongOwner() public {
        MockSavingsVault wrongVault = new MockSavingsVault(user2);
        
        vm.prank(user1);
        vm.expectRevert(SpendAndSaveModule.InvalidVaultOwner.selector);
        spendAndSave.linkVault(address(wrongVault));
    }

    function test_LinkVault_RevertWithZeroAddress() public {
        vm.prank(user1);
        vm.expectRevert(SpendAndSaveModule.ZeroAddress.selector);
        spendAndSave.linkVault(address(0));
    }

    function test_UnlinkVault_Success() public {
        vm.startPrank(user1);
        
        spendAndSave.linkVault(address(vault));
        spendAndSave.unlinkVault();
        
        assertEq(spendAndSave.getUserVault(user1), address(0));
        
        vm.stopPrank();
    }

    // ============ Auto-Save Execution Tests ============

    function test_AutoDepositSpendAndSave_PercentageBased_Success() public {
        _setupUser1WithSpendAndSave();
        
        uint256 spendAmount = 100 * 10**6; // 100 USDC
        uint256 expectedSave = 10 * 10**6; // 10% = 10 USDC
        bytes32 txHash = keccak256("tx1");
        
        uint256 vaultBalanceBefore = usdc.balanceOf(address(vault));
        
        vm.expectEmit(true, true, true, true);
        emit AutoSaveTriggered(user1, spendAmount, expectedSave, block.timestamp, expectedSave, txHash);
        
        vm.prank(automationService);
        spendAndSave.autoDepositSpendAndSave(user1, spendAmount, txHash);
        
        uint256 vaultBalanceAfter = usdc.balanceOf(address(vault));
        assertEq(vaultBalanceAfter - vaultBalanceBefore, expectedSave);
        
        // Verify stats
        (uint256 totalAutoSaved, uint256 transactionCount,,,) = spendAndSave.getUserStats(user1);
        assertEq(totalAutoSaved, expectedSave);
        assertEq(transactionCount, 1);
    }

    function test_AutoDepositSpendAndSave_FixedAmount_Success() public {
        vm.startPrank(user1);
        
        spendAndSave.linkVault(address(vault));
        usdc.approve(address(spendAndSave), type(uint256).max);
        
        // Enable with fixed amount (5 USDC per transaction)
        spendAndSave.enableSpendAndSave(
            5 * 10**6,    // 5 USDC fixed
            false,        // NOT percentage
            MIN_THRESHOLD,
            DAILY_CAP,
            MONTHLY_CAP,
            0
        );
        
        vm.stopPrank();
        
        uint256 spendAmount = 100 * 10**6; // 100 USDC
        uint256 expectedSave = 5 * 10**6; // 5 USDC fixed
        bytes32 txHash = keccak256("tx2");
        
        vm.prank(automationService);
        spendAndSave.autoDepositSpendAndSave(user1, spendAmount, txHash);
        
        (uint256 totalAutoSaved,,,) = spendAndSave.getUserStats(user1);
        assertEq(totalAutoSaved, expectedSave);
    }

    function test_AutoDepositSpendAndSave_SkipWhenBelowThreshold() public {
        _setupUser1WithSpendAndSave();
        
        uint256 spendAmount = 5 * 10**6; // 5 USDC (below 10 USDC threshold)
        bytes32 txHash = keccak256("tx3");
        
        vm.expectEmit(true, true, true, true);
        emit AutoSaveSkipped(user1, spendAmount, "Below threshold", block.timestamp);
        
        vm.prank(automationService);
        spendAndSave.autoDepositSpendAndSave(user1, spendAmount, txHash);
        
        (uint256 totalAutoSaved,,,) = spendAndSave.getUserStats(user1);
        assertEq(totalAutoSaved, 0);
    }

    function test_AutoDepositSpendAndSave_SkipWhenNotEnabled() public {
        vm.startPrank(user1);
        spendAndSave.linkVault(address(vault));
        usdc.approve(address(spendAndSave), type(uint256).max);
        vm.stopPrank();
        
        uint256 spendAmount = 100 * 10**6;
        bytes32 txHash = keccak256("tx4");
        
        vm.expectEmit(true, true, true, true);
        emit AutoSaveSkipped(user1, spendAmount, "Not enabled", block.timestamp);
        
        vm.prank(automationService);
        spendAndSave.autoDepositSpendAndSave(user1, spendAmount, txHash);
    }

    function test_AutoDepositSpendAndSave_SkipWhenInsufficientBalance() public {
        _setupUser1WithSpendAndSave();
        
        // Transfer away most of user's balance
        vm.prank(user1);
        usdc.transfer(user2, INITIAL_BALANCE - 1 * 10**6);
        
        uint256 spendAmount = 100 * 10**6;
        bytes32 txHash = keccak256("tx5");
        
        vm.expectEmit(true, true, true, true);
        emit AutoSaveSkipped(user1, spendAmount, "Insufficient balance", block.timestamp);
        
        vm.prank(automationService);
        spendAndSave.autoDepositSpendAndSave(user1, spendAmount, txHash);
    }

    function test_AutoDepositSpendAndSave_RevertOnDuplicateTransaction() public {
        _setupUser1WithSpendAndSave();
        
        uint256 spendAmount = 100 * 10**6;
        bytes32 txHash = keccak256("tx6");
        
        // First call succeeds
        vm.prank(automationService);
        spendAndSave.autoDepositSpendAndSave(user1, spendAmount, txHash);
        
        // Second call with same txHash reverts
        vm.prank(automationService);
        vm.expectRevert(SpendAndSaveModule.DuplicateTransaction.selector);
        spendAndSave.autoDepositSpendAndSave(user1, spendAmount, txHash);
    }

    function test_AutoDepositSpendAndSave_RevertWhenUnauthorized() public {
        _setupUser1WithSpendAndSave();
        
        uint256 spendAmount = 100 * 10**6;
        bytes32 txHash = keccak256("tx7");
        
        // Non-automation service tries to call
        vm.prank(user2);
        vm.expectRevert(AutomationGuard.UnauthorizedAutomation.selector);
        spendAndSave.autoDepositSpendAndSave(user1, spendAmount, txHash);
    }

    // ============ Cap Enforcement Tests ============

    function test_DailyCap_EnforcedCorrectly() public {
        _setupUser1WithSpendAndSave();
        
        // Make multiple auto-saves up to daily cap (50 USDC)
        // 10% of 100 = 10 USDC per save
        // 5 transactions = 50 USDC (hits cap)
        
        for (uint i = 0; i < 5; i++) {
            bytes32 txHash = keccak256(abi.encodePacked("tx", i));
            vm.prank(automationService);
            spendAndSave.autoDepositSpendAndSave(user1, 100 * 10**6, txHash);
            vm.warp(block.timestamp + 61); // Skip rate limit
        }
        
        (,, uint256 dailySaved,) = spendAndSave.getUserStats(user1);
        assertEq(dailySaved, DAILY_CAP);
        
        // Next transaction should be skipped
        bytes32 txHash = keccak256("tx_over_cap");
        vm.expectEmit(true, true, true, true);
        emit AutoSaveSkipped(user1, 100 * 10**6, "Daily cap", block.timestamp);
        
        vm.prank(automationService);
        spendAndSave.autoDepositSpendAndSave(user1, 100 * 10**6, txHash);
    }

    function test_DailyCap_ResetsAfter24Hours() public {
        _setupUser1WithSpendAndSave();
        
        // Hit daily cap
        for (uint i = 0; i < 5; i++) {
            bytes32 txHash = keccak256(abi.encodePacked("tx", i));
            vm.prank(automationService);
            spendAndSave.autoDepositSpendAndSave(user1, 100 * 10**6, txHash);
            vm.warp(block.timestamp + 61);
        }
        
        // Fast forward 24 hours
        vm.warp(block.timestamp + 86400);
        
        // Should work again
        bytes32 txHash = keccak256("tx_after_reset");
        vm.prank(automationService);
        spendAndSave.autoDepositSpendAndSave(user1, 100 * 10**6, txHash);
        
        uint256 remaining = spendAndSave.getRemainingDailyCap(user1);
        assertEq(remaining, DAILY_CAP - 10 * 10**6);
    }

    function test_MonthlyCap_EnforcedCorrectly() public {
        _setupUser1WithSpendAndSave();
        
        // Make 50 auto-saves = 500 USDC (monthly cap)
        for (uint i = 0; i < 50; i++) {
            bytes32 txHash = keccak256(abi.encodePacked("tx", i));
            
            // Reset daily cap every 5 transactions
            if (i % 5 == 0 && i > 0) {
                vm.warp(block.timestamp + 86400);
            }
            
            vm.prank(automationService);
            spendAndSave.autoDepositSpendAndSave(user1, 100 * 10**6, txHash);
            vm.warp(block.timestamp + 61);
        }
        
        (,,, uint256 monthlySaved) = spendAndSave.getUserStats(user1);
        assertEq(monthlySaved, MONTHLY_CAP);
        
        // Next should be skipped
        vm.warp(block.timestamp + 86400); // Reset daily
        bytes32 txHash = keccak256("tx_monthly_over");
        
        vm.expectEmit(true, true, true, true);
        emit AutoSaveSkipped(user1, 100 * 10**6, "Monthly cap", block.timestamp);
        
        vm.prank(automationService);
        spendAndSave.autoDepositSpendAndSave(user1, 100 * 10**6, txHash);
    }

    // ============ Rate Limiting Tests ============

    function test_RateLimit_PreventsTooFrequentCalls() public {
        _setupUser1WithSpendAndSave();
        
        uint256 spendAmount = 100 * 10**6;
        
        // First call succeeds
        bytes32 txHash1 = keccak256("tx1");
        vm.prank(automationService);
        spendAndSave.autoDepositSpendAndSave(user1, spendAmount, txHash1);
        
        // Second call within 60 seconds is skipped
        bytes32 txHash2 = keccak256("tx2");
        vm.warp(block.timestamp + 30); // Only 30 seconds
        
        vm.expectEmit(true, true, true, true);
        emit AutoSaveSkipped(user1, spendAmount, "Rate limit", block.timestamp);
        
        vm.prank(automationService);
        spendAndSave.autoDepositSpendAndSave(user1, spendAmount, txHash2);
        
        // Third call after 60 seconds succeeds
        bytes32 txHash3 = keccak256("tx3");
        vm.warp(block.timestamp + 31); // Total 61 seconds
        
        vm.expectEmit(true, true, true, true);
        emit AutoSaveTriggered(user1, spendAmount, 10 * 10**6, block.timestamp, 20 * 10**6, txHash3);
        
        vm.prank(automationService);
        spendAndSave.autoDepositSpendAndSave(user1, spendAmount, txHash3);
    }

    // ============ View Function Tests ============

    function test_CalculateSaveAmount_Percentage() public {
        _setupUser1WithSpendAndSave();
        
        (uint256 saveAmount, bool willExecute, string memory reason) = 
            spendAndSave.calculateSaveAmount(user1, 100 * 10**6);
        
        assertEq(saveAmount, 10 * 10**6);
        assertTrue(willExecute);
        assertEq(reason, "Will execute");
    }

    function test_CalculateSaveAmount_BelowThreshold() public {
        _setupUser1WithSpendAndSave();
        
        (uint256 saveAmount, bool willExecute, string memory reason) = 
            spendAndSave.calculateSaveAmount(user1, 5 * 10**6);
        
        assertEq(saveAmount, 0);
        assertFalse(willExecute);
        assertEq(reason, "Below threshold");
    }

    function test_GetRemainingDailyCap() public {
        _setupUser1WithSpendAndSave();
        
        uint256 remaining = spendAndSave.getRemainingDailyCap(user1);
        assertEq(remaining, DAILY_CAP);
        
        // Make one auto-save
        bytes32 txHash = keccak256("tx1");
        vm.prank(automationService);
        spendAndSave.autoDepositSpendAndSave(user1, 100 * 10**6, txHash);
        
        remaining = spendAndSave.getRemainingDailyCap(user1);
        assertEq(remaining, DAILY_CAP - 10 * 10**6);
    }

    // ============ Emergency Pause Tests ============

    function test_EmergencyPause_BlocksNewConfigurations() public {
        spendAndSave.emergencyPause();
        
        vm.startPrank(user1);
        spendAndSave.linkVault(address(vault));
        
        vm.expectRevert("Pausable: paused");
        spendAndSave.enableSpendAndSave(10, true, MIN_THRESHOLD, DAILY_CAP, MONTHLY_CAP, 0);
        
        vm.stopPrank();
    }

    function test_EmergencyPause_BlocksAutoSaves() public {
        _setupUser1WithSpendAndSave();
        
        spendAndSave.emergencyPause();
        
        bytes32 txHash = keccak256("tx1");
        vm.prank(automationService);
        vm.expectRevert("Pausable: paused");
        spendAndSave.autoDepositSpendAndSave(user1, 100 * 10**6, txHash);
    }

    function test_EmergencyUnpause_RestoresOperations() public {
        _setupUser1WithSpendAndSave();
        
        spendAndSave.emergencyPause();
        spendAndSave.emergencyUnpause();
        
        bytes32 txHash = keccak256("tx1");
        vm.prank(automationService);
        spendAndSave.autoDepositSpendAndSave(user1, 100 * 10**6, txHash);
        
        (uint256 totalAutoSaved,,,) = spendAndSave.getUserStats(user1);
        assertEq(totalAutoSaved, 10 * 10**6);
    }

    // ============ Access Control Tests ============

    function test_GrantAutomationRole_OnlyOwner() public {
        address newService = makeAddr("newService");
        
        spendAndSave.grantAutomationRole(newService);
        
        assertTrue(spendAndSave.hasRole(spendAndSave.AUTOMATION_ROLE(), newService));
    }

    function test_GrantAutomationRole_RevertWhenNotOwner() public {
        address newService = makeAddr("newService");
        
        vm.prank(user1);
        vm.expectRevert();
        spendAndSave.grantAutomationRole(newService);
    }

    function test_RevokeAutomationRole_Success() public {
        spendAndSave.revokeAutomationRole(automationService);
        
        assertFalse(spendAndSave.hasRole(spendAndSave.AUTOMATION_ROLE(), automationService));
    }

    // ============ Fuzz Tests ============

    function testFuzz_EnableSpendAndSave_ValidPercentages(uint8 percentage) public {
        vm.assume(percentage >= 1 && percentage <= 50);
        
        vm.startPrank(user1);
        spendAndSave.linkVault(address(vault));
        usdc.approve(address(spendAndSave), type(uint256).max);
        
        spendAndSave.enableSpendAndSave(
            percentage,
            true,
            MIN_THRESHOLD,
            DAILY_CAP,
            MONTHLY_CAP,
            0
        );
        
        ISpendAndSaveModule.SpendAndSaveConfig memory config = spendAndSave.getUserConfig(user1);
        assertEq(config.value, percentage);
        
        vm.stopPrank();
    }

    function testFuzz_AutoSave_VariousSpendAmounts(uint96 spendAmount) public {
        vm.assume(spendAmount >= MIN_THRESHOLD && spendAmount <= 1000 * 10**6);
        
        _setupUser1WithSpendAndSave();
        
        bytes32 txHash = keccak256(abi.encodePacked(spendAmount));
        
        vm.prank(automationService);
        spendAndSave.autoDepositSpendAndSave(user1, spendAmount, txHash);
        
        uint256 expectedSave = (spendAmount * 10) / 100;
        
        (uint256 totalAutoSaved,,,) = spendAndSave.getUserStats(user1);
        assertEq(totalAutoSaved, expectedSave);
    }

    
}