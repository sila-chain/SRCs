import { Contract, Signer } from "ethers";
import { ethers } from "hardhat";
import {
  SRC20_NAME,
  SRC20_SYMBOL,
  SRC20_EXPIRABLE_CONTRACT,
  YEAR_IN_MILLISECONDS,
} from "./constant.test";

export interface ISlidingWindowState {
  _blocksPerEpoch: Number;
  _windowSize: Number;
  _initialBlockNumber: Number;
}

export const calculateSlidingWindowState = function ({
  startBlockNumber = 100,
  blockTime = 400,
  windowSize = 2,
}): ISlidingWindowState {
  const self: ISlidingWindowState = {
    _blocksPerEpoch: 0,
    _windowSize: 0,
    _initialBlockNumber: 0,
  };
  self._initialBlockNumber = startBlockNumber;
  // since solidity always rounds down. then use 'Math.floor'
  const blocksPerEpochCache = Math.floor(Math.floor(YEAR_IN_MILLISECONDS / blockTime) / 4);
  self._blocksPerEpoch = blocksPerEpochCache;
  self._windowSize = windowSize;
  return self;
};

export const deploySRC7818 = async function ({
  blockTime = 400, // assume 400ms block time
  windowSize = 2, // widow width size 2 epoch
} = {}) {
  const [deployer, alice, bob, jame] = await ethers.getSigners();

  const SRC7818 = await ethers.getContractFactory(
    SRC20_EXPIRABLE_CONTRACT,
    deployer
  );
  const src7818 = await SRC7818.deploy(
    SRC20_NAME,
    SRC20_SYMBOL,
    blockTime,
    windowSize
  );
  await src7818.waitForDeployment();

  return {
    src7818,
    deployer,
    alice,
    bob,
    jame,
  };
};

