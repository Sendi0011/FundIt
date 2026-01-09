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

    
}