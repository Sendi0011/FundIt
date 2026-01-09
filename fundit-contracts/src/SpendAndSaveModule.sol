// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./storage/SpendAndSaveStorage.sol";
import "./security/AutomationGuard.sol";
import "./security/EmergencyPause.sol";
import "./libraries/SpendAndSaveLib.sol";
import "./interfaces/ISavingsVault.sol";

/**
 * @title SpendAndSaveModule
 * @notice Production-ready automated savings triggered by spending patterns
 * @dev Implements comprehensive security measures and gas optimizations
 * 
 * Security Features:
 * - ReentrancyGuard on all state-changing functions
 * - Role-based access control for automation
 * - Emergency pause functionality
 * - Rate limiting to prevent spam
 * - Idempotency checks for duplicate prevention
 * - Time-locked resets for caps
 * - Balance verification before transfers
 * - No admin access to user funds
 * 
 * @custom:security-contact security@fundit.com
 */
contract SpendAndSaveModule is 
    SpendAndSaveStorage,
    ReentrancyGuard,
    AutomationGuard,
    EmergencyPause 
{
    using SafeERC20 for IERC20;
    using SpendAndSaveLib for uint256;

    // ============ Immutables ============

    IERC20 public immutable USDC;

    // ============ Events ============

    event SpendAndSaveEnabled(
        address indexed user,
        bool isPercentage,
        uint256 value,
        uint256 minSpendThreshold,
        uint256 dailyCap,
        uint256 monthlyCap,
        uint256 timestamp
    );

    event SpendAndSaveDisabled(address indexed user, uint256 timestamp);
    
    event SpendAndSavePaused(address indexed user, uint256 timestamp);
    
    event SpendAndSaveResumed(address indexed user, uint256 timestamp);

    event SpendAndSaveConfigUpdated(
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

    event VaultLinked(address indexed user, address indexed vault, uint256 timestamp);

    event VaultUnlinked(address indexed user, address indexed oldVault, uint256 timestamp);

    // ============ Errors ============

    error SpendAndSaveNotEnabled();
    error SpendAndSaveAlreadyEnabled();
    error VaultNotLinked();
    error InvalidVaultOwner();
    error BelowMinimumThreshold();
    error DailyCapReached();
    error MonthlyCapReached();
    error InsufficientBalance();
    error DuplicateTransaction();
    error RateLimitExceeded();
    error ZeroAddress();

    // ============ Constructor ============

    /**
     * @notice Initialize the Spend & Save module
     * @param _usdc Address of USDC token on Base
     */
    constructor(address _usdc) {
        if (_usdc == address(0)) revert ZeroAddress();
        USDC = IERC20(_usdc);
    }

    // ============ User Configuration Functions ============

    /**
     * @notice Link user's savings vault for deposits
     * @param vault Address of user's SavingsVault
     * @dev Validates vault ownership before linking
     */
    function linkVault(address vault) external nonReentrant {
        if (vault == address(0)) revert ZeroAddress();
        
        // Verify vault owner is msg.sender
        if (ISavingsVault(vault).owner() != msg.sender) {
            revert InvalidVaultOwner();
        }
        
        _userVaults[msg.sender] = vault;
        emit VaultLinked(msg.sender, vault, block.timestamp);
    }

    /**
     * @notice Unlink vault (must disable Spend & Save first)
     */
    function unlinkVault() external nonReentrant {
        if (_userConfigs[msg.sender].enabled) {
            revert SpendAndSaveNotEnabled(); // Must disable first
        }
        
        address oldVault = _userVaults[msg.sender];
        delete _userVaults[msg.sender];
        emit VaultUnlinked(msg.sender, oldVault, block.timestamp);
    }

    /**
     * @notice Enable Spend & Save with comprehensive validation
     * @param value Percentage (1-50) or fixed USDC amount (in USDC decimals)
     * @param isPercentage True for percentage-based, false for fixed amount
     * @param minSpendThreshold Minimum spend to trigger auto-save (in USDC decimals)
     * @param dailyCap Maximum USDC to auto-save per day (in USDC decimals)
     * @param monthlyCap Maximum USDC to auto-save per month (in USDC decimals)
     * @param destinationId 0 for flexible savings, >0 for specific position
     */
    function enableSpendAndSave(
        uint256 value,
        bool isPercentage,
        uint256 minSpendThreshold,
        uint256 dailyCap,
        uint256 monthlyCap,
        uint256 destinationId
    ) external nonReentrant whenNotPaused {
        if (_userConfigs[msg.sender].enabled) revert SpendAndSaveAlreadyEnabled();
        if (_userVaults[msg.sender] == address(0)) revert VaultNotLinked();
        
        // Validate configuration
        if (isPercentage) {
            SpendAndSaveLib.validatePercentage(value);
        } else {
            SpendAndSaveLib.validateFixedAmount(value);
        }
        
        SpendAndSaveLib.validateCaps(dailyCap, monthlyCap);

        SpendAndSaveConfig storage config = _userConfigs[msg.sender];
        config.enabled = true;
        config.isPercentage = isPercentage;
        config.value = value;
        config.minSpendThreshold = minSpendThreshold;
        config.dailyCap = dailyCap;
        config.monthlyCap = monthlyCap;
        config.destinationId = destinationId;
        config.lastResetDay = block.timestamp;
        config.lastResetMonth = block.timestamp;

        emit SpendAndSaveEnabled(
            msg.sender,
            isPercentage,
            value,
            minSpendThreshold,
            dailyCap,
            monthlyCap,
            block.timestamp
        );
    }

    /**
     * @notice Update configuration with validation
     */
    function updateSpendAndSaveConfig(
        uint256 value,
        bool isPercentage,
        uint256 minSpendThreshold,
        uint256 dailyCap,
        uint256 monthlyCap,
        uint256 destinationId
    ) external nonReentrant whenNotPaused {
        if (!_userConfigs[msg.sender].enabled) revert SpendAndSaveNotEnabled();

        // Validate new configuration
        if (isPercentage) {
            SpendAndSaveLib.validatePercentage(value);
        } else {
            SpendAndSaveLib.validateFixedAmount(value);
        }
        
        SpendAndSaveLib.validateCaps(dailyCap, monthlyCap);

        SpendAndSaveConfig storage config = _userConfigs[msg.sender];
        config.isPercentage = isPercentage;
        config.value = value;
        config.minSpendThreshold = minSpendThreshold;
        config.dailyCap = dailyCap;
        config.monthlyCap = monthlyCap;
        config.destinationId = destinationId;

        emit SpendAndSaveConfigUpdated(
            msg.sender,
            isPercentage,
            value,
            minSpendThreshold,
            dailyCap,
            monthlyCap,
            block.timestamp
        );
    }

    /**
     * @notice Pause Spend & Save (keeps config)
     */
    function pauseSpendAndSave() external nonReentrant {
        if (!_userConfigs[msg.sender].enabled) revert SpendAndSaveNotEnabled();
        _userConfigs[msg.sender].enabled = false;
        emit SpendAndSavePaused(msg.sender, block.timestamp);
    }

    /**
     * @notice Resume Spend & Save
     */
    function resumeSpendAndSave() external nonReentrant whenNotPaused {
        SpendAndSaveConfig storage config = _userConfigs[msg.sender];
        if (config.value == 0) revert SpendAndSaveLib.InvalidConfiguration();
        if (config.enabled) revert SpendAndSaveAlreadyEnabled();
        
        config.enabled = true;
        emit SpendAndSaveResumed(msg.sender, block.timestamp);
    }

    /**
     * @notice Disable completely and reset configuration
     */
    function disableSpendAndSave() external nonReentrant {
        if (!_userConfigs[msg.sender].enabled) revert SpendAndSaveNotEnabled();
        delete _userConfigs[msg.sender];
        emit SpendAndSaveDisabled(msg.sender, block.timestamp);
    }

    // ============ Automation Functions ============

    /**
     * @notice Process auto-save (called by automation service)
     * @param user User who made a spend transaction
     * @param originalSpendAmount Original USDC spend amount
     * @param txHash Hash of the original spend transaction (for idempotency)
     * 
     * @dev Security measures:
     * - Only automation service can call
     * - Idempotency check prevents duplicate processing
     * - Rate limiting prevents spam
     * - All validations happen on-chain
     * - Balance verified before transfer
     */
    function autoDepositSpendAndSave(
        address user,
        uint256 originalSpendAmount,
        bytes32 txHash
    ) external nonReentrant onlyAutomation whenNotPaused {
        // Idempotency check
        if (_processedTransactions[txHash]) {
            revert DuplicateTransaction();
        }
        _processedTransactions[txHash] = true;

        // Rate limiting
        if (block.timestamp < _lastAutoSaveTime[user] + RATE_LIMIT_COOLDOWN) {
            emit AutoSaveSkipped(user, originalSpendAmount, "Rate limit", block.timestamp);
            return;
        }

        SpendAndSaveConfig storage config = _userConfigs[user];

        // Check if enabled
        if (!config.enabled) {
            emit AutoSaveSkipped(user, originalSpendAmount, "Not enabled", block.timestamp);
            return;
        }

        // Check minimum threshold
        if (originalSpendAmount < config.minSpendThreshold) {
            emit AutoSaveSkipped(user, originalSpendAmount, "Below threshold", block.timestamp);
            return;
        }

        // Reset counters if needed
        _resetCountersIfNeeded(config);

        // Calculate save amount
        uint256 saveAmount = SpendAndSaveLib.calculateSaveAmount(
            originalSpendAmount,
            config.value,
            config.isPercentage
        );

        // Check daily cap
        if (config.dailySaved + saveAmount > config.dailyCap) {
            emit AutoSaveSkipped(user, originalSpendAmount, "Daily cap", block.timestamp);
            return;
        }

        // Check monthly cap
        if (config.monthlySaved + saveAmount > config.monthlyCap) {
            emit AutoSaveSkipped(user, originalSpendAmount, "Monthly cap", block.timestamp);
            return;
        }

        // Check user balance
        uint256 userBalance = USDC.balanceOf(user);
        if (userBalance < saveAmount) {
            emit AutoSaveSkipped(user, originalSpendAmount, "Insufficient balance", block.timestamp);
            return;
        }

        // Check allowance
        uint256 allowance = USDC.allowance(user, address(this));
        if (allowance < saveAmount) {
            emit AutoSaveSkipped(user, originalSpendAmount, "Insufficient allowance", block.timestamp);
            return;
        }

        // Execute transfer to vault
        address vault = _userVaults[user];
        USDC.safeTransferFrom(user, vault, saveAmount);

        // Update state
        config.dailySaved += saveAmount;
        config.monthlySaved += saveAmount;
        config.totalAutoSaved += saveAmount;
        config.transactionCount += 1;
        _lastAutoSaveTime[user] = block.timestamp;

        emit AutoSaveTriggered(
            user,
            originalSpendAmount,
            saveAmount,
            block.timestamp,
            config.totalAutoSaved,
            txHash
        );
    }

    // ============ Internal Functions ============

    /**
     * @notice Reset daily/monthly counters based on time
     * @dev Uses time-based logic instead of block numbers for accuracy
     */
    function _resetCountersIfNeeded(SpendAndSaveConfig storage config) internal {
        if (SpendAndSaveLib.needsDailyReset(config.lastResetDay)) {
            config.dailySaved = 0;
            config.lastResetDay = block.timestamp;
        }

        if (SpendAndSaveLib.needsMonthlyReset(config.lastResetMonth)) {
            config.monthlySaved = 0;
            config.lastResetMonth = block.timestamp;
        }
    }

    // ============ View Functions ============

    /**
     * @notice Get user's complete configuration
     */
    function getUserConfig(address user) external view returns (SpendAndSaveConfig memory) {
        return _userConfigs[user];
    }

    /**
     * @notice Get user's linked vault
     */
    function getUserVault(address user) external view returns (address) {
        return _userVaults[user];
    }

    /**
     * @notice Check if Spend & Save is enabled
     */
    function isSpendAndSaveEnabled(address user) external view returns (bool) {
        return _userConfigs[user].enabled;
    }

    /**
     * @notice Get remaining daily cap (accounts for time-based reset)
     */
    function getRemainingDailyCap(address user) external view returns (uint256) {
        SpendAndSaveConfig memory config = _userConfigs[user];
        if (!config.enabled) return 0;
        
        if (SpendAndSaveLib.needsDailyReset(config.lastResetDay)) {
            return config.dailyCap;
        }
        
        if (config.dailySaved >= config.dailyCap) return 0;
        return config.dailyCap - config.dailySaved;
    }

    /**
     * @notice Get remaining monthly cap (accounts for time-based reset)
     */
    function getRemainingMonthlyCap(address user) external view returns (uint256) {
        SpendAndSaveConfig memory config = _userConfigs[user];
        if (!config.enabled) return 0;
        
        if (SpendAndSaveLib.needsMonthlyReset(config.lastResetMonth)) {
            return config.monthlyCap;
        }
        
        if (config.monthlySaved >= config.monthlyCap) return 0;
        return config.monthlyCap - config.monthlySaved;
    }

    /**
     * @notice Calculate save amount for a hypothetical spend
     * @return saveAmount The amount that would be saved
     * @return willExecute Whether the auto-save would execute
     * @return reason Human-readable reason if it won't execute
     */
    function calculateSaveAmount(address user, uint256 spendAmount) 
        external 
        view 
        returns (uint256 saveAmount, bool willExecute, string memory reason) 
    {
        SpendAndSaveConfig memory config = _userConfigs[user];

        if (!config.enabled) {
            return (0, false, "Not enabled");
        }

        if (spendAmount < config.minSpendThreshold) {
            return (0, false, "Below threshold");
        }

        // Calculate save amount
        saveAmount = SpendAndSaveLib.calculateSaveAmount(
            spendAmount,
            config.value,
            config.isPercentage
        );

        // Check caps with time-based resets
        uint256 dailyRemaining = SpendAndSaveLib.needsDailyReset(config.lastResetDay)
            ? config.dailyCap
            : (config.dailyCap > config.dailySaved ? config.dailyCap - config.dailySaved : 0);

        uint256 monthlyRemaining = SpendAndSaveLib.needsMonthlyReset(config.lastResetMonth)
            ? config.monthlyCap
            : (config.monthlyCap > config.monthlySaved ? config.monthlyCap - config.monthlySaved : 0);

        if (saveAmount > dailyRemaining) {
            return (saveAmount, false, "Would exceed daily cap");
        }

        if (saveAmount > monthlyRemaining) {
            return (saveAmount, false, "Would exceed monthly cap");
        }

        uint256 userBalance = USDC.balanceOf(user);
        if (userBalance < saveAmount) {
            return (saveAmount, false, "Insufficient balance");
        }

        uint256 allowance = USDC.allowance(user, address(this));
        if (allowance < saveAmount) {
            return (saveAmount, false, "Insufficient allowance");
        }

        return (saveAmount, true, "Will execute");
    }

    /**
     * @notice Get lifetime statistics
     */
    function getUserStats(address user) 
        external 
        view 
        returns (
            uint256 totalAutoSaved,
            uint256 transactionCount,
            uint256 dailySaved,
            uint256 monthlySaved,
            uint256 lastAutoSave
        ) 
    {
        SpendAndSaveConfig memory config = _userConfigs[user];
        return (
            config.totalAutoSaved,
            config.transactionCount,
            config.dailySaved,
            config.monthlySaved,
            _lastAutoSaveTime[user]
        );
    }

    /**
     * @notice Check if transaction has been processed
     */
    function isTransactionProcessed(bytes32 txHash) external view returns (bool) {
        return _processedTransactions[txHash];
    }
}