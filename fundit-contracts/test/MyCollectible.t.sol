// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/MyCollectible.sol";

/**
 * @title MyCollectibleTest
 * @notice Test suite for the MyCollectible ERC721 contract
 */
contract MyCollectibleTest is Test {
    MyCollectible public collectible;
    
    address public owner;
    address public user1;
    
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    function setUp() public {
        owner = address(this);
        user1 = makeAddr("user1");
        
        // Deploy the contract
        collectible = new MyCollectible();
    }

    // ============ Deployment Tests ============

    function test_InitialNameAndSymbol() public {
        assertEq(collectible.name(), "MyCollectible", "Name should be MyCollectible");
        assertEq(collectible.symbol(), "MYC", "Symbol should be MYC");
    }

    // ============ Minting Tests ============

    function test_Mint_Success() public {
        string memory tokenURI = "https://example.com/nft/1";
        
        // Expect a Transfer event from address(0) to user1 for tokenId 1
        vm.expectEmit(true, true, true, true);
        emit Transfer(address(0), user1, 1);
        
        uint256 newItemId = collectible.mint(user1, tokenURI);
        
        assertEq(newItemId, 1, "First minted token ID should be 1");
        assertEq(collectible.ownerOf(newItemId), user1, "Owner of new token should be user1");
        assertEq(collectible.tokenURI(newItemId), tokenURI, "Token URI should be set correctly");
        assertEq(collectible.balanceOf(user1), 1, "user1 balance should be 1");
    }

    function test_Mint_IncrementsTokenId() public {
        string memory uri1 = "https://example.com/nft/1";
        string memory uri2 = "https://example.com/nft/2";
        
        uint256 tokenId1 = collectible.mint(user1, uri1);
        uint256 tokenId2 = collectible.mint(user1, uri2);

        assertEq(tokenId1, 1, "First token ID should be 1");
        assertEq(tokenId2, 2, "Second token ID should be 2");
    }
    
    function test_TokenURI() public {
        string memory tokenURI = "ipfs://QmTp2h3Z9ZkY8Z7Y8Z7Y8Z7Y8Z7Y8Z7Y8Z7Y8Z7Y8Z7";
        uint256 newItemId = collectible.mint(user1, tokenURI);
        
        string memory retrievedURI = collectible.tokenURI(newItemId);
        assertEq(retrievedURI, tokenURI, "Retrieved token URI does not match the minted one");
    }

    // ============ Access Control Tests ============

    function test_Mint_RevertWhenNotOwner() public {
        vm.prank(user1); // Simulate the call from user1
        
        string memory tokenURI = "https://example.com/nft/1";
        
        // Expect a revert with the Ownable: caller is not the owner message
        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        collectible.mint(user1, tokenURI);
    }
}
