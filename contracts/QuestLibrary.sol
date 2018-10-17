pragma solidity ^0.4.24;

library QuestLibrary {
    /* 
        Takes a string and converts to binary uint
        This is to be used as the NFT key
        @param str - string to convert to a uint256 integer
    */
    function encodeString(string str) 
        external 
        pure 
        returns (uint) 
    {
        require(bytes(str).length <= 32, "String must be less 32 bytes");

        bytes memory b = bytes(str);
        uint number = 0;
        for (uint i = 0; i < b.length; i++) {
            number = number + uint(b[i])*(uint(2)**(8*(uint(b.length)-(i+1))));
        }
        return number;
    }

    /*
        Lets you pack and arrange a uint256 with uint32 and uint224
    */
    function makeQuestToken(uint32 questIndex, uint16 category, uint16 version, uint192 tokenIndex) 
        public pure
        returns (uint256)
    {
        uint256 a = questIndex * uint256(2) ** 224;
        uint256 b = category * uint256(2) ** 208;
        uint256 c = version * uint256(2) ** 192;

        return uint256(tokenIndex) | a | b | c;
    }

    function getQuestIndex(uint questToken) 
        public pure
        returns (uint32)
    {
        return uint32(extractNBits(questToken, 32, 224));
    }

    function getTokenVersion(uint questToken) 
        public pure
        returns (uint32)
    {
        return uint32(extractNBits(questToken, 16, 192));
    }

    function getTokenCategory(uint questToken) 
        public pure
        returns (uint32)
    {
        return uint32(extractNBits(questToken, 16, 208));
    }

    function getTokenIndex(uint questToken) 
        public pure
        returns (uint32)
    {
        return uint32(extractNBits(questToken, 192, 0));
    }

    /*
        Lets you extract n bits starting at any point in a uint256
    */
    function extractNBits(
        uint256 bigNum, 
        uint8 n,
        uint8 starting
    )
        public pure
        returns (uint256) 
    {
        uint256 leftShift = bigNum * (uint256(2) ** uint256(256-n-starting));
        uint256 rightShift = leftShift / (uint256(2) ** uint256(256-n));
        return rightShift;
    }

}