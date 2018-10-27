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
const saveRasheedQuestLord = `0x3D01dDdB4eBD0b521f0E4022DCbeF3cb9bc20FF2`

contract(
  `QuestToken`,
  ([contractOwner, questCreator, questHero, questHero2]) => {
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
      this.questCost = 1000
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
        { from: questOwner }
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
      { from: owner }
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
        // console.log(`M0`, metadata0)
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

        // console.log(`M1`, metadata1)
        const index = await this.questLibrary.getTokenData(q1)
        index.should.be.bignumber.equal(0)
        const index2 = await this.questLibrary.getTokenData(q2)
        index2.should.be.bignumber.equal(1)
      })
    })
  }
)
