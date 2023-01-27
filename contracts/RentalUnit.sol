//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

// The RentalUnit is a NFT
contract RentalUnit is ERC721URIStorage {
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds; 

  // name and abbreviation
  constructor() ERC721("RentalUnit", "RU") {}

  // 1. Minting is the process in which a transaction is validated on 
  //    the blockchain to create a new asset, with that asset being an NFT. 
  // 2. The msg.sender is the address that has called or initiated a function or 
  //    created a transaction. Now, this address could be of a contract or even 
  //    a person like you and me.
  function mint(string memory tokenURI) public returns(uint256) {
    _tokenIds.increment();

    uint256 newItemId = _tokenIds.current();
    _safeMint(msg.sender, newItemId);
    _setTokenURI(newItemId, tokenURI);

    return newItemId;
  }

  function totalSupply() public view returns (uint256) {
    return _tokenIds.current();
  } 
}
