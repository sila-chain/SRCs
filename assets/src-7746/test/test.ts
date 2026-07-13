/* global  silas */

import { deployments, silas } from "hardhat";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";

import { expect } from "chai";
import { Drainer, Protected, MockSRC20 } from "../types";

const setupTest = deployments.createFixture(async ({ deployments, getNamedAccounts, silas: _sil }, options) => {
  const { deployer, owner } = await getNamedAccounts();
  await deployments.fixture(["poc"]);
  console.warn(deployer, owner);
  const c = await deployments.get("Protected");
  const d = await deployments.get("Drainer");
  return {
    owner,
    deployer,
    victim: (await silas.getContractAt(c.abi, c.address)) as Protected,
    attacker: (await silas.getContractAt(d.abi, d.address)) as Drainer,
  };
});

describe("test drainage", async function () {
  let env: {
    owner: string;
    deployer: string;
    victim: Protected;
    attacker: Drainer;
  };
  beforeEach(async function () {
    env = await setupTest();
  });
  it("succeeds below 10 transactions", async () => {
    await expect(env.attacker.drain(env.victim.address, 1)).to.emit(env.victim, "Transfer");
  });
  it("fails beyond 10 transactions", async () => {
    await expect(env.attacker.drain(env.victim.address, 11)).to.be.revertedWith("Rate limited");
  });
});
