import { expect } from "chai";
import { deploySRC7818 } from "../utils.test";
import {
  ERROR_SRC20_INSUFFICIENT_BALANCE,
  ERROR_SRC20_INVALID_RECEIVER,
  EVENT_TRANSFER,
} from "../constant.test";
import { ZeroAddress } from "silas";
import { network } from "hardhat";
import { mine } from "@nomicfoundation/hardhat-network-helpers";

export const run = async () => {
  describe("Transfer", async function () {
    beforeEach(async function () {
      await network.provider.send("hardhat_reset");
    });

    it("[SUCCESS] transfer alice to bob", async function () {
      const windowSize = 2;
      const { src7818, alice, bob } = await deploySRC7818({ windowSize });
      const blocksPerEpoch = await src7818.epochLength();
      const blocksPerWindow =
        (await src7818.validityDuration()) * blocksPerEpoch;
      let epoch = await src7818.currentEpoch();
      expect(epoch).equal(0);
      let amount = 100;
      await expect(src7818.mint(alice.address, amount))
        .to.be.emit(src7818, EVENT_TRANSFER)
        .withArgs(ZeroAddress, alice.address, amount);
      expect(await src7818.balanceOf(alice.address)).to.equal(amount);
      amount -= 10;
      await expect(src7818.connect(alice).transfer(bob.address, amount))
        .to.be.emit(src7818, EVENT_TRANSFER)
        .withArgs(alice.address, bob.address, amount);
      expect(await src7818.balanceOf(bob.address)).to.equal(amount);
      await mine(blocksPerWindow + BigInt(2));
      epoch = await src7818.currentEpoch();
      expect(epoch).equal(2);
      expect(await src7818.balanceOf(bob.address)).to.equal(0);
    });

    it("[SUCCESS] transfer alice to bob FIFO", async function () {
      const windowSize = 2;
      const { src7818, alice, bob } = await deploySRC7818({ windowSize });
      const blocksPerEpoch = await src7818.epochLength();
      const blocksPerWindow =
        (await src7818.validityDuration()) * blocksPerEpoch;
      let epoch = await src7818.currentEpoch();
      expect(epoch).equal(0);
      const amount = BigInt(1);
      const iterate = BigInt(200);
      const expectBalance = iterate * amount;
      for (let index = 0; index < iterate; index++) {
        await src7818.mint(alice.address, amount);
      }
      expect(await src7818.balanceOf(alice.address)).to.equal(expectBalance);
      await expect(src7818.connect(alice).transfer(bob.address, expectBalance))
        .to.be.emit(src7818, EVENT_TRANSFER)
        .withArgs(alice.address, bob.address, expectBalance);
      expect(await src7818.balanceOf(bob.address)).to.equal(expectBalance);
      await mine(blocksPerWindow + iterate + BigInt(2));
      epoch = await src7818.currentEpoch();
      expect(epoch).equal(2);
      expect(await src7818.balanceOf(bob.address)).to.equal(0);
    });

    it("[SUCCESS] transfer alice to bob FIFO overlap epoch", async function () {
      const windowSize = 2;
      const { src7818, alice, bob } = await deploySRC7818({ windowSize });
      const blocksPerEpoch = await src7818.epochLength();
      const blocksPerWindow =
        (await src7818.validityDuration()) * blocksPerEpoch;
      let epoch = await src7818.currentEpoch();
      expect(epoch).equal(0);
      const amount = BigInt(1);
      const iterate = BigInt(200);
      const expectBalance = iterate * amount;
      await mine(blocksPerEpoch - BigInt(101));
      for (let index = 0; index < iterate; index++) {
        await src7818.mint(alice.address, amount);
      }
      epoch = await src7818.currentEpoch();
      expect(epoch).equal(1);
      expect(await src7818.balanceOfAtEpoch(0, alice.address)).to.equal(100);
      expect(await src7818.balanceOfAtEpoch(1, alice.address)).to.equal(100);
      expect(await src7818.balanceOf(alice.address)).to.equal(expectBalance);
      await expect(src7818.connect(alice).transfer(bob.address, expectBalance))
        .to.be.emit(src7818, EVENT_TRANSFER)
        .withArgs(alice.address, bob.address, expectBalance);
      expect(await src7818.balanceOf(bob.address)).to.equal(expectBalance);
      await mine(blocksPerWindow);
      epoch = await src7818.currentEpoch();
      expect(epoch).equal(3);
      expect(await src7818.balanceOf(bob.address)).to.equal(0);
    });

    it("[SUCCESS] transfer alice to bob FIFO overlap epoch shrink expire balance", async function () {
      const windowSize = 2;
      const { src7818, alice, bob } = await deploySRC7818({ windowSize });
      const blocksPerEpoch = await src7818.epochLength();
      const blocksPerWindow =
        (await src7818.validityDuration()) * blocksPerEpoch;
      await src7818.mint(alice.address, 10);
      await mine(blocksPerEpoch / BigInt(2));
      await src7818.mint(alice.address, 10);
      await mine(blocksPerEpoch / BigInt(2));
      await mine(blocksPerEpoch * BigInt(1));
      await expect(src7818.connect(alice).transfer(bob.address, 10))
        .to.be.emit(src7818, EVENT_TRANSFER)
        .withArgs(alice.address, bob.address, 10);
      expect(await src7818.balanceOf(alice.address)).to.equal(0);
      expect(await src7818.balanceOf(bob.address)).to.equal(10);
    });

    it("[SUCCESS] transfer specific epoch alice to bob ", async function () {
      const windowSize = 2;
      const { src7818, alice, bob } = await deploySRC7818({ windowSize });
      const blocksPerEpoch = await src7818.epochLength();
      const blocksPerWindow =
        (await src7818.validityDuration()) * blocksPerEpoch;
      let epoch = await src7818.currentEpoch();
      expect(epoch).equal(0);
      const amount = BigInt(1);
      const iterate = BigInt(200);
      const expectBalance = iterate * amount;
      await mine(blocksPerEpoch - BigInt(101));
      for (let index = 0; index < iterate; index++) {
        await src7818.mint(alice.address, amount);
      }
      epoch = await src7818.currentEpoch();
      expect(epoch).equal(1);
      expect(await src7818.balanceOfAtEpoch(0, alice.address)).to.equal(100);
      const epochBalance = await src7818.balanceOfAtEpoch(1, alice.address);
      expect(epochBalance).to.equal(100);
      expect(await src7818.balanceOf(alice.address)).to.equal(expectBalance);
      // transfer balance over epoch balance will failed
      await expect(
        src7818.connect(alice).transferAtEpoch(0, bob.address, expectBalance)
      )
        .to.be.revertedWithCustomError(
          src7818,
          ERROR_SRC20_INSUFFICIENT_BALANCE
        )
        .withArgs(alice.address, epochBalance, expectBalance);
      await expect(
        src7818.connect(alice).transferAtEpoch(0, bob.address, epochBalance)
      )
        .to.be.emit(src7818, EVENT_TRANSFER)
        .withArgs(alice.address, bob.address, epochBalance);
      expect(await src7818.balanceOf(bob.address)).to.equal(epochBalance);
    });

    it("[FAILED] insufficient balance", async function () {
      const { src7818, alice, bob } = await deploySRC7818({});
      await expect(src7818.connect(alice).transfer(bob.address, 1))
        .to.be.revertedWithCustomError(
          src7818,
          ERROR_SRC20_INSUFFICIENT_BALANCE
        )
        .withArgs(alice.address, 0, 1);
    });
  });
};
