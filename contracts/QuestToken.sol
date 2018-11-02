pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/token/ERC721/ERC721Metadata.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/token/ERC721/ERC721Enumerable.sol";

import './HeroToken.sol';

/*
    The Quest contract stores Quests as NFTs
    It manages distribution of Quest Tokens according to the Quest owners
    Quest Owners are the oracles to their Quests!
*/
contract QuestToken is ERC721Enumerable, ERC721Metadata, Ownable {

    struct QuestMetadata {
        uint cost;
        uint64 start;
        uint64 end;
        uint32 supplyRemaining;
        uint32 repeatLimit;
        uint32 index;
        uint[] heroTokens;
        mapping (address => uint) heroQuestCompletions;
    }

    mapping (uint => QuestMetadata) public metadata; 
    HeroToken public heroToken;

    /*
        Constructs a Quest to store files 
    */
    constructor() 
        public 
        ERC721Metadata("Quest Token", "QT")
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
        string questData,
        address questLord
    )
        public
    {
        uint32 questNum = uint32(totalSupply());
        require (totalSupply() < questNum + 1, "Max Quest supply hit");
        uint32 supplyRemaining = tokenSupply;
        if (supplyRemaining == 0) {
          supplyRemaining -= 1; // set to maximum uint32 to create max supply of 4,294,967,296
        }
        QuestMetadata memory q = QuestMetadata(
            cost,
            questStart,
            questEnd,
            supplyRemaining,
            repeatLimit,
            questNum,
            new uint[](0)
        );
        _mint(questLord, questId);
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
      heroToken = HeroToken(tokenContract);
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
        @param questId - the quest identifier
        @param tokenCategory - which type of token are we minting
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
        // Validate completion possible
        require (msg.sender == ownerOf(questId), "Only quest owner can complete");
        QuestMetadata storage q = metadata[questId];   
        require (q.repeatLimit == 0 || q.heroQuestCompletions[hero] < q.repeatLimit, "Hero can complete quest up to limit");
        require (questInProgress(questId), "Quest must be in progress");
        
        // Mint token and update Quest Metadata
        uint32 index = q.index;
        uint token = heroToken.mint(uint192(numHeroTokens(questId)), hero, index,  0, tokenCategory, checkinProofs);
        q.heroQuestCompletions[hero] += 1;
        q.heroTokens.push(token);
        q.supplyRemaining -= 1;

        // If decentralized quest, remove reward
        _removePendingAndReward(questId, hero);
        emit QuestCompleted(questId, index, token, hero, checkinProofs);
        return token;
    }

    /* 
        Returns completion counts by quest
        @param questId - the quest
    */
    function numHeroTokens
    (
      uint questId
    ) 
      public view
      returns (uint)
    {
      return metadata[questId].heroTokens.length;
    }
    
    /* 
        Returns completion counts by quest by hero
        @param questId - the quest
        @param hero - return completion counts for the hero by quest
    */
    function numQuestCompletions
    (
      uint questId,
      address hero
    )
      public view
      returns (uint)
    {
      return metadata[questId].heroQuestCompletions[hero];
    }

    /* 
        Returns Hero tokens by index
        @param questId - the quest
        @param index - index into hero token array
    */
    function heroToken
    (
      uint questId,
      uint index
    ) 
      public view
      returns (uint)
    {
      return metadata[questId].heroTokens[index];
    }

    
    // Decentralized Quest submission and validation below

    struct Proof {
      address hero;
      string proof;
      uint value;
      uint blockNumber;
    }

    mapping (uint => mapping (address => Proof)) public pendingProofs; 
    mapping (uint => bool) public approvedForReclaiming; 
    mapping (uint => bool) public submittedProof; 
   
    event ApprovalToggled(uint questId, bool approved);
    event PendingProofSubmitted(uint questId, address hero, string proof);
    event PendingProofRefunded(uint questId, address hero);
    event PendingProofReclaimed(uint questId, address hero, uint value);
    event PendingProofCompleted(uint questId, address hero, uint value);

    /* 
      Removes pending proofs for quest and pays quest owner any pending value
      @param questId - the quest
      @param hero - who completed quest 
    */
    function _removePendingAndReward
    (
        uint questId,
        address hero
    ) 
      private
    {
      Proof memory p = pendingProofs[questId][hero];
      if (p.hero != address(0)) {
        // pay for cost of minting the token
        ownerOf(questId).transfer(p.value);  
        delete pendingProofs[questId][hero];
        emit PendingProofCompleted(questId, hero, p.value);
      }
    }

    /* 
        A hero can request refund on the contract
        @param questId - the quest to request refunds for
    */
    function requestRefund
    (
      uint questId
    )
        public
    {
        Proof storage p = pendingProofs[questId][msg.sender];
        require (p.hero == msg.sender, "Only hero can request refund");
        require (p.blockNumber + 50 < block.number, "At least 50 blocks must elapse");
        uint proofHash = uint(keccak256(abi.encodePacked(p.proof)));
        require (submittedProof[proofHash], "No pending proof to refund");

        msg.sender.transfer(p.value);
        
        // delete submitted proof and pending proof
        delete submittedProof[proofHash];
        delete pendingProofs[questId][msg.sender];

        emit PendingProofRefunded(questId, msg.sender);
    }

    /* 
        A hero can submit proofs that they completed a quest at any time
        @param questId - the quest to submit proofs for
        @param proofs - the IPFS hash of the proofs
    */
    function submitProofs(
        uint questId,
        string proofs
    )
        public
        payable
    {
        QuestMetadata storage q = metadata[questId];
        require (_exists(questId), "quest must exist");
        require (q.cost <= msg.value, "Incorrect value passed");
        require (q.repeatLimit == 0 || q.heroQuestCompletions[msg.sender] < q.repeatLimit, "Over repeat limit");
        require (questInProgress(questId), "Quest must be in progress");
        uint proofHash = uint(keccak256(abi.encodePacked(proofs)));
        require (submittedProof[proofHash] == false, "Identicle proof submitted");
        require (pendingProofs[questId][msg.sender].hero == address(0), "One pending proof per quest");
        submittedProof[proofHash] = true;
        // add pending proof
        pendingProofs[questId][msg.sender] = Proof(msg.sender, proofs, msg.value, block.number);
        emit PendingProofSubmitted(questId, msg.sender, proofs);
    }

    /* 
        Approve the owner to reclaim lost funds on the contract and distribute accordingly
        @param questId - the quest
        @param isApproved - toggle on/off approval for the owner to reclaim
    */
    function approveReclaiming
    (
      uint questId,
      bool isApproved
    )
      public
    {
      require (msg.sender == ownerOf(questId), "Only quest owner can approve/disapprove reclaiming");
      approvedForReclaiming[questId] = isApproved;
      emit ApprovalToggled(questId, isApproved);
    }



    /* 
        Only owner can reclaim lost funds if approved to do so
        @param questId - the quest
        @param wallet - which wallet to reclaim funds for
    */
    function reclaimLostProofs
    (
      uint questId,
      address wallet
    )
        public
        onlyOwner
    {
        require (msg.sender == ownerOf(questId) || approvedForReclaiming[questId] == true, "must be approved by quest owner");
        Proof storage p = pendingProofs[questId][wallet];
        require (p.hero == wallet && p.hero != address(0), "Wallet has no pending proofs");
        owner().transfer(p.value);
        delete pendingProofs[questId][wallet];
        uint proofHash = uint(keccak256(abi.encodePacked(p.proof)));
        delete submittedProof[proofHash];
        emit PendingProofReclaimed(questId, wallet, p.value);
    }

}