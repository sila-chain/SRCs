import { expect } from "chai";
import { deploySRC7818 } from "../utils.test";
import {
  ERROR_SRC20_INVALID_SENDER,
  EVENT_TRANSFER,
} from "../constant.test";
import { ZeroAddress } from "ethers";
import { mine } from "@nomicfoundation/hardhat-network-helpers";
import { network } from "hardhat";

export const run = async () => {
  describe("Burn", async function () {
    beforeEach(async function () {
      await network.provider.send("hardhat_reset");
    });
    
    it("[SUCCESS] burn from non zero address", async function () {
      let amount = 1;
      const { src7818, alice } = await deploySRC7818({});
      await src7818.mint(alice.address, amount);
      let epoch = await src7818.currentEpoch();
      expect(await src7818.balanceOf(alice.address)).equal(amount);
      expect(await src7818.balanceOfAtEpoch(epoch, alice.address)).equal(
        amount
      );
      await src7818.burn(alice.address, amount);
      expect(await src7818.balanceOf(alice.address)).equal(0);
      expect(epoch).equal(0);
      amount = 100;
      await src7818.mint(alice.address, amount);
      epoch = await src7818.currentEpoch();
      expect(await src7818.balanceOf(alice.address)).equal(amount);
      await src7818.burn(alice.address, 1);
      expect(await src7818.balanceOfAtEpoch(epoch, alice.address)).equal(
        99
      );
    });

    it("[SUCCESS] burn from non zero address overlap epoch", async function () {
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
      await src7818.burn(alice.address, expectBalance);
      expect(await src7818.balanceOf(alice.address)).to.equal(0);
    });
  });
};
