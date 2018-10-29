const {
  duration,
  latest,
  increase
} = require(`openzeppelin-solidity/test/helpers/time`)
const {
  advanceBlock
} = require(`openzeppelin-solidity/test/helpers/advanceToBlock`)
const QuestLibrary = artifacts.require(`QuestLibrary.sol`)
const HeroToken = artifacts.require(`HeroToken.sol`)
const BigNumber = web3.BigNumber
const QuestToken = artifacts.require(`QuestToken.sol`)

const should = require(`chai`)
  .use(require(`chai-as-promised`))
  .use(require(`chai-bignumber`)(BigNumber))
  .should()

contract(`HeroToken`, ([contractOwner, hero1]) => {
  beforeEach(async () => {
    this.questToken = await QuestToken.new({ from: contractOwner })
    this.heroToken = await HeroToken.new(this.questToken.address, {
      from: contractOwner
    })
    this.questLibrary = await QuestLibrary.new()
    this.questIndex = 1
    this.tokenCategory = 2
    this.checkinProofs = `asdf`
    this.tokenVersion = 4
  })
  const mintAToken = tokenIndex => this.heroToken.mint(
    tokenIndex,
    hero1,
    this.questIndex,
    this.tokenVersion,
    this.tokenCategory,
    this.checkinProofs,
    { from: contractOwner }
  ).should.be.fulfilled
  const mintATokenCall = tokenIndex => this.heroToken.mint.call(
    tokenIndex,
    hero1,
    this.questIndex,
    this.tokenVersion,
    this.tokenCategory,
    this.checkinProofs,
    { from: contractOwner }
  )
  describe(`Token Minting`, () => {
    it(`should mint a diff token for each new index passed`, async () => {
      const token = await mintATokenCall(0)
      await mintAToken(0)
      const token1 = await mintATokenCall(1)
      await mintAToken(1)
      token.should.be.bignumber.not.equal(token1)
    })
    it(`should be able to pull out params from minted token`, async () => {
      const tokenIndex = 4
      const token = await mintATokenCall(tokenIndex)
      await mintAToken(tokenIndex)
      const qi = await this.questLibrary.getQuestIndex(token)
      qi.should.be.bignumber.equal(this.questIndex)
      const qv = await this.questLibrary.getTokenVersion(token)
      qv.should.be.bignumber.equal(this.tokenVersion)
      const tc = await this.questLibrary.getTokenCategory(token)
      tc.should.be.bignumber.equal(this.tokenCategory)
      const ti = await this.questLibrary.getTokenData(token)
      ti.should.be.bignumber.equal(tokenIndex)
    })
    it(`should return correct token uri`, async () => {
      const tokenIndex = 4
      const token = await mintATokenCall(tokenIndex)
      await mintAToken(tokenIndex)
      const tokenAt0 = await this.heroToken.tokenByIndex.call(0)
      const uri = await this.heroToken.tokenURI.call(tokenAt0)
      const uri2 = await this.heroToken.tokenURI.call(token)
      uri.should.be.equal(this.checkinProofs)
      uri2.should.be.equal(this.checkinProofs)
    })
  })
})
