// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/MyNFT.sol";

/**
 * @title MyNFTTest
 * @notice Test suite for the MyNFT ERC1155 contract
 */
contract MyNFTTest is Test {
    MyNFT public nft;
    
    address public owner;
    address public user1;
    address public user2;
    address public operator; // Address approved to manage tokens for others
    
    // ERC1155 Events
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event URI(string value, uint256 indexed id);

    function setUp() public {
        owner = address(this);
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        operator = makeAddr("operator");
        
        // Deploy the contract with a base URI
        nft = new MyNFT("https://base.example/token/{id}.json");
    }

    // ============ Deployment Tests ============

    function test_InitialURI() public {
        assertEq(nft.uri(0), "https://base.example/token/{id}.json", "Initial URI should be set");
    }

    // ============ Minting Tests ============

    function test_Mint_Success() public {
        uint256 tokenId = 1;
        uint256 amount = 100;

        vm.expectEmit(true, true, true, true);
        emit TransferSingle(owner, address(0), user1, tokenId, amount);

        vm.prank(owner);
        nft.mint(user1, tokenId, amount, "");

        assertEq(nft.balanceOf(user1, tokenId), amount, "User1 should have minted amount");
    }

    function test_MintBatch_Success() public {
        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = 1;
        tokenIds[1] = 2;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 100;
        amounts[1] = 200;

        vm.expectEmit(true, true, true, true);
        emit TransferBatch(owner, address(0), user1, tokenIds, amounts);

        vm.prank(owner);
        nft.mintBatch(user1, tokenIds, amounts, "");

        assertEq(nft.balanceOf(user1, tokenIds[0]), amounts[0], "User1 should have minted amount for tokenId 1");
        assertEq(nft.balanceOf(user1, tokenIds[1]), amounts[1], "User1 should have minted amount for tokenId 2");
    }

    function test_Mint_RevertWhenNotOwner() public {
        uint256 tokenId = 1;
        uint256 amount = 100;

        vm.prank(user1); // Simulate call from non-owner
        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        nft.mint(user1, tokenId, amount, "");
    }

    function test_MintBatch_RevertWhenNotOwner() public {
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 1;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 100;

        vm.prank(user1); // Simulate call from non-owner
        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        nft.mintBatch(user1, tokenIds, amounts, "");
    }

    // ============ URI Management Tests ============

    function test_SetURI_Success() public {
        string memory newURI = "https://new.example/data/{id}.json";
        
        vm.prank(owner);
        nft.setURI(newURI);
        
        assertEq(nft.uri(0), newURI, "URI should be updated");
        vm.expectEmit(true, true, false, true); // id is indexed, value is not
        emit URI(newURI, 0); // For ERC1155, URI event should emit with id 0 for base URI changes
    }
    
    function test_SetURI_RevertWhenNotOwner() public {
        vm.prank(user1);
        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        nft.setURI("https://new.example/data/{id}.json");
    }

    // ============ ERC1155 Specifics ============

    function test_BalanceOfBatch() public {
        uint256 tokenId1 = 1;
        uint256 tokenId2 = 2;
        uint256 amount1 = 50;
        uint256 amount2 = 75;

        vm.prank(owner);
        nft.mint(user1, tokenId1, amount1, "");
        vm.prank(owner);
        nft.mint(user1, tokenId2, amount2, "");

        address[] memory addresses = new address[](2);
        addresses[0] = user1;
        addresses[1] = user1;

        uint256[] memory ids = new uint256[](2);
        ids[0] = tokenId1;
        ids[1] = tokenId2;

        uint256[] memory balances = nft.balanceOfBatch(addresses, ids);

        assertEq(balances[0], amount1, "Balance of tokenId1 for user1 should be correct");
        assertEq(balances[1], amount2, "Balance of tokenId2 for user1 should be correct");
    }

    function test_SetApprovalForAll_Success() public {
        vm.expectEmit(true, true, true, true);
        emit ApprovalForAll(user1, operator, true);

        vm.prank(user1);
        nft.setApprovalForAll(operator, true);

        assertTrue(nft.isApprovedForAll(user1, operator), "Operator should be approved");
    }

    function test_SafeTransferFrom_Single_Success() public {
        uint256 tokenId = 1;
        uint256 amount = 50;

        // Mint to user1
        vm.prank(owner);
        nft.mint(user1, tokenId, 100, "");

        // User1 approves operator
        vm.prank(user1);
        nft.setApprovalForAll(operator, true);

        vm.expectEmit(true, true, true, true);
        emit TransferSingle(operator, user1, user2, tokenId, amount);

        vm.prank(operator); // Operator performs transfer
        nft.safeTransferFrom(user1, user2, tokenId, amount, "");

        assertEq(nft.balanceOf(user1, tokenId), 50, "User1 balance should decrease");
        assertEq(nft.balanceOf(user2, tokenId), 50, "User2 balance should increase");
    }

    function test_SafeTransferFrom_Batch_Success() public {
        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = 1;
        tokenIds[1] = 2;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 50;
        amounts[1] = 75;
        
        uint256[] memory mintedAmounts = new uint256[](2);
        mintedAmounts[0] = 100;
        mintedAmounts[1] = 150;


        // Mint to user1
        vm.prank(owner);
        nft.mintBatch(user1, tokenIds, mintedAmounts, "");

        // User1 approves operator
        vm.prank(user1);
        nft.setApprovalForAll(operator, true);

        vm.expectEmit(true, true, true, true);
        emit TransferBatch(operator, user1, user2, tokenIds, amounts);

        vm.prank(operator); // Operator performs batch transfer
        nft.safeBatchTransferFrom(user1, user2, tokenIds, amounts, "");

        assertEq(nft.balanceOf(user1, tokenIds[0]), mintedAmounts[0] - amounts[0], "User1 balance tokenId1 should decrease");
        assertEq(nft.balanceOf(user1, tokenIds[1]), mintedAmounts[1] - amounts[1], "User1 balance tokenId2 should decrease");
        assertEq(nft.balanceOf(user2, tokenIds[0]), amounts[0], "User2 balance tokenId1 should increase");
        assertEq(nft.balanceOf(user2, tokenIds[1]), amounts[1], "User2 balance tokenId2 should increase");
    }

    function test_SafeTransferFrom_RevertInsufficientBalance() public {
        uint256 tokenId = 1;
        uint256 amount = 100;

        // Mint less to user1 than amount to transfer
        vm.prank(owner);
        nft.mint(user1, tokenId, 50, ""); // Mints only 50

        // User1 approves operator
        vm.prank(user1);
        nft.setApprovalForAll(operator, true);

        vm.prank(operator);
        vm.expectRevert(bytes("ERC1155: insufficient balance for transfer"));
        nft.safeTransferFrom(user1, user2, tokenId, amount, "");
    }
}
