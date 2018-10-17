pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/token/ERC721/ERC721Token.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import './QuestToken.sol';
import './QuestLibrary.sol';

/*
    A transferrable Quest that lets you store, transfer, 
    and access information associated to a quest named from 32 character string
*/
contract Quest is ERC721Token, Ownable {

    struct QuestMetadata {
        uint cost;
        uint64 start;
        uint64 end;
        uint32 index;
        uint32 supplyRemaining;
        uint32 repeatLimit;
        mapping (address => uint32) completionCounts;
    }

    mapping (uint => QuestMetadata) public metadata; 
    mapping (uint  => uint[]) public questTokens; 
    QuestToken public token;

    /*
        Constructs a Quest to store files 
    */
    constructor() 
        public 
        ERC721Token("Quest", "Q")
    {
    }

    event QuestCreated(uint questId, uint32 questIndex, uint32 tokenSupply, uint cost, string questData);
    event QuestCompleted(uint questId, uint32 questIndex, uint token, address hero,  string proof);

    function createQuest
    (
        uint questId,
        uint cost,
        uint64 questStart,
        uint64 questEnd,
        uint32 tokenSupply,
        uint32 repeatLimit,
        string questData
    )
        public
    {
        uint32 questNum = uint32(totalSupply());
        uint32 supplyRemaining = tokenSupply;
        if (supplyRemaining == 0) {
          supplyRemaining -= 1; // set to maximum uint32 to create max supply of 4,294,967,296
        }
        QuestMetadata memory q = QuestMetadata(
            cost,
            questStart,
            questEnd,
            questNum,
            supplyRemaining,
            repeatLimit
        );
        _mint(msg.sender, questId);
        _setTokenURI(questId, questData);
        metadata[questId] = q;
        emit QuestCreated(questId, questNum, tokenSupply, cost, questData);
    }

    function setTokenContract
    (
      address tokenContract
    )
      public
      onlyOwner
    {
      token = QuestToken(tokenContract);
    }

    /*
        Quest cannot be ongoing if there's no more supply or a start time or end time have been specified
    */
    function questInProgress
    (
        uint questId
    )
        public view
        returns (bool)
    {
        QuestMetadata memory q = metadata[questId];
        bool started = now > q.start;
        bool notEnded = q.end == 0 || now < q.end;

        return (q.supplyRemaining > 0 && started && notEnded);
    }

    /* 
        An oracle can complete quest after validating the proof from the hero
        @param questToken - the token linking quest to token stats
        @param hero - Who will receive the token if all is well
        @param checkinProofs - the proof of successful completion of the quest
    */
    function completeQuest(
        uint questId,
        uint16 tokenCategory,
        address hero,
        string checkinProofs
    )
        public
        returns (uint)
    {
        require (msg.sender == ownerOf(questId), "Only quest owner can complete quests");
        QuestMetadata storage q = metadata[questId];
        
        require (q.index < totalSupply(), "Invalid quest index passed");
        require (q.repeatLimit == 0 || q.completionCounts[hero] < q.repeatLimit, "Hero may only complete quest up to repeat count.");
        require (q.supplyRemaining > 0, "There must be available tokens remaining.");
        
        uint count = numQuestTokens(questId);
        uint questToken = QuestLibrary.makeQuestToken(q.index, tokenCategory, 0, uint192(count));
        questTokens[questId].push(questToken);

        token.mint(questToken, hero, checkinProofs);
        q.supplyRemaining -= 1;
        q.completionCounts[hero] += 1;
        _completePendingQuest(questId, hero);
        emit QuestCompleted(questId, q.index, questToken, hero, checkinProofs);
        return questToken;
    }

    function numQuestTokens
    (
      uint questId
    ) 
      public view
      returns (uint)
    {
      return questTokens[questId].length;
    }
    
    // Decentralized Quest submission and validation below

    struct Proof {
      address hero;
      string proof;
      uint value;
    }

    mapping (uint => mapping (address => Proof)) public pendingProofs; 
    mapping (uint => bool) public approvedForReclaiming; 
   
    event PendingProofSubmitted(uint questId, address hero, string proof);
    event PendingProofRefunded(uint questId, address hero);
    event PendingProofReclaimed(uint questId, address hero, uint value);
    event PendingProofCompleted(uint questId, address hero, uint value);

    function _completePendingQuest
    (
        uint questId,
        address hero
    ) 
      private
    {
      Proof memory p = pendingProofs[questId][hero];
      if (p.hero != address(0)) {
        ownerOf(questId).transfer(p.value);  // pay for cost of minting the token
        delete pendingProofs[questId][hero];
        emit PendingProofCompleted(questId, hero, p.value);
      }
    }

    function requestRefund
    (
      uint questId
    )
        public
    {
        Proof storage p = pendingProofs[questId][msg.sender];
        require (p.hero == msg.sender, "Only hero can request refund");
        address(this).transfer(p.value);
        delete pendingProofs[questId][msg.sender];
        emit PendingProofRefunded(questId, msg.sender);
    }

    /* 
        A hero can submit proofs that they completed a quest at any time
        @param questId - the quest to submit proofs for
        @param checkinProofs - the IPFS hash of the proofs
    */
    function submitProofs(
        uint questId,
        string proofs
    )
        public
        payable
    {
        QuestMetadata storage q = metadata[questId];
        require (exists(questId), "quest must exist");
        require (q.cost <= msg.value, "must pass value greater than cost of quest");
        require (q.repeatLimit == 0 || q.completionCounts[msg.sender] < q.repeatLimit, "Hero may only complete quest up to repeat count.");
        require (q.supplyRemaining > 0, "There must be available tokens remaining.");
        pendingProofs[questId][msg.sender] = Proof(msg.sender, proofs, msg.value);
        emit PendingProofSubmitted(questId, msg.sender, proofs);
    }

    function approveReclaiming
    (
      uint questId,
      bool isApproved
    )
      public
    {
      require (msg.sender == ownerOf(questId), "Only quest owner can approve/disapprove reclaiming");
      approvedForReclaiming[questId] = isApproved;
    }

    function reclaimLostProofs
    (
      uint questId,
      address wallet
    )
        public
        onlyOwner
    {
        require (approvedForReclaiming[questId] == true, "owner must be approved by quest owner for reclaiming");
        Proof storage p = pendingProofs[questId][wallet];
        require (p.hero == wallet, "Wallet to be reclaimed must have pending proofs");
        owner.transfer(p.value);
        delete pendingProofs[questId][wallet];
        emit PendingProofReclaimed(questId, wallet, p.value);
    }
}