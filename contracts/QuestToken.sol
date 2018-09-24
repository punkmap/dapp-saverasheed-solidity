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
    constructor(_name, _symbol, _supply, _questMetadata) 
        public 
        ERC721Token(_name, _symbol)
    {
        supplyRemaining = _supply;
        questMetadata = _questMetadata;
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
        Mints a token with associated data and assigns ownership
        @param _quest - the Name of the Quest to store
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
        uint rewardToken = encodeTokenId(_tokenGenetics);
        _mint(_hero, rewardToken);
        _setTokenURI(rewardToken, _proof);
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