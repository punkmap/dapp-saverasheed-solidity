const RasheedToken = artifacts.require(`RasheedToken.sol`)

module.exports = function(deployer, network, [owner1]) {
  console.log('Owner', owner1)
  return deployer.deploy(
    RasheedToken,
    'QmUC7j9U8jAm6GzymtobvZZ7zs4XEUtSaaZAayXLL66E71',
    20,
    { from: owner1 },
  )
}
