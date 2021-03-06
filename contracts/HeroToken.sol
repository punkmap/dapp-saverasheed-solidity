pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/token/ERC721/ERC721Metadata.sol";
import "openzeppelin-solidity/contracts/token/ERC721/ERC721Enumerable.sol";
import "openzeppelin-solidity/contracts/access/roles/MinterRole.sol";
import './QuestLibrary.sol';

/*
    The NFT Token for Quests
*/
contract HeroToken is ERC721Enumerable, ERC721Metadata, MinterRole {

    /*
        Constructs a Quest to store files
        @param questContract - the Owner Contract has rules to mint tokens
    */
    constructor(address questContract) 
        public 
        ERC721Metadata("Hero Token", "HT")
    {
        addMinter(questContract);
    }

    /* 
        The owner of QuestTokens is the only one who can create new tokens based on the rules of the 
        latest Quest Contract
        @param hero - who receives the token
        @param questIndex - Which quest by index (quest id doesn't fit)
        @param proofs - the proof of successful completion of the quest
    */
    function mint(
        uint192 tokenData,
        address hero,
        uint32 questIndex,
        uint16 tokenVersion,
        uint16 tokenCategory,
        string proofs
    )
        public
        onlyMinter
        returns (uint)
    {
        uint token = QuestLibrary.makeHeroToken(tokenData, questIndex, tokenCategory, tokenVersion);
        _mint(hero, token);
        _setTokenURI(token, proofs);
        return token;
    }



}