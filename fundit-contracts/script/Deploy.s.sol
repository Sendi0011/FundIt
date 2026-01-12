// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../src/SpendAndSaveModule.sol";

/**
 * @title DeploySpendAndSave
 * @notice Deployment script for SpendAndSaveModule on Base
 * 
 * Usage:
 * 1. Set environment variables in .env file
 * 2. Run: forge script script/Deploy.s.sol:DeploySpendAndSave --rpc-url base --broadcast --verify
 * 
 * For testnet:
 * forge script script/Deploy.s.sol:DeploySpendAndSave --rpc-url base-sepolia --broadcast --verify
 */
contract DeploySpendAndSave is Script {
    
    // Base Mainnet USDC: 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913
    // Base Sepolia USDC: 0x036CbD53842c5426634e7929541eC2318f3dCF7e
    
    address constant BASE_MAINNET_USDC = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;
    address constant BASE_SEPOLIA_USDC = 0x036CbD53842c5426634e7929541eC2318f3dCF7e;
    
    SpendAndSaveModule public spendAndSave;
    
    function run() external {
        // Get deployer private key from environment
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        // Get automation service address from environment
        address automationService = vm.envAddress("AUTOMATION_SERVICE_ADDRESS");
        
        // Determine which network we're on
        uint256 chainId = block.chainid;
        address usdcAddress;
        
        if (chainId == 8453) {
            // Base Mainnet
            usdcAddress = BASE_MAINNET_USDC;
            console.log("Deploying to Base Mainnet");
        } else if (chainId == 84532) {
            // Base Sepolia
            usdcAddress = BASE_SEPOLIA_USDC;
            console.log("Deploying to Base Sepolia");
        } else {
            revert("Unsupported network");
        }
        
        console.log("Deployer address:", deployer);
        console.log("USDC address:", usdcAddress);
        console.log("Automation service:", automationService);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy SpendAndSaveModule
        console.log("\n=== Deploying SpendAndSaveModule ===");
        spendAndSave = new SpendAndSaveModule(usdcAddress);
        console.log("SpendAndSaveModule deployed at:", address(spendAndSave));
        
        // Grant automation role
        console.log("\n=== Granting Automation Role ===");
        spendAndSave.grantAutomationRole(automationService);
        console.log("Automation role granted to:", automationService);
        
        // Verify setup
        console.log("\n=== Verifying Deployment ===");
        console.log("USDC address in contract:", address(spendAndSave.USDC()));
        console.log("Has automation role:", spendAndSave.hasRole(spendAndSave.AUTOMATION_ROLE(), automationService));
        console.log("Contract owner:", spendAndSave.owner());
        
        vm.stopBroadcast();
        
        // Save deployment info
        _saveDeploymentInfo(chainId, address(spendAndSave), usdcAddress, automationService);
        
        console.log("\n=== Deployment Complete ===");
        console.log("SpendAndSaveModule:", address(spendAndSave));
        console.log("\nNext steps:");
        console.log("1. Verify contract on BaseScan (if not auto-verified)");
        console.log("2. Update frontend with contract address");
        console.log("3. Configure automation service with contract address");
        console.log("4. Test with a small deposit first");
    }
    
    function _saveDeploymentInfo(
        uint256 chainId,
        address spendAndSaveAddress,
        address usdcAddress,
        address automationService
    ) internal {
        string memory networkName = chainId == 8453 ? "base" : "base-sepolia";
        string memory json = string.concat(
            '{\n',
            '  "network": "', networkName, '",\n',
            '  "chainId": ', vm.toString(chainId), ',\n',
            '  "timestamp": ', vm.toString(block.timestamp), ',\n',
            '  "contracts": {\n',
            '    "SpendAndSaveModule": "', vm.toString(spendAndSaveAddress), '",\n',
            '    "USDC": "', vm.toString(usdcAddress), '"\n',
            '  },\n',
            '  "automationService": "', vm.toString(automationService), '"\n',
            '}'
        );
        
        string memory filename = string.concat("deployments/", networkName, "-latest.json");
        vm.writeFile(filename, json);
        console.log("\nDeployment info saved to:", filename);
    }
}

