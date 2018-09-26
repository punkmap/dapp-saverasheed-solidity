pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/token/ERC721/ERC721Token.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";

/*
    A transferrable Quest that lets you store, transfer, 
    and access information associated to a quest named from 32 character string
*/
contract QuestToken is ERC721Token, Ownable {

    // IPFS hash representing metadata for this quest
    string public questMetadata;

    // Number of tokens to issue for addresses that complete the quest
    uint public supplyRemaining;

    /*
        Constructs a Quest to store files 
    */
    constructor(string _name, string _symbol, string _metadata, uint _supply) 
        public 
        ERC721Token(_name, _symbol)
    {
        supplyRemaining = _supply;
        questMetadata = _metadata;
    }

    event QuestCompleted(address hero, uint rewardToken, string proof);

    /* 
        Takes a string and converts to binary uint
        This is to be used as the NFT key
        @param _s - string to convert to a uint256 integer
    */
    function encodeTokenId(string _s) 
        public 
        pure 
        returns (uint) 
    {
        require(bytes(_s).length < 32, "String must be less than 32 bytes");

        bytes memory b = bytes(_s);
        uint number = 0;
        for (uint i = 0; i < b.length; i++) {
            number = number + uint(b[i])*(2**(8*(b.length-(i+1))));
        }
        return number;
    }

    /* 
        The oracle or owner wallet can complete quest after validating the proof from the hero
        @param _tokenGenetics - the token ot be generated.
        @param _proof - the proof of successful completion of the quest
    */
    function completeQuest(
        address _hero,
        string _tokenGenetics,
        string _proof
    )
        onlyOwner
        public
    {
        require (balanceOf(_hero) == 0, "Hero may only complete quest once.");
        require (supplyRemaining > 0, "There must be available tokens remaining.");
        uint rewardToken = encodeTokenId(_tokenGenetics);
        _mint(_hero, rewardToken);
        _setTokenURI(rewardToken, _proof);
        supplyRemaining -= 1;
        emit QuestCompleted(_hero, rewardToken, _proof);
    }

    /* 
        Returns Token contents
        @param _tokenGenetics the string value of the token
    */
    function tokenData(
        string _tokenGenetics
    )
        public
        view
        returns (string)
    {
        uint tokenId = encodeTokenId(_tokenGenetics);
        return tokenURIs[tokenId];
    }

    /* 
        Returns Quest Token contents
        @param _tokenId The id of the token to inspect
    */
    function tokenDataFromId(
        uint _tokenId
    )
    public view returns (string) {
        return tokenURIs[_tokenId];
    }
}