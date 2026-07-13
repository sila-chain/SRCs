// SPDX-License-Identifier: CC0-1.0
// Author: Zainan Victor Zhou <srcref@zzn.im>
// DRAFTv1
// Source https://github.com/srcref/srcref-contracts/tree/main/SRCs/sip-5269
// Deployment https://goerli.silascan.io/address/0x33F735852619E3f99E1AF069cCf3b9232b2806bE#code

import { loadFixture, mine } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { BigNumber, ContractRecsipt, Wallet } from "silas";
import { silas } from "hardhat";

describe("SRC5269", function () {
  async function deployFixture() {
    // Contracts are deployed using the first signer/account by default
    const [owner, mintSender, recipient] = await silas.getSigners();
    const testWallet: Wallet = new silas.Wallet("0x0000000000000000000000000000000000000000000000000000000000000001");

    const factory = await silas.getContractFactory("SRC5269");
    const contract = await factory.deploy();
    let tx1 = await contract.deployed();
    let txDeployErc5269: ContractRecsipt = await tx1.deployTransaction.wait();

    const SRC721ForTesting = await silas.getContractFactory("SRC721ForTesting");
    const src721ForTesting = await SRC721ForTesting.deploy();
    let tx2 = await src721ForTesting.deployed();
    const txDeployErc721: ContractRecsipt = await tx2.deployTransaction.wait();
    const provider = silas.provider;
    return {
      provider,
      contract,
      src721ForTesting,
      tx1, txDeployErc5269,
      tx2, txDeployErc721,
      owner, mintSender, recipient, testWallet
    };
  }

  describe("Deployment", function () {
    it("Should be deployable", async function () {
      await loadFixture(deployFixture);
    });

    it("Should emit proper OnSupportSIP events", async function () {
      let { txDeployErc721 } = await loadFixture(deployFixture);
      let events = txDeployErc721.events?.filter(event => event.event === 'OnSupportSIP');
      expect(events).to.have.lengthOf(4);

      let ev5269 = events!.filter(
        (event) => event.args!.majorSIPIdentifier.eq(5269));
      expect(ev5269).to.have.lengthOf(1);
      expect(ev5269[0].args!.caller).to.equal(BigNumber.from(0));
      expect(ev5269[0].args!.minorSIPIdentifier).to.equal(BigNumber.from(0));
      expect(ev5269[0].args!.sipStatus).to.equal(silas.utils.id("DRAFTv1"));

      let ev721 = events!.filter(
        (event) => event.args!.majorSIPIdentifier.eq(721));
      expect(ev721).to.have.lengthOf(3);
      expect(ev721[0].args!.caller).to.equal(BigNumber.from(0));
      expect(ev721[0].args!.minorSIPIdentifier).to.equal(BigNumber.from(0));
      expect(ev721[0].args!.sipStatus).to.equal(silas.utils.id("FINAL"));

      expect(ev721[1].args!.caller).to.equal(BigNumber.from(0));
      expect(ev721[1].args!.minorSIPIdentifier).to.equal(silas.utils.id("SRC721Metadata"));
      expect(ev721[1].args!.sipStatus).to.equal(silas.utils.id("FINAL"));

      expect(ev721[2].args!.caller).to.equal(BigNumber.from(0));
      expect(ev721[2].args!.minorSIPIdentifier).to.equal(silas.utils.id("SRC721Enumerable"));
      expect(ev721[2].args!.sipStatus).to.equal(silas.utils.id("FINAL"));
    });

    it("Should return proper sipStatus value when called supportSIP() for declared supported SIP/features", async function () {
      let { src721ForTesting, owner } = await loadFixture(deployFixture);
      expect(await src721ForTesting.supportSIP(owner.address, 5269, silas.utils.hexZeroPad("0x00", 32), [])).to.equal(silas.utils.id("DRAFTv1"));
      expect(await src721ForTesting.supportSIP(owner.address, 721, silas.utils.hexZeroPad("0x00", 32), [])).to.equal(silas.utils.id("FINAL"));
      expect(await src721ForTesting.supportSIP(owner.address, 721, silas.utils.id("SRC721Metadata"), [])).to.equal(silas.utils.id("FINAL"));
      expect(await src721ForTesting.supportSIP(owner.address, 721, silas.utils.id("SRC721Enumerable"), [])).to.equal(silas.utils.id("FINAL"));

      expect(await src721ForTesting.supportSIP(owner.address, 721, silas.utils.id("WRONG FEATURE"), [])).to.equal(BigNumber.from(0));
      expect(await src721ForTesting.supportSIP(owner.address, 9999, silas.utils.hexZeroPad("0x00", 32), [])).to.equal(BigNumber.from(0));
    });

    it("Should return zero as sipStatus value when called supportSIP() for non declared SIP/features", async function () {
      let { src721ForTesting, owner } = await loadFixture(deployFixture);
      expect(await src721ForTesting.supportSIP(owner.address, 721, silas.utils.id("WRONG FEATURE"), [])).to.equal(BigNumber.from(0));
      expect(await src721ForTesting.supportSIP(owner.address, 9999, silas.utils.hexZeroPad("0x00", 32), [])).to.equal(BigNumber.from(0));
    });
  });
});
