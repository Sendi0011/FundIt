// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title StakingContract
 * @notice A contract for staking an ERC20 token to earn rewards in another ERC20 token.
 */
contract StakingContract is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Math for uint256;

    // ============ State Variables ============

    IERC20 public immutable stakingToken;
    IERC20 public immutable rewardsToken;

    uint256 public totalStaked;

    // Per-user information
    mapping(address => uint256) private _stakedBalances;
    mapping(address => uint256) private _rewards;
    
    // Reward calculation variables
    uint256 public rewardRate; // Rewards per second
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;

    mapping(address => uint256) private _userRewardPerTokenPaid;

    // ============ Events ============

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event RewardClaimed(address indexed user, uint256 amount);
    event RewardRateUpdated(uint256 newRate);
    event RewardsFunded(uint256 amount);

    // ============ Errors ============

    error InvalidAmount();
    error NothingToClaim();

    // ============ Constructor ============

    constructor(address _stakingToken, address _rewardsToken) Ownable(msg.sender) {
        stakingToken = IERC20(_stakingToken);
        rewardsToken = IERC20(_rewardsToken);
    }

    // ============ External Functions ============

    /**
     * @notice Stake tokens.
     * @param amount The amount of stakingToken to stake.
     */
    function stake(uint256 amount) external nonReentrant updateReward(msg.sender) {
        if (amount == 0) revert InvalidAmount();
        
        totalStaked += amount;
        _stakedBalances[msg.sender] += amount;
        
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        
        emit Staked(msg.sender, amount);
    }

    /**
     * @notice Unstake tokens.
     * @param amount The amount of stakingToken to unstake.
     */
    function unstake(uint256 amount) external nonReentrant updateReward(msg.sender) {
        if (amount == 0) revert InvalidAmount();
        if (_stakedBalances[msg.sender] < amount) revert InvalidAmount();
        
        totalStaked -= amount;
        _stakedBalances[msg.sender] -= amount;
        
        stakingToken.safeTransfer(msg.sender, amount);
        
        emit Unstaked(msg.sender, amount);
    }

    /**
     * @notice Claim accumulated rewards.
     */
    function claimReward() external nonReentrant updateReward(msg.sender) {
        uint256 reward = _rewards[msg.sender];
        if (reward == 0) revert NothingToClaim();

        _rewards[msg.sender] = 0;
        rewardsToken.safeTransfer(msg.sender, reward);

        emit RewardClaimed(msg.sender, reward);
    }

    // ============ View Functions ============

    /**
     * @notice Get the amount staked by a user.
     */
    function stakedBalance(address account) external view returns (uint256) {
        return _stakedBalances[account];
    }
    
    /**
     * @notice Calculate the rewards earned by an account.
     */
    function earned(address account) public view returns (uint256) {
        return _stakedBalances[account] * (rewardPerToken() - _userRewardPerTokenPaid[account]) / 1e18 + _rewards[account];
    }

    /**
     * @notice Calculate the reward per token.
     */
    function rewardPerToken() public view returns (uint256) {
        if (totalStaked == 0) {
            return rewardPerTokenStored;
        }
        return rewardPerTokenStored + ( (block.timestamp - lastUpdateTime) * rewardRate * 1e18 / totalStaked );
    }

    // ============ Owner Functions ============

    /**
     * @notice Set the reward rate (rewards per second).
     * @param _rewardRate The new reward rate.
     */
    function setRewardRate(uint256 _rewardRate) external onlyOwner {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = block.timestamp;
        rewardRate = _rewardRate;
        emit RewardRateUpdated(_rewardRate);
    }

    /**
     * @notice Fund the contract with reward tokens.
     * @param amount The amount of rewardsToken to fund.
     */
    function fundRewards(uint256 amount) external onlyOwner updateReward(address(0)) {
        if (amount == 0) revert InvalidAmount();
        rewardsToken.safeTransferFrom(msg.sender, address(this), amount);
        emit RewardsFunded(amount);
    }

    // ============ Modifiers ============

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = block.timestamp;

        if (account != address(0)) {
            _rewards[account] = earned(account);
            _userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        
        _;
    }
}
