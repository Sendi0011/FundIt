// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";

abstract contract AutomationGuard is AccessControl {
    bytes32 public constant AUTOMATION_ROLE = keccak256("AUTOMATION_ROLE");

    error UnauthorizedAutomation();

    event AutomationServiceGranted(address indexed service);
    event AutomationServiceRevoked(address indexed service);

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    modifier onlyAutomation() {
        if (!hasRole(AUTOMATION_ROLE, msg.sender)) {
            revert UnauthorizedAutomation();
        }
        _;
    }

    function grantAutomationRole(address service) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(AUTOMATION_ROLE, service);
        emit AutomationServiceGranted(service);
    }

    function revokeAutomationRole(address service) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(AUTOMATION_ROLE, service);
        emit AutomationServiceRevoked(service);
    }
}