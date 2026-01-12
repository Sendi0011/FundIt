// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../../src/security/AutomationGuard.sol";

// Mock contract to test AutomationGuard functionality
contract MockGuardedContract is AutomationGuard {
    event TestFunctionCalled();

    function guardedFunction() external onlyAutomation {
        emit TestFunctionCalled();
    }

    function unguardedFunction() external {
        emit TestFunctionCalled();
    }
}

contract AutomationGuardTest is Test {
    MockGuardedContract public guardedContract;

    address public owner;
    address public automationService;
    address public stranger;

    function setUp() public {
        owner = address(this);
        automationService = makeAddr("automationService");
        stranger = makeAddr("stranger");

        // Deploy the mock contract. The constructor grants DEFAULT_ADMIN_ROLE to msg.sender (owner)
        guardedContract = new MockGuardedContract();

        // Owner grants the automation role to automationService
        vm.prank(owner);
        guardedContract.grantAutomationRole(automationService);
    }

    // Test for successful call to a guarded function by an automation service
    function test_GuardedFunction_AutomationService() public {
        vm.expectEmit(true, true, true, true);
        emit MockGuardedContract.TestFunctionCalled();

        vm.prank(automationService);
        guardedContract.guardedFunction();
    }

    // Test that a stranger cannot call a guarded function
    function test_GuardedFunction_Unauthorized() public {
        vm.prank(stranger);
        vm.expectRevert(AutomationGuard.UnauthorizedAutomation.selector);
        guardedContract.guardedFunction();
    }

    // Test that a regular admin (owner) cannot call a guarded function without automation role
    function test_GuardedFunction_OwnerWithoutAutomationRole() public {
        // Owner is DEFAULT_ADMIN_ROLE, but not AUTOMATION_ROLE by default
        vm.prank(owner);
        vm.expectRevert(AutomationGuard.UnauthorizedAutomation.selector);
        guardedContract.guardedFunction();
    }

    // Test that an unguarded function can be called by anyone
    function test_UnguardedFunction_Anyone() public {
        vm.expectEmit(true, true, true, true);
        emit MockGuardedContract.TestFunctionCalled();
        vm.prank(stranger);
        guardedContract.unguardedFunction();

        vm.expectEmit(true, true, true, true);
        emit MockGuardedContract.TestFunctionCalled();
        vm.prank(automationService);
        guardedContract.unguardedFunction();

        vm.expectEmit(true, true, true, true);
        emit MockGuardedContract.TestFunctionCalled();
        vm.prank(owner);
        guardedContract.unguardedFunction();
    }

    // Test granting an automation role by the default admin
    function test_GrantAutomationRole_Success() public {
        address newAutomationService = makeAddr("newAutomationService");

        vm.expectEmit(true, true, true, true);
        emit AutomationGuard.AutomationServiceGranted(newAutomationService);

        vm.prank(owner);
        guardedContract.grantAutomationRole(newAutomationService);

        assertTrue(guardedContract.hasRole(guardedContract.AUTOMATION_ROLE(), newAutomationService));

        // Verify the new service can call the guarded function
        vm.expectEmit(true, true, true, true);
        emit MockGuardedContract.TestFunctionCalled();
        vm.prank(newAutomationService);
        guardedContract.guardedFunction();
    }

    // Test revoking an automation role by the default admin
    function test_RevokeAutomationRole_Success() public {
        // automationService already has the role from setUp

        vm.expectEmit(true, true, true, true);
        emit AutomationGuard.AutomationServiceRevoked(automationService);

        vm.prank(owner);
        guardedContract.revokeAutomationRole(automationService);

        assertFalse(guardedContract.hasRole(guardedContract.AUTOMATION_ROLE(), automationService));

        // Verify the revoked service can no longer call the guarded function
        vm.prank(automationService);
        vm.expectRevert(AutomationGuard.UnauthorizedAutomation.selector);
        guardedContract.guardedFunction();
    }

    // Test granting automation role by an unauthorized address
    function test_GrantAutomationRole_Unauthorized() public {
        address newAutomationService = makeAddr("newAutomationService");

        vm.prank(stranger);
        vm.expectRevert(abi.encodeWithSelector(AccessControl.AccessControlUnauthorizedAccount.selector, stranger, guardedContract.DEFAULT_ADMIN_ROLE()));
        guardedContract.grantAutomationRole(newAutomationService);
    }

    // Test revoking automation role by an unauthorized address
    function test_RevokeAutomationRole_Unauthorized() public {
        vm.prank(stranger);
        vm.expectRevert(abi.encodeWithSelector(AccessControl.AccessControlUnauthorizedAccount.selector, stranger, guardedContract.DEFAULT_ADMIN_ROLE()));
        guardedContract.revokeAutomationRole(automationService);
    }

    // Test that default admin can grant themselves the automation role
    function test_GrantAutomationRole_OwnerSelfGrant() public {
        vm.prank(owner);
        guardedContract.grantAutomationRole(owner);

        assertTrue(guardedContract.hasRole(guardedContract.AUTOMATION_ROLE(), owner));

        // Verify owner can now call guarded function
        vm.expectEmit(true, true, true, true);
        emit MockGuardedContract.TestFunctionCalled();
        vm.prank(owner);
        guardedContract.guardedFunction();
    }

    // Test initial role assignment in constructor
    function test_Constructor_DefaultAdminRole() public {
        assertTrue(guardedContract.hasRole(guardedContract.DEFAULT_ADMIN_ROLE(), owner));
        assertFalse(guardedContract.hasRole(guardedContract.AUTOMATION_ROLE(), owner)); // Owner doesn't get automation role by default
    }
}
