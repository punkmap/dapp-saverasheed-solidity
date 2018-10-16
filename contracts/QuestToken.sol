pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/token/ERC721/ERC721Token.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";

/*
    A transferrable Quest that lets you store, transfer, 
    and access information associated to a quest named from 32 character string
*/
contract QuestToken is ERC721Token, Ownable {

    /*
        Constructs a Quest to store files 
    */
    constructor(address questContract) 
        public 
        ERC721Token("Quest Token", "QT")
    {
        owner = questContract;
    }
    
    /* 
        An oracle can complete quest after validating the proof from the hero
        @param tokenId - the token ot be generated.
        @param checkinProofs - the proof of successful completion of the quest
    */
    function mint(
        uint tokenId,
        address hero,
        string checkinProofs
    )
        public
        onlyOwner
    {
        // TODO - generate token with quest index
        _mint(hero, tokenId);
        _setTokenURI(tokenId, checkinProofs);
    }

    /* 
        Returns Quest Token contents
        @param tokenId The id of the token to inspect
    */
    function tokenData
    (
        uint tokenId
    )
        public view 
        returns (string) 
    {
        return tokenURIs[tokenId];
    }

}