/**
 * @title DeployWithMocks
 * @notice Deployment script for local testing with mock contracts
 * 
 * Usage:
 * forge script script/Deploy.s.sol:DeployWithMocks --rpc-url localhost --broadcast
 */
contract DeployWithMocks is Script {
    
    MockUSDC public usdc;
    SpendAndSaveModule public spendAndSave;
    MockSavingsVault public vault;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("Deploying mock contracts for local testing");
        console.log("Deployer:", deployer);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy Mock USDC
        console.log("\n=== Deploying Mock USDC ===");
        usdc = new MockUSDC();
        console.log("Mock USDC deployed at:", address(usdc));
        
        // Deploy SpendAndSaveModule
        console.log("\n=== Deploying SpendAndSaveModule ===");
        spendAndSave = new SpendAndSaveModule(address(usdc));
        console.log("SpendAndSaveModule deployed at:", address(spendAndSave));
        
        // Grant automation role to deployer (for testing)
        spendAndSave.grantAutomationRole(deployer);
        console.log("Automation role granted to deployer");
        
        // Deploy Mock Vault for deployer
        console.log("\n=== Deploying Mock Vault ===");
        vault = new MockSavingsVault(deployer);
        console.log("Mock Vault deployed at:", address(vault));
        
        // Setup test account
        usdc.mint(deployer, 10_000 * 10**6);
        console.log("Minted 10,000 USDC to deployer");
        
        vm.stopBroadcast();
        
        console.log("\n=== Local Deployment Complete ===");
        console.log("Mock USDC:", address(usdc));
        console.log("SpendAndSaveModule:", address(spendAndSave));
        console.log("Mock Vault:", address(vault));
        console.log("\nYou can now interact with the contracts locally");
    }
}

/**
 * @title VerifyDeployment
 * @notice Script to verify an existing deployment
 * 
 * Usage:
 * forge script script/Deploy.s.sol:VerifyDeployment --rpc-url base
 */
contract VerifyDeployment is Script {
    
    function run() external view {
        address spendAndSaveAddress = vm.envAddress("SPEND_AND_SAVE_ADDRESS");
        address automationService = vm.envAddress("AUTOMATION_SERVICE_ADDRESS");
        
        console.log("=== Verifying Deployment ===");
        console.log("SpendAndSaveModule address:", spendAndSaveAddress);
        
        SpendAndSaveModule spendAndSave = SpendAndSaveModule(spendAndSaveAddress);
        
        // Check USDC address
        address usdcAddress = address(spendAndSave.USDC());
        console.log("\nUSDC address:", usdcAddress);
        
        // Check owner
        address owner = spendAndSave.owner();
        console.log("Contract owner:", owner);
        
        // Check automation role
        bool hasRole = spendAndSave.hasRole(spendAndSave.AUTOMATION_ROLE(), automationService);
        console.log("Automation service has role:", hasRole);
        console.log("Automation service address:", automationService);
        
        // Check if paused
        bool paused = spendAndSave.paused();
        console.log("Contract paused:", paused);
        
        console.log("\n=== Verification Complete ===");
        
        if (!hasRole) {
            console.log("\nWARNING: Automation service does not have automation role!");
        }
        if (paused) {
            console.log("\nWARNING: Contract is paused!");
        }
    }
}

// ============ Mock Contracts for Local Testing ============

contract MockUSDC is ERC20 {
    constructor() ERC20("USD Coin", "USDC") {
        _mint(msg.sender, 1_000_000 * 10**6);
    }

    function decimals() public pure override returns (uint8) {
        return 6;
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

contract MockSavingsVault {
    address public owner;
    
    constructor(address _owner) {
        owner = _owner;
    }

    function depositFlexible(uint256) external pure {}
    function depositTarget(uint256, uint256) external pure {}
}