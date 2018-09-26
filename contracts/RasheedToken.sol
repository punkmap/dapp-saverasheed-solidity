pragma solidity ^0.4.24;

import "./QuestToken.sol";
import "openzeppelin-solidity/contracts/token/ERC721/ERC721Token.sol";

/*
    Rasheed Token are tokens issued for completing the Save Rasheed quest!
    see saverasheed.com
*/
contract RasheedToken is QuestToken {

    mapping (uint => bool) redeemed;
    uint numberRedeemed = 0;

    constructor(string _questMetadata, uint _supply) 
      public 
      QuestToken("Rasheed Token", "RT", _questMetadata, _supply)
    {
    }

    function addSupply
    (
        uint _supply
    ) 
        public
        onlyOwner
    {
        supplyRemaining += _supply;
    }


    function redeemToken
    (
        uint _tokenId
    )
        public
    {
        require(msg.sender == owner || msg.sender == ownerOf(_tokenId), "Only redeemable by token owner or contract owner");
        require (!redeemed[_tokenId], "Cannot redeem token already redeemed");
        redeemed[_tokenId] = true;
        numberRedeemed++;
    }
    
}