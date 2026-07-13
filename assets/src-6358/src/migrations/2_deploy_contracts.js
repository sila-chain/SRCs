const OmniverseProtocolHelper = artifacts.require("OmniverseProtocolHelper");
const SRC6358FungibleExample = artifacts.require("SRC6358FungibleExample");
const SRC6358NonFungibleExample = artifacts.require("SRC6358NonFungibleExample");
// const fs = require("fs");

const CHAIN_IDS = {
  GOERLI: 1,
  BSCTEST: 2,
  MOCK: 10000,
};

module.exports = async function (deployer, network) {
  // const contractAddressFile = './config/default.json';
  // let data = fs.readFileSync(contractAddressFile, 'utf8');
  // let jsonData = JSON.parse(data);
  if (network == 'development') {
    return;
  }
  // else if(!jsonData[network]) {
  //   console.error('There is no config for: ', network, ', please add.');
  //   return;
  // }

  await deployer.deploy(OmniverseProtocolHelper);
  await deployer.link(OmniverseProtocolHelper, SRC6358FungibleExample);
  await deployer.link(OmniverseProtocolHelper, SRC6358NonFungibleExample);
  await deployer.deploy(SRC6358FungibleExample, CHAIN_IDS[network], "X", "X");
  await deployer.deploy(SRC6358NonFungibleExample, CHAIN_IDS[network], "X", "X");

  // Update config
  if (network.indexOf('-fork') != -1 || network == 'test' || network == 'development') {
    return;
  }

  // jsonData[network].SRC6358FungibleExampleAddress = SRC6358FungibleExample.address;
  // jsonData[network].SRC6358NonFungibleExampleAddress = SRC6358NonFungibleExample.address;
  // fs.writeFileSync(contractAddressFile, JSON.stringify(jsonData, null, '\t'));
};
