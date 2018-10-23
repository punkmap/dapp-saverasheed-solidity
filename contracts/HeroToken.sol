pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/token/ERC721/ERC721MetadataMintable.sol";
import "openzeppelin-solidity/contracts/token/ERC721/ERC721Enumerable.sol";
import './QuestLibrary.sol';

/*
    The NFT Token for Quests
*/
contract HeroToken is ERC721MetadataMintable, ERC721Enumerable {

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
        uint192 tokenIndex,
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
        uint token = QuestLibrary.makeHeroToken(questIndex, tokenCategory, tokenVersion, tokenIndex);
        require(mintWithTokenURI(hero, token, proofs), "Cannot mint this token");
        return token;
    }



}