#!/usr/bin/env node

const server = require('./web3Adaptor-server')

return server.injectWeb3().then(() => {
  console.log('Web3 initialized!')
  let contract = server.contractNamed('RasheedToken')
  console.log('Got Rasheed Token!', contract)
})
