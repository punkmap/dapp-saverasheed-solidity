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
        Takes a converts binary int converts to string
        @param i - int to convert to a string
    */
    function decodeStr
    (
      uint binary
    ) 
      public pure 
      returns (string)
    {
        uint num = binary;
        bytes memory str = new bytes(32);
        uint8 newLen = 32;
        // get bytes
        for (uint8 i = 0; i < 32; i++) {
          byte val = byte(num/(uint(2)**(8*i)));
          if (val == 0) {
            newLen = i;
            break;
          }
          str[i] = val;
        }
        bytes memory retstr = new bytes(newLen);
        //reverse byte array 
        for (uint8 j = newLen; j > 0; j--) {
          retstr[j-1] = str[newLen - j];
        }
        return string(retstr);
    }

    /*
        Lets you pack some necessary info into a quest token
    */
    function makeHeroToken(uint32 questIndex, uint16 category, uint16 version, uint192 tokenData) 
        public pure
        returns (uint256)
    {
        uint256 a = questIndex * uint256(2) ** 224;
        uint256 b = category * uint256(2) ** 208;
        uint256 c = version * uint256(2) ** 192;

        return uint256(tokenData) | a | b | c;
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

    function getTokenData(uint questToken) 
        public pure
        returns (uint32)
    {
        return uint32(extractNBits(questToken, 192, 0));
    }

    /*
        Lets you extract n bits starting at any point in a uint256
        @param bigNum - The number to get bits from
        @param n - The number of bits to take
        @param starting - Where to start reading bits from
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