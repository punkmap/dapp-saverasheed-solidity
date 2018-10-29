const QuestLibrary = artifacts.require(`QuestLibrary.sol`)

contract(`QuestLibrary`, ([libOwner]) => {
  before(async () => {
    this.questLibrary = await QuestLibrary.new()
  })
  describe(`Encoding`, () => {
    it(`should be able to encode and decode the same string`, async () => {
      const encodeString = `12345678901234567890123456789012`
      const number = await this.questLibrary.encodeString(encodeString).should
        .be.fulfilled
      const decodedString = await this.questLibrary.decodeStr(number).should.be
        .fulfilled
      encodeString.should.be.equal(decodedString)
    })
  })
  describe(`Hero Token`, () => {
    it(`should be able to encode and decode hero token`, async () => {
      const td = `12341234`
      const qi = `1234`
      const ca = `12346`
      const v = `55`
      const token = await this.questLibrary.makeHeroToken(td, qi, ca, v).should.be
        .fulfilled

      const dtd = await this.questLibrary.getTokenData(token)
      const dqi = await this.questLibrary.getQuestIndex(token)
      const dca = await this.questLibrary.getTokenCategory(token)
      const dv = await this.questLibrary.getTokenVersion(token)

      dtd.should.be.bignumber.equal(td)
      dqi.should.be.bignumber.equal(qi)
      dca.should.be.bignumber.equal(ca)
      dv.should.be.bignumber.equal(v)
    })
  })
})
