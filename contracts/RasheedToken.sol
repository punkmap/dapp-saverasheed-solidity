pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/token/ERC721/ERC721Token.sol";

/*
    A transferrable Quest that lets you store, transfer, 
    and access information associated to a quest named from 32 character string
*/
contract RasheedToken is QuestToken {


    constructor(uint _supply, string questMetadata) 
      public 
      QuestToken("Rasheed Token", "RT", supply, questMetadata)
    {
    }

    function adjustSupply
    (
        uint _supply
    ) 
        public
        onlyOwner
    {
        supplyRemaining = _supply;
    }

    function createRasheedToken
    (
        uint256 _tokenId, 
        address _beneficiary,
        string _questData
    ) 
        public 
        onlyOwner
    {
        require(supplyRemaining > 0, "No more tokens");
        _mint(_beneficiary, _tokenId);
        _setTokenURI(_tokenId, _questData);
    }
}