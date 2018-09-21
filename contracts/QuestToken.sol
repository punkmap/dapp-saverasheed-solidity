pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/token/ERC721/ERC721Token.sol";

/*
    A transferrable Quest that lets you store, transfer, 
    and access information associated to a quest named from 32 character string
*/
contract QuestToken is ERC721Token {

    mapping (uint256 => address) questTokenAddress;
    /*
        Constructs a Quest to store files 
    */
    constructor() 
        public 
        ERC721Token("IPFS Quest", "IQ")
    {
    }

    event QuestCreated(string quest, uint indexed questId, address indexed owner, string ipfs);

    /* 
        Takes a string and converts to binary uint
        This is to be used as the NFT key
        @param _s - string to convert to a uint256 integer
    */
    function encodeQuestId(string _s) 
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
        @param _data - the data to put in the Quest
    */
    function createQuest(
        string _quest,
        string _data
    )
        public
    {
        uint questId = encodeQuestId(_quest);
        if (!exists(questId)) {
            _mint(msg.sender, questId);
        }
        require (ownerOf(questId) == msg.sender, "Sender must own Quest to modify it");
        _setTokenURI(questId, _data);
        emit QuestCreated(_quest, questId, msg.sender, _data);
    }

    /* 
        Returns Quest contents
        @param _quest The Quest to inspect
    */
    function questData(
        string _quest
    )
        public
        view
        returns (string)
    {
        uint questId = encodeQuestId(_quest);
        return tokenURIs[questId];
    }

    /* 
        Returns Quest contents
        @param _questId The id of the Quest to inspect
    */
    function questDataFromQuestId(
        uint _questId
    )
    public view returns (string) {
        return tokenURIs[_questId];
    }
}