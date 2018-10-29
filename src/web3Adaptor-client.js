/*
  This is an auto-generated web3 interface to the smart contracts deployed via Dapploy
  Do not make changes to this file, they get overwritten each Dapploy :)
*/
/* eslint-disable */
import Web3 from 'web3'

import { PortisProvider } from 'portis'

export const getWeb3 = () => {
  if (typeof window.web3 !== 'undefined') {
    return new Web3(window.web3.currentProvider)
  }
  return new Web3(new PortisProvider({
        providerNodeUrl: 'http://localhost:8545',
    }))
}

const contractObject = name =>
  SmartContracts.find(contract => contract.name === name)

export const contractNamed = name => {
  const contractObj = contractObject(name)
  return contractObj ? contractObj.contract : undefined
}

export const contractAddress = name => {
  const contractObj = contractObject(name)
  return contractObj ? contractObj.address : undefined
}

export const validateContracts = async => {
  return Promise.all(
    SmartContracts.map(contract => validContract(contract.name)),
  ).then(results => {
    return results.reduce((result, next) => result && next)
  })
}

export const validContract = async name => {
  console.log('Validating Contract', name)
  const address = contractAddress(name)
  return new Promise((resolve, reject) => {
    web3.eth
      .getCode(address)
      .then(
        code =>
          code === '0x0' || code === '0x' ? resolve(false) : resolve(true),
      )
      .catch(err => reject(err))
  })
}

const getCurrentUser = async () =>
  web3.eth.getAccounts().then(accounts => accounts[0])

export let SmartContracts = []
export let web3
export let currentUser

export let QuestLibrary
export let QuestToken
export let HeroToken


const refreshContracts = async web3 =>
  web3.eth.net.getId().then(netId => {
    SmartContracts = []
    
		const jsonQuestLibrary = require('./../build/contracts/QuestLibrary.json')
		if (jsonQuestLibrary && jsonQuestLibrary.networks[netId]) {
			const addressQuestLibrary = jsonQuestLibrary.networks[netId].address
			QuestLibrary = new web3.eth.Contract(
			jsonQuestLibrary.abi,
			addressQuestLibrary)
			SmartContracts.push({name: 'QuestLibrary', contract: QuestLibrary, address: addressQuestLibrary})
		}
		const jsonQuestToken = require('./../build/contracts/QuestToken.json')
		if (jsonQuestToken && jsonQuestToken.networks[netId]) {
			const addressQuestToken = jsonQuestToken.networks[netId].address
			QuestToken = new web3.eth.Contract(
			jsonQuestToken.abi,
			addressQuestToken)
			SmartContracts.push({name: 'QuestToken', contract: QuestToken, address: addressQuestToken})
		}
		const jsonHeroToken = require('./../build/contracts/HeroToken.json')
		if (jsonHeroToken && jsonHeroToken.networks[netId]) {
			const addressHeroToken = jsonHeroToken.networks[netId].address
			HeroToken = new web3.eth.Contract(
			jsonHeroToken.abi,
			addressHeroToken)
			SmartContracts.push({name: 'HeroToken', contract: HeroToken, address: addressHeroToken})
		}

    return Promise.resolve(SmartContracts)
  })

export function injectWeb3() {
  web3 = getWeb3()

  const refreshUser = () =>
    getCurrentUser().then(account => {
      currentUser = account
    })
  const refreshDapp = async () =>
    Promise.all([refreshUser(), refreshContracts(web3)])

  // Will refresh local store when new user is chosen:
  web3.currentProvider.publicConfigStore.on('update', refreshDapp)

  return refreshDapp()
}
