// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/StakingContract.sol";
import "../src/MyToken.sol";

/**
 * @title StakingContractTest
 * @notice Test suite for the StakingContract
 */
contract StakingContractTest is Test {
    StakingContract public stakingContract;
    MyToken public stakingToken;
    MyToken public rewardsToken;

    address public owner;
    address public staker1;
    address public staker2;

    uint256 constant INITIAL_STAKER_BALANCE = 1000 * 10**18;
    uint256 constant REWARD_FUND_AMOUNT = 1_000_000 * 10**18;

    function setUp() public {
        owner = address(this);
        staker1 = makeAddr("staker1");
        staker2 = makeAddr("staker2");

        // Deploy tokens
        stakingToken = new MyToken();
        rewardsToken = new MyToken();

        // Deploy StakingContract
        stakingContract = new StakingContract(address(stakingToken), address(rewardsToken));

        // Fund stakers with staking tokens
        vm.prank(owner);
        stakingToken.transfer(staker1, INITIAL_STAKER_BALANCE);
        vm.prank(owner);
        stakingToken.transfer(staker2, INITIAL_STAKER_BALANCE);

        // Fund the staking contract with reward tokens
        vm.prank(owner);
        rewardsToken.transfer(address(stakingContract), REWARD_FUND_AMOUNT);
        vm.prank(owner);
        stakingContract.fundRewards(REWARD_FUND_AMOUNT); // Must call function to track
    }

    // ============ Staking Tests ============

    function test_Stake_Success() public {
        uint256 stakeAmount = 100 * 10**18;

        vm.startPrank(staker1);
        stakingToken.approve(address(stakingContract), stakeAmount);
        stakingContract.stake(stakeAmount);
        vm.stopPrank();

        assertEq(stakingContract.stakedBalance(staker1), stakeAmount, "Staked balance should be updated");
        assertEq(stakingContract.totalStaked(), stakeAmount, "Total staked should be updated");
        assertEq(stakingToken.balanceOf(address(stakingContract)), stakeAmount, "Contract's token balance should increase");
    }
    
    function test_Stake_RevertOnZeroAmount() public {
        vm.prank(staker1);
        vm.expectRevert(StakingContract.InvalidAmount.selector);
        stakingContract.stake(0);
    }
    
    // ============ Unstaking Tests ============

    function test_Unstake_Success() public {
        uint256 stakeAmount = 100 * 10**18;

        // Staker1 stakes
        vm.startPrank(staker1);
        stakingToken.approve(address(stakingContract), stakeAmount);
        stakingContract.stake(stakeAmount);
        
        // Staker1 unstakes half
        uint256 unstakeAmount = stakeAmount / 2;
        stakingContract.unstake(unstakeAmount);
        vm.stopPrank();

        assertEq(stakingContract.stakedBalance(staker1), unstakeAmount, "Staked balance should be reduced");
        assertEq(stakingContract.totalStaked(), unstakeAmount, "Total staked should be reduced");
        assertEq(stakingToken.balanceOf(staker1), INITIAL_STAKER_BALANCE - unstakeAmount, "Staker's token balance should increase");
    }

    function test_Unstake_RevertOnZeroAmount() public {
        vm.prank(staker1);
        vm.expectRevert(StakingContract.InvalidAmount.selector);
        stakingContract.unstake(0);
    }

    function test_Unstake_RevertInsufficientStaked() public {
        uint256 stakeAmount = 100 * 10**18;
        uint256 unstakeAmount = stakeAmount + 1;

        // Staker1 stakes
        vm.startPrank(staker1);
        stakingToken.approve(address(stakingContract), stakeAmount);
        stakingContract.stake(stakeAmount);
        
        // Staker1 tries to unstake more than staked
        vm.expectRevert(StakingContract.InvalidAmount.selector);
        stakingContract.unstake(unstakeAmount);
        vm.stopPrank();
    }
    
    // ============ Reward Tests ============

    function test_Rewards_AccrueOverTime() public {
        uint256 stakeAmount = 100 * 10**18;
        uint256 rewardRate = 1 * 10**18; // 1 reward token per second

        // Set reward rate
        vm.prank(owner);
        stakingContract.setRewardRate(rewardRate);

        // Staker1 stakes
        vm.startPrank(staker1);
        stakingToken.approve(address(stakingContract), stakeAmount);
        stakingContract.stake(stakeAmount);
        vm.stopPrank();

        // Warp forward in time
        uint256 timeToWarp = 100; // 100 seconds
        vm.warp(block.timestamp + timeToWarp);

        uint256 expectedRewards = timeToWarp * rewardRate;
        assertEq(stakingContract.earned(staker1), expectedRewards, "Rewards should accrue over time");
    }

    function test_ClaimReward_Success() public {
        uint256 stakeAmount = 100 * 10**18;
        uint256 rewardRate = 1 * 10**18;

        vm.prank(owner);
        stakingContract.setRewardRate(rewardRate);

        vm.startPrank(staker1);
        stakingToken.approve(address(stakingContract), stakeAmount);
        stakingContract.stake(stakeAmount);
        vm.stopPrank();

        vm.warp(block.timestamp + 100);
        
        uint256 earnedRewards = stakingContract.earned(staker1);
        uint256 balanceBefore = rewardsToken.balanceOf(staker1);
        
        vm.prank(staker1);
        stakingContract.claimReward();

        uint256 balanceAfter = rewardsToken.balanceOf(staker1);
        assertEq(balanceAfter, balanceBefore + earnedRewards, "Staker should receive earned rewards");
        assertEq(stakingContract.earned(staker1), 0, "Earned rewards should reset after claiming");
    }
    
    function test_ClaimReward_RevertOnNoRewards() public {
        vm.prank(staker1);
        vm.expectRevert(StakingContract.NothingToClaim.selector);
        stakingContract.claimReward();
    }

    function test_MultipleStakers_Rewards() public {
        uint256 stakeAmount1 = 100 * 10**18;
        uint256 stakeAmount2 = 300 * 10**18;
        uint256 rewardRate = 4 * 10**18; // 4 tokens/sec total reward

        vm.prank(owner);
        stakingContract.setRewardRate(rewardRate);

        // Staker1 stakes 100 tokens (should get 1/4 of rewards)
        vm.startPrank(staker1);
        stakingToken.approve(address(stakingContract), stakeAmount1);
        stakingContract.stake(stakeAmount1);
        vm.stopPrank();
        
        uint256 time0 = block.timestamp;
        
        // Staker2 stakes 300 tokens (should get 3/4 of rewards)
        vm.startPrank(staker2);
        stakingToken.approve(address(stakingContract), stakeAmount2);
        stakingContract.stake(stakeAmount2);
        vm.stopPrank();

        uint256 time1 = block.timestamp;

        // Staker1's rewards for the period before staker2 joined
        uint256 period1Rewards = (time1 - time0) * rewardRate;

        // Warp forward another 100 seconds
        uint256 timeDelta2 = 100;
        vm.warp(block.timestamp + timeDelta2);
        
        // During period 2, staker1 gets 1/4 of rewards
        uint256 staker1_period2_rewards = timeDelta2 * rewardRate * stakeAmount1 / (stakeAmount1 + stakeAmount2);
        // Staker2 gets 3/4 of rewards
        uint256 staker2_period2_rewards = timeDelta2 * rewardRate * stakeAmount2 / (stakeAmount1 + stakeAmount2);
        
        uint256 expectedStaker1Rewards = period1Rewards + staker1_period2_rewards;

        assertApproxEqAbs(stakingContract.earned(staker1), expectedStaker1Rewards, 1, "Staker1 rewards should be correct");
        assertApproxEqAbs(stakingContract.earned(staker2), staker2_period2_rewards, 1, "Staker2 rewards should be correct");
    }

    // ============ Owner Functions Tests ============

    function test_SetRewardRate_Success() public {
        uint256 newRate = 2 * 10**18;
        
        vm.prank(owner);
        stakingContract.setRewardRate(newRate);
        
        assertEq(stakingContract.rewardRate(), newRate, "Reward rate should be updated");
    }

    function test_SetRewardRate_RevertWhenNotOwner() public {
        vm.prank(staker1);
        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        stakingContract.setRewardRate(1);
    }

    function test_FundRewards_Success() public {
        uint256 fundAmount = 500 * 10**18;
        uint256 initialBalance = rewardsToken.balanceOf(address(stakingContract));
        
        vm.prank(owner);
        rewardsToken.approve(address(stakingContract), fundAmount);
        stakingContract.fundRewards(fundAmount);
        
        assertEq(rewardsToken.balanceOf(address(stakingContract)), initialBalance + fundAmount, "Contract reward balance should increase");
    }

    function test_FundRewards_RevertWhenNotOwner() public {
        uint256 fundAmount = 500 * 10**18;
        
        vm.prank(staker1);
        rewardsToken.approve(address(stakingContract), fundAmount);
        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        stakingContract.fundRewards(fundAmount);
    }
}
