const Quest = artifacts.require(`Quest.sol`)
const QuestLibrary = artifacts.require(`QuestLibrary.sol`)
const QuestToken = artifacts.require(`QuestToken.sol`)

function deployLibraries(deployer) {
  return deployer.deploy([QuestLibrary]).then(() => {
    return deployer.link(QuestLibrary, [Quest])
  })
}

const saveRasheedQuestId = '25805080724369420902507832676'

module.exports = function(deployer, network, [owner1]) {
  console.log('Owner', owner1)
  return deployLibraries(deployer)
    .then(() => {
      return deployer.deploy(Quest, { from: owner1 })
    })
    .then(() => {
      return deployer.deploy(QuestToken, Quest.address, { from: owner1 })
    })
    .then(() => {
      return Quest.deployed()
    })
    .then(async quest => {
      await quest.setTokenContract(QuestToken.address, { from: owner1 })
      return quest.createQuest(
        saveRasheedQuestId,
        0,
        0,
        0,
        400,
        1,
        'QmUC7j9U8jAm6GzymtobvZZ7zs4XEUtSaaZAayXLL66E71',
        { from: owner1 },
      )
    })
    .catch(err => {
      console.log('Problem Deploying', err)
    })
}
