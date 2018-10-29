
const QuestLibrary = artifacts.require(`QuestLibrary.sol`)

contract(`QuestLibrary`, ([libOwner]) => {
  before(async () => {
    this.questLibrary = await QuestLibrary.new()
  })
  describe.only(`Encoding`, () => {
    it(`should be able to encode and decode the same string`, async () => {
      const encodeString = `12345678901234567890123456789012`
      const number = await this.questLibrary.encodeString(encodeString).should.be.fulfilled
      const decodedString = await this.questLibrary.decodeStr(number).should.be.fulfilled
      encodeString.should.be.equal(decodedString)
    })
  })
})
