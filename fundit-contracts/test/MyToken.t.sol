// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/MyToken.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Using for safe arithmetic operations

/**
 * @title MyTokenTest
 * @notice Test suite for the MyToken ERC20 contract
 */
contract MyTokenTest is Test {
    MyToken public token;
    
    address public owner;
    address public user1;
    address public user2;
    address public constant ZERO_ADDRESS = address(0);

    // ERC20 Events
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function setUp() public {
        owner = address(this);
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        
        // Deploy the contract
        token = new MyToken();
    }

    // ============ Deployment Tests ============

    function test_InitialSupplyAndOwnerBalance() public {
        uint256 expectedTotalSupply = 1_000_000 * 10**18;
        assertEq(token.totalSupply(), expectedTotalSupply, "Total supply should be 1,000,000 * 10^18");
        assertEq(token.balanceOf(owner), expectedTotalSupply, "Owner should have the initial supply");
    }

    function test_NameAndSymbol() public {
        assertEq(token.name(), "MyToken", "Name should be MyToken");
        assertEq(token.symbol(), "MTK", "Symbol should be MTK");
    }

    function test_Decimals() public {
        assertEq(token.decimals(), 18, "Decimals should be 18");
    }

    // ============ Transfer Tests ============

    function test_Transfer_Success() public {
        uint256 transferAmount = 100 * 10**18; // 100 tokens
        uint256 ownerBalanceBefore = token.balanceOf(owner);
        uint256 user1BalanceBefore = token.balanceOf(user1);

        vm.expectEmit(true, true, true, true);
        emit Transfer(owner, user1, transferAmount);
        
        vm.prank(owner);
        token.transfer(user1, transferAmount);

        assertEq(token.balanceOf(owner), ownerBalanceBefore - transferAmount, "Owner balance should decrease");
        assertEq(token.balanceOf(user1), user1BalanceBefore + transferAmount, "User1 balance should increase");
    }

    function test_Transfer_RevertInsufficientBalance() public {
        uint256 transferAmount = 1_000_000 * 10**18 + 1; // More than total supply
        
        vm.prank(owner);
        vm.expectRevert(bytes("ERC20: transfer amount exceeds balance"));
        token.transfer(user1, transferAmount);
    }

    function test_Transfer_RevertZeroAddress() public {
        uint256 transferAmount = 100 * 10**18;
        
        vm.prank(owner);
        vm.expectRevert(bytes("ERC20: transfer to the zero address"));
        token.transfer(ZERO_ADDRESS, transferAmount);
    }

    // ============ Approval and TransferFrom Tests ============

    function test_Approve_Success() public {
        uint256 approveAmount = 500 * 10**18;
        
        vm.expectEmit(true, true, true, true);
        emit Approval(owner, user1, approveAmount);
        
        vm.prank(owner);
        token.approve(user1, approveAmount);

        assertEq(token.allowance(owner, user1), approveAmount, "Allowance should be set correctly");
    }

    function test_Approve_RevertZeroAddress() public {
        uint256 approveAmount = 500 * 10**18;
        
        vm.prank(owner);
        vm.expectRevert(bytes("ERC20: approve to the zero address"));
        token.approve(ZERO_ADDRESS, approveAmount);
    }

    function test_TransferFrom_Success() public {
        uint256 approveAmount = 500 * 10**18;
        uint256 transferAmount = 100 * 10**18;

        vm.prank(owner);
        token.approve(user1, approveAmount); // Owner approves user1

        uint256 ownerBalanceBefore = token.balanceOf(owner);
        uint256 user2BalanceBefore = token.balanceOf(user2);
        uint256 user1AllowanceBefore = token.allowance(owner, user1);

        vm.expectEmit(true, true, true, true);
        emit Transfer(owner, user2, transferAmount);

        vm.prank(user1); // User1 calls transferFrom
        token.transferFrom(owner, user2, transferAmount);

        assertEq(token.balanceOf(owner), ownerBalanceBefore - transferAmount, "Owner balance should decrease");
        assertEq(token.balanceOf(user2), user2BalanceBefore + transferAmount, "User2 balance should increase");
        assertEq(token.allowance(owner, user1), user1AllowanceBefore - transferAmount, "Allowance should decrease");
    }

    function test_TransferFrom_RevertInsufficientAllowance() public {
        uint256 approveAmount = 50 * 10**18;
        uint256 transferAmount = 100 * 10**18; // More than allowance

        vm.prank(owner);
        token.approve(user1, approveAmount);

        vm.prank(user1);
        vm.expectRevert(bytes("ERC20: insufficient allowance"));
        token.transferFrom(owner, user2, transferAmount);
    }

    function test_TransferFrom_RevertInsufficientBalance() public {
        uint256 approveAmount = 1_000_000 * 10**18;
        uint256 transferAmount = 1_000_000 * 10**18 + 1; // More than owner's balance

        vm.prank(owner);
        token.approve(user1, approveAmount);

        vm.prank(user1);
        vm.expectRevert(bytes("ERC20: transfer amount exceeds balance"));
        token.transferFrom(owner, user2, transferAmount);
    }

    function test_TransferFrom_RevertZeroAddressTo() public {
        uint256 approveAmount = 100 * 10**18;
        uint256 transferAmount = 50 * 10**18;

        vm.prank(owner);
        token.approve(user1, approveAmount);

        vm.prank(user1);
        vm.expectRevert(bytes("ERC20: transfer to the zero address"));
        token.transferFrom(owner, ZERO_ADDRESS, transferAmount);
    }
    
    function test_TransferFrom_RevertZeroAddressFrom() public {
        uint256 approveAmount = 100 * 10**18;
        uint256 transferAmount = 50 * 10**18;

        vm.prank(owner);
        token.approve(user1, approveAmount);

        vm.prank(user1);
        vm.expectRevert(bytes("ERC20: transfer from the zero address")); // This revert message can vary depending on exact ERC20 implementation details
        token.transferFrom(ZERO_ADDRESS, user2, transferAmount);
    }

    // ============ Allowance Edge Cases ============

    function test_IncreaseAllowance() public {
        uint256 initialAllowance = 100 * 10**18;
        uint256 addedAllowance = 50 * 10**18;
        
        vm.prank(owner);
        token.approve(user1, initialAllowance);
        
        vm.expectEmit(true, true, true, true);
        emit Approval(owner, user1, initialAllowance + addedAllowance);
        
        vm.prank(owner);
        token.increaseAllowance(user1, addedAllowance);
        
        assertEq(token.allowance(owner, user1), initialAllowance + addedAllowance);
    }

    function test_DecreaseAllowance() public {
        uint256 initialAllowance = 100 * 10**18;
        uint256 subtractedAllowance = 50 * 10**18;
        
        vm.prank(owner);
        token.approve(user1, initialAllowance);
        
        vm.expectEmit(true, true, true, true);
        emit Approval(owner, user1, initialAllowance - subtractedAllowance);
        
        vm.prank(owner);
        token.decreaseAllowance(user1, subtractedAllowance);
        
        assertEq(token.allowance(owner, user1), initialAllowance - subtractedAllowance);
    }

    function test_DecreaseAllowance_RevertWhenBelowZero() public {
        uint256 initialAllowance = 50 * 10**18;
        uint256 subtractedAllowance = 100 * 10**18;
        
        vm.prank(owner);
        token.approve(user1, initialAllowance);
        
        vm.prank(owner);
        vm.expectRevert(bytes("ERC20: decreased allowance below zero"));
        token.decreaseAllowance(user1, subtractedAllowance);
    }
}
