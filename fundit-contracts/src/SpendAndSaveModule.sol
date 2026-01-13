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

    constructor(address _usdc) {
        if (_usdc == address(0)) revert ZeroAddress();
        USDC = IERC20(_usdc);
    }

    // ============ User Configuration Functions ============

    function linkVault(address vault) external nonReentrant {
        if (vault == address(0)) revert ZeroAddress();
        
        // Verify vault owner is msg.sender
        if (ISavingsVault(vault).owner() != msg.sender) {
            revert InvalidVaultOwner();
        }
        
        _userVaults[msg.sender] = vault;
        emit VaultLinked(msg.sender, vault, block.timestamp);
    }

    function unlinkVault() external nonReentrant {
        if (_userConfigs[msg.sender].enabled) {
            revert SpendAndSaveNotEnabled(); // Must disable first
        }
        
        address oldVault = _userVaults[msg.sender];
        delete _userVaults[msg.sender];
        emit VaultUnlinked(msg.sender, oldVault, block.timestamp);
    }

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

    function pauseSpendAndSave() external nonReentrant {
        if (!_userConfigs[msg.sender].enabled) revert SpendAndSaveNotEnabled();
        _userConfigs[msg.sender].enabled = false;
        emit SpendAndSavePaused(msg.sender, block.timestamp);
    }

    function resumeSpendAndSave() external nonReentrant whenNotPaused {
        SpendAndSaveConfig storage config = _userConfigs[msg.sender];
        if (config.value == 0) revert SpendAndSaveLib.InvalidConfiguration();
        if (config.enabled) revert SpendAndSaveAlreadyEnabled();
        
        config.enabled = true;
        emit SpendAndSaveResumed(msg.sender, block.timestamp);
    }

    function disableSpendAndSave() external nonReentrant {
        if (!_userConfigs[msg.sender].enabled) revert SpendAndSaveNotEnabled();
        delete _userConfigs[msg.sender];
        emit SpendAndSaveDisabled(msg.sender, block.timestamp);
    }

    // ============ Automation Functions ============

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

    function getUserConfig(address user) external view returns (SpendAndSaveConfig memory) {
        return _userConfigs[user];
    }

    function getUserVault(address user) external view returns (address) {
        return _userVaults[user];
    }

    function isSpendAndSaveEnabled(address user) external view returns (bool) {
        return _userConfigs[user].enabled;
    }

    function getRemainingDailyCap(address user) external view returns (uint256) {
        SpendAndSaveConfig memory config = _userConfigs[user];
        if (!config.enabled) return 0;
        
        if (SpendAndSaveLib.needsDailyReset(config.lastResetDay)) {
            return config.dailyCap;
        }
        
        if (config.dailySaved >= config.dailyCap) return 0;
        return config.dailyCap - config.dailySaved;
    }

    function getRemainingMonthlyCap(address user) external view returns (uint256) {
        SpendAndSaveConfig memory config = _userConfigs[user];
        if (!config.enabled) return 0;
        
        if (SpendAndSaveLib.needsMonthlyReset(config.lastResetMonth)) {
            return config.monthlyCap;
        }
        
        if (config.monthlySaved >= config.monthlyCap) return 0;
        return config.monthlyCap - config.monthlySaved;
    }

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

    function isTransactionProcessed(bytes32 txHash) external view returns (bool) {
        return _processedTransactions[txHash];
    }
}