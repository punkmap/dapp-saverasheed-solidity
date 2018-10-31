const {
  duration,
  latest,
  increase
} = require(`openzeppelin-solidity/test/helpers/time`)
const {
  advanceBlock
} = require(`openzeppelin-solidity/test/helpers/advanceToBlock`)
const QuestToken = artifacts.require(`QuestToken.sol`)
const QuestLibrary = artifacts.require(`QuestLibrary.sol`)
const HeroToken = artifacts.require(`HeroToken.sol`)
const BigNumber = web3.BigNumber

const should = require(`chai`)
  .use(require(`chai-as-promised`))
  .use(require(`chai-bignumber`)(BigNumber))
  .should()

const saveRasheedQuestId = `3430083573232153044767320670749830693485949750982054416035926456`
const saveRasheedQuestIPFS = `QmVLGZhFZNACQfBZFUPgMvsXU7PiDnSBqgt7ob4AusXPuY`
const saveRasheedQuestIPFS1 = `QmVLGZhFZNACQfBZFUPgMvsXU7PiDnSBqgt7ob4AusXPud`

contract(
  `QuestToken`,
  ([contractOwner, questCreator, questCreator2, questHero, questHero2]) => {
    before(async () => {
      this.questLibrary = await QuestLibrary.new()
    })
    beforeEach(async () => {
      this.questToken = await QuestToken.new({ from: contractOwner })
      this.heroToken = await HeroToken.new(this.questToken.address, {
        from: contractOwner
      })
      await this.questToken.setTokenContract(this.heroToken.address)
      this.startTime = await latest()
      this.afterStart = this.startTime + duration.seconds(1)
      this.duration = duration.weeks(2)
      this.endTime = this.startTime + this.duration
      this.questCost = 10000000000000
      this.questSupply = 1
      this.repeatLimit = 1
    })

    const createQuest = (questOwner = questCreator) => this.questToken
      .createQuest(
        saveRasheedQuestId,
        this.questCost,
        this.startTime,
        this.endTime,
        this.questSupply,
        this.repeatLimit,
        saveRasheedQuestIPFS,
        questOwner,
        { from: questOwner, gasPrice: 0 }
      )
      .then(async () => increase(duration.seconds(1)))

    const printQuestOwner = async () => {
      const qowner = await this.questToken.ownerOf(saveRasheedQuestId)
      console.log(`Quest owner`, qowner)
      return true
    }
    const completeQuest = async (hero, owner = questCreator) => this.questToken.completeQuest(
      saveRasheedQuestId,
      1,
      hero,
      saveRasheedQuestIPFS,
      { from: owner, gasPrice: 0 }
    )

    describe(`Quest Creation`, () => {
      it(`should enable anyone to create a quest`, async () => {
        await createQuest(contractOwner).should.be.fulfilled
        const metadata = await this.questToken.metadata(saveRasheedQuestId)
        // console.log(`Metadata returned`, metadata)
        metadata[0].should.be.bignumber.equal(this.questCost)
        metadata[1].should.be.bignumber.equal(this.startTime)
        metadata[2].should.be.bignumber.equal(this.endTime)
        metadata[3].should.be.bignumber.equal(this.questSupply)
        metadata[4].should.be.bignumber.equal(this.repeatLimit)
        metadata[5].should.be.bignumber.equal(0)
      })

      it(`cannot be created twice`, async () => {
        await createQuest(questCreator).should.be.fulfilled
        await createQuest(questCreator).should.not.be.fulfilled
      })

      it(`should be in progress`, async () => {
        await createQuest(questCreator).should.be.fulfilled

        const inProgress = await this.questToken.questInProgress(
          saveRasheedQuestId
        )
        await increase(duration.seconds(2))

        inProgress.should.equal(true)
        await increase(this.duration)
        const newInProgress = await this.questToken.questInProgress(
          saveRasheedQuestId
        )
        newInProgress.should.equal(false)
      })
    })

    describe(`Quest Completion`, () => {
      it(`should allow completion`, async () => {
        await createQuest(questCreator).should.be.fulfilled
        await completeQuest(questHero).should.be.fulfilled
      })
      it(`should not allow completion by non-quest owner`, async () => {
        await createQuest(questCreator).should.be.fulfilled
        await completeQuest(questHero, contractOwner).should.not.be.fulfilled
      })
      it(`should not completion over quest supply`, async () => {
        this.repeatLimit = 2
        this.questSupply = 2
        await createQuest(questCreator).should.be.fulfilled
        await completeQuest(questHero).should.be.fulfilled
        await completeQuest(questHero).should.be.fulfilled
        await completeQuest(questHero).should.not.be.fulfilled
      })
      it(`should not completion over repeat limit`, async () => {
        this.repeatLimit = 1
        this.questSupply = 2
        await createQuest(questCreator).should.be.fulfilled
        await completeQuest(questHero).should.be.fulfilled
        await completeQuest(questHero).should.not.be.fulfilled
      })
      it(`should not completion when quest ends`, async () => {
        await createQuest(questCreator).should.be.fulfilled
        await increase(this.duration)
        await completeQuest(questHero).should.not.be.fulfilled
      })
      it(`should track number of hero tokens and hero completions`, async () => {
        this.repeatLimit = 2
        this.questSupply = 4
        await createQuest(questCreator).should.be.fulfilled
        await completeQuest(questHero).should.be.fulfilled
        await completeQuest(questHero).should.be.fulfilled

        await completeQuest(questHero2, questCreator).should.be.fulfilled
        // console.log(`asdf`, p1, p2, p3)

        const numTokens = await this.questToken.numHeroTokens(
          saveRasheedQuestId
        )
        numTokens.should.be.bignumber.equal(3)
        const hero1Tokens = await this.questToken.numQuestCompletions(
          saveRasheedQuestId,
          questHero
        )
        hero1Tokens.should.be.bignumber.equal(2)
        const hero2Tokens = await this.questToken.numQuestCompletions(
          saveRasheedQuestId,
          questHero2
        )
        hero2Tokens.should.be.bignumber.equal(1)
      })
      it(`should be able to read and decifer hero token`, async () => {
        this.repeatLimit = 2
        this.questSupply = 4
        await createQuest(questCreator).should.be.fulfilled
        const params1 = [
          saveRasheedQuestId,
          1,
          questHero,
          saveRasheedQuestIPFS,
          { from: questCreator }
        ]
        const params2 = [
          saveRasheedQuestId,
          1,
          questHero,
          saveRasheedQuestIPFS,
          { from: questCreator }
        ]
        const q1 = await this.questToken.completeQuest.call(...params1)
        await this.questToken.completeQuest(...params1)
        const q2 = await this.questToken.completeQuest.call(...params2)
        await this.questToken.completeQuest(...params2)

        const index = await this.questLibrary.getTokenData(q1)
        index.should.be.bignumber.equal(0)
        const index2 = await this.questLibrary.getTokenData(q2)
        index2.should.be.bignumber.equal(1)
      })
    })
    describe(`decentralized quests`, () => {
      beforeEach(async () => {
        await createQuest().should.be.fulfilled
      })
      it(`should accept up to one pending proof`, async () => {
        const params = [
          saveRasheedQuestId,
          saveRasheedQuestIPFS,
          { from: questHero, value: this.questCost }
        ]
        const params1 = [
          saveRasheedQuestId,
          saveRasheedQuestIPFS,
          { from: questHero2, value: this.questCost }
        ]
        await this.questToken.submitProofs(...params).should.be.fulfilled
        await this.questToken.submitProofs(...params1).should.not.be.fulfilled
      })
      it(`should not allow identical proofs`, async () => {
        const params = [
          saveRasheedQuestId,
          saveRasheedQuestIPFS,
          { from: questHero, value: this.questCost }
        ]
        const params1 = [
          saveRasheedQuestId,
          saveRasheedQuestIPFS,
          { from: questHero2, value: this.questCost }
        ]
        await this.questToken.submitProofs(...params).should.be.fulfilled
        await this.questToken.submitProofs(...params1).should.not.be.fulfilled
      })
      it(`should allow different proofs from different heros`, async () => {
        const params = [
          saveRasheedQuestId,
          saveRasheedQuestIPFS,
          { from: questHero, value: this.questCost }
        ]
        const params1 = [
          saveRasheedQuestId,
          saveRasheedQuestIPFS1,
          { from: questHero2, value: this.questCost }
        ]
        await this.questToken.submitProofs(...params).should.be.fulfilled
        await this.questToken.submitProofs(...params1).should.be.fulfilled
        const pending = await this.questToken.pendingProofs.call(
          saveRasheedQuestId,
          questHero
        )
        const pending2 = await this.questToken.pendingProofs.call(
          saveRasheedQuestId,
          questHero2
        )
        pending[1].should.be.equal(saveRasheedQuestIPFS)
        pending2[1].should.be.equal(saveRasheedQuestIPFS1)
      })
      it(`should pay quest owner for validating proofs`, async () => {
        const balance = await web3.eth.getBalance(questCreator)

        const params = [
          saveRasheedQuestId,
          saveRasheedQuestIPFS,
          { from: questHero, value: this.questCost }
        ]
        await this.questToken.submitProofs(...params).should.be.fulfilled
        await completeQuest(questHero).should.be.fulfilled
        const balance1 = await web3.eth.getBalance(questCreator)
        balance.should.be.bignumber.equal(balance1.minus(this.questCost))
      })

      it(`should allow refunds on submitted proofs after 50 blocks`, async () => {
        const params = [
          saveRasheedQuestId,
          saveRasheedQuestIPFS,
          { from: questHero, value: this.questCost }
        ]
        await this.questToken.submitProofs(...params).should.be.fulfilled
        await this.questToken.requestRefund(saveRasheedQuestId, {
          from: questHero
        }).should.not.be.fulfilled
        const promises = Array(52)
          .fill()
          .map(_ => advanceBlock())
        await Promise.all(promises)
        const balance = await web3.eth.getBalance(questHero)
        await this.questToken.requestRefund(saveRasheedQuestId, {
          from: questHero,
          gasPrice: 0
        }).should.be.fulfilled
        const balance1 = await web3.eth.getBalance(questHero)
        balance.should.be.bignumber.equal(balance1.minus(this.questCost))
      })

      it(`can approve reclaiming by only quest owner`, async () => {
        const params = [
          saveRasheedQuestId,
          saveRasheedQuestIPFS,
          { from: questHero, value: this.questCost }
        ]
        await this.questToken.submitProofs(...params).should.be.fulfilled
        await this.questToken.approveReclaiming(saveRasheedQuestId, true, {
          from: questCreator2
        }).should.not.be.fulfilled

        await this.questToken.reclaimLostProofs(saveRasheedQuestId, questHero, {
          from: contractOwner,
          gasPrice: 0
        }).should.not.be.fulfilled

        await this.questToken.approveReclaiming(saveRasheedQuestId, true, {
          from: questCreator
        }).should.be.fulfilled

        const balance = await web3.eth.getBalance(contractOwner)
        await this.questToken.reclaimLostProofs(saveRasheedQuestId, questHero, {
          from: contractOwner,
          gasPrice: 0
        }).should.be.fulfilled
        const balance1 = await web3.eth.getBalance(contractOwner)
        balance.should.be.bignumber.equal(balance1.minus(this.questCost))

        await this.questToken.approveReclaiming(saveRasheedQuestId, false, {
          from: questCreator
        }).should.be.fulfilled
        await this.questToken.reclaimLostProofs(saveRasheedQuestId).should.not
          .be.fulfilled
      })
    })
  }
)
