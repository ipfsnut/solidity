// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

// init - set initial whitelist contract/tokenid, set Minting Contract
// mint 
// ------ call 0xd490F7FC26592bA987c81Cd6F10816487F6947B7 create function (maxsupply/initialsupply/uri/data --- used?)
// set whitelist owner contracts
// canMint function returns bool

interface IERC1155 {
    function balanceOf(address _operator, uint256 tokenID) external view returns (uint256);
}

interface IERC721 {
    function balanceOf(address _operator) external view returns (uint256);
}

interface IUniftyERC1155 {
   function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount, bytes calldata _data)
    external;

  function setApprovalForAll(address _operator, bool _approved)
    external;
  
  function isApprovedForAll(address _owner, address _operator) external view returns (bool isOperator);
	function totalSupply(uint256 _id) external view returns (uint256);
	function maxSupply(uint256 _id) external view returns (uint256);
	function create(
		uint256 _maxSupply,
		uint256 _initialSupply,
		string calldata _uri,
		bytes calldata _data
	) external returns (uint256 tokenId);	
	function updateUri(uint256 _id, string calldata _uri) external;

	function mint(
		uint256 _id,
		uint256 _quantity,
		bytes calldata _data
	) external;
}

contract CommunityMintControl is AccessControl, ERC1155Holder {
    bytes32 public constant ADMIN = keccak256("ADMIN");

    event Minted(
        uint256 indexed tokenID,
        address receiver
    );

    // no token id represents an ERC721 - tokenID represents 
    struct WhitelistNFT {
        string description;
        bool isMultitoken;
    }

    mapping (bytes => WhitelistNFT) public WhitelistNFTs;
    bytes[] WhitelistNFTArray;
    mapping (bytes => uint256) bytesToIdx;

    IUniftyERC1155 public Collection;

    constructor (address _collectionAddress, string memory _description, address _NFTAddress, uint256 _tokenID, bool _isMultitoken) {
        _setupRole(ADMIN, _msgSender());
        Collection = IUniftyERC1155(_collectionAddress); 
        setWhitelistNFT(_NFTAddress, _tokenID, _description, _isMultitoken);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155Receiver, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function setCollection(address _address) public onlyRole(ADMIN) {
        Collection = IUniftyERC1155(_address);
    }

    function setWhitelistNFT(address _address, uint256 _tokenID, string memory _description,  bool _isMultitoken) public onlyRole(ADMIN) {
        bytes memory packedIdentifier = Identifier(_address, _tokenID);
        WhitelistNFT storage wNFT = WhitelistNFTs[packedIdentifier];
        
        wNFT.description = _description;
        wNFT.isMultitoken = _isMultitoken;

        WhitelistNFTArray.push(packedIdentifier);
        bytesToIdx[packedIdentifier] = WhitelistNFTArray.length-1;
    }

    function Identifier (address _address, uint256 _tokenID) pure internal returns (bytes memory) {
        return abi.encode(_address, _tokenID);
    }

    function removeWhitelistNFT(address _address, uint256 _tokenID) public onlyRole(ADMIN) {
        bytes memory packedIdentifier = Identifier(_address, _tokenID);
        uint256 lastIdx = WhitelistNFTArray.length-1;
        uint256 curIdx = bytesToIdx[packedIdentifier];
        WhitelistNFTArray[curIdx] = WhitelistNFTArray[lastIdx];
        bytesToIdx[WhitelistNFTArray[curIdx]] = curIdx;
        WhitelistNFTArray.pop();
        delete bytesToIdx[packedIdentifier];
        delete WhitelistNFTs[packedIdentifier];
    }

    function getWhitelistNFT(address _address, uint256 _tokenID) public view returns (string memory, bool) {
        bytes memory packedIdentifier = Identifier(_address, _tokenID);
        return (WhitelistNFTs[packedIdentifier].description, WhitelistNFTs[packedIdentifier].isMultitoken);
    }

    function mint(uint256 _maxSupply, uint256 _initialSupply, string calldata tokenURI) public returns (uint256){
        require(canMint(_msgSender()));
        bytes memory _data = "0x";
        uint256 newTokenID = Collection.create(_maxSupply, _initialSupply, tokenURI, _data );
        Collection.safeTransferFrom(address(this), _msgSender(), newTokenID, _maxSupply, _data);
        emit Minted(newTokenID, msg.sender);
        return newTokenID;
    }

    function canMint(address _minter) public view returns (bool) {
        bool mintPass = false;

        if (WhitelistNFTArray.length == 0) return true;

        for (uint256 index=0; (!mintPass) && (index < WhitelistNFTArray.length); index++){
            address passERC;
            uint256 tokenID;
            (passERC, tokenID) = decodePackedIdentifier(WhitelistNFTArray[index]);
            if (WhitelistNFTs[WhitelistNFTArray[index]].isMultitoken) {
                IERC1155 pass = IERC1155(passERC);
                mintPass = (pass.balanceOf(_minter,tokenID) > 0);
            } else {
                IERC721 pass = IERC721(passERC);
                mintPass = (pass.balanceOf(_minter)>0);
            }
        }
        return mintPass;
    }

    function decodePackedIdentifier(bytes memory packedIdentifier) private pure returns (address, uint256){

        return abi.decode(packedIdentifier, (address, uint256));
    }
}
