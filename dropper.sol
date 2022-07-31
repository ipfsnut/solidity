// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/* Steps to deploy and run

    1. Compile and deploy this contract, save its address
    2. Call setApprovalForAll on target contract: RDME - 0x931204Fb8CEA7F7068995dcE924F0d76d571DF99
        setApprovalForAll( operator=THIS_CONTRACT_ADDRESS, approved=true )
    3. Call AirdropToken on this contract
        AirdropToken ( 
            _recipient = ["0x1stAddy","0x2ndAddy"], 
            _collection = "0x931204Fb8CEA7F7068995dcE924F0d76d571DF99",
            _tokenID = TOKEN_ID_YOU_WANT_TO_DROP )
    
        Note: this function only sends one of the tokens to each recipient

*/

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

contract CommunityAirdrop is AccessControl, ERC1155Holder {
    bytes32 public constant ADMIN = keccak256("ADMIN");

    event Airdrop(
        uint256 indexed tokenID,
        address sender,
        address receiver
    );

    constructor () {
        _setupRole(ADMIN, _msgSender());
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155Receiver, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function AirdropToken(address[] calldata _recipient, address _collection, uint256 _tokenID) public onlyRole(ADMIN){
        IUniftyERC1155 Collection = IUniftyERC1155(_collection);
        bytes memory _data = "0x";

        for(uint i = 0; i< _recipient.length; i++)
        {
            Collection.safeTransferFrom(_msgSender(), _recipient[i], _tokenID, 1, _data);
            emit Airdrop(_tokenID, _msgSender(), _recipient[i]);
        }
    }

}
