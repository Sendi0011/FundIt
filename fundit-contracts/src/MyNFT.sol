// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MyNFT is ERC1155, Ownable {
    // Base URI for metadata. {id} will be replaced by the token ID.
    string private _baseURI;

    constructor(string memory uri_) ERC1155(uri_) Ownable(msg.sender) {
        _baseURI = uri_;
    }

    // Function to set a new URI for all token types
    function setURI(string memory newUri) public onlyOwner {
        _setURI(newUri);
        _baseURI = newUri;
    }

    // Function to mint a new token type and initial supply to an address
    function mint(address to, uint256 id, uint256 amount, bytes memory data)
        public
        onlyOwner
    {
        _mint(to, id, amount, data);
    }

    // Function to mint a batch of new token types and initial supplies to an address
    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        public
        onlyOwner
    {
        _mintBatch(to, ids, amounts, data);
    }

    // The following functions are overrides required by Solidity.

    function uri(uint256) public view override returns (string memory) {
        return _baseURI;
    }
}
