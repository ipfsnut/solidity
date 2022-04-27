// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts@4.5.0/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts@4.5.0/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts@4.5.0/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts@4.5.0/security/Pausable.sol";
import "@openzeppelin/contracts@4.5.0/access/AccessControl.sol";
import "@openzeppelin/contracts@4.5.0/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts@4.5.0/utils/Counters.sol";

/// @custom:security-contact info@wippublishing.com
contract OfficialPageDAOMembership is ERC721, ERC721Enumerable, ERC721URIStorage, Pausable, AccessControl, ERC721Burnable {
    using Counters for Counters.Counter;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    Counters.Counter private _tokenIdCounter;

    string silverURI = "https://ipfs.nftbookbazaar.com/ipfs/QmcBpuMDjuAvaz4TV5nt25Bv9ow3UTfDrQXcaXEnAESBoU#0";
    string wippyURI = "https://ipfs.nftbookbazaar.com/ipfs/Qmbr4ynQH4XgFdSQXuKK2DywBC9SakqsZtzvcD4gQrynbe#0";
    string diamondURI = "https://ipfs.nftbookbazaar.com/ipfs/QmaBSBGuMyPmjFcLtV528YWCJaSitLtZn9c6kSwduhZXaY#0";
    
    uint256 _price;
    uint256 public constant diamondMaxSupply = 13 * (10 ** 18);
    uint256 public constant silverMaxSupply = 10000 * (10 ** 18);
    uint256 public constant wippyMaxSupply = 384 * (10 ** 18);
    uint256 diamondPrice = 2.5 * (10 ** 18);
    uint256 silverPrice = 0.025 * (10 ** 18);


    constructor() ERC721("Official PageDAO Membership", "OPM") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function safeMint(address to, string memory uri) public onlyRole(MINTER_ROLE) {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

                
    // This function makes the tokens airdroppable.
   
    function airDropWippy(address[] memory toAddresses) public onlyRole(MINTER_ROLE) {
        for(uint i = 0; i < toAddresses.length; i++) {
        safeMint(toAddresses[i], wippyURI);
        }

    }

    function MintDiamond() payable public whenNotPaused {
        require(totalSupply() < diamondMaxSupply);
        require(diamondPrice == msg.value, "Ether value sent is not correct");
        
        uint256 tokenID = totalSupply();
        _safeMint(_msgSender(), tokenID);
        _setTokenURI(tokenID, diamondURI);
    }

    function MintSilver() payable public whenNotPaused {
        require(totalSupply() < silverMaxSupply);
        require(silverPrice == msg.value, "Ether value sent is not correct");
        
        uint256 tokenID = totalSupply();
        _safeMint(_msgSender(), tokenID);
        _setTokenURI(tokenID, silverURI);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
