const QuestToken = artifacts.require(`QuestToken.sol`)
const QuestLibrary = artifacts.require(`QuestLibrary.sol`)
const HeroToken = artifacts.require(`HeroToken.sol`)

function deployLibraries(deployer) {
  return deployer.deploy([QuestLibrary]).then(() => {
    return deployer.link(QuestLibrary, [HeroToken])
  })
}

const saveRasheedQuestId =
  '34300835732321530447673206707498306934859497509820544160359264568'
const saveRasheedQuestIPFS = 'QmerYJC8yrsmTHuu2p89nixw82NELpaYscQxNWJ8QrZwVz'
const saveRasheedQuestLord = '0x2073edCF9eAfd08DcD8dD31BE9AD6673A31FeDc8'

module.exports = function(deployer, network, [owner1]) {
  console.log('Owner', owner1)
  return deployLibraries(deployer)
    .then(() => {
      return deployer.deploy(QuestToken, { from: owner1 })
    })
    .then(() => {
      return deployer.deploy(HeroToken, QuestToken.address, { from: owner1 })
    })
    .then(() => {
      return QuestToken.deployed()
    })
    .then(async quest => {
      await quest.setTokenContract(HeroToken.address, { from: owner1 })
      console.log('Set Token Contract', HeroToken.address)
      return quest.createQuest(
        saveRasheedQuestId,
        0,
        0,
        0,
        300,
        1,
        saveRasheedQuestIPFS,
        saveRasheedQuestLord,
        { from: owner1 },
      )
    })
    .catch(err => {
      console.log('Problem Deploying', err)
    })
}
