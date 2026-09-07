import { expect } from "chai";
import { deploySRC7818 } from "../utils.test";
import { EVENT_TRANSFER } from "../constant.test";
import { ZeroAddress } from "ethers";
import { mine } from "@nomicfoundation/hardhat-network-helpers";
import { network } from "hardhat";

export const run = async () => {
  describe("Mint", async function () {
    beforeEach(async function () {
      await network.provider.send("hardhat_reset");
    });

    it("[SUCCESS] mint to non zero address", async function () {
      const amount = 1;
      const {src7818, alice} = await deploySRC7818({});
      const blocksPerEpoch = await src7818.epochLength();
      const blocksPerWindow = (await src7818.validityDuration()) * blocksPerEpoch;
      let epoch = await src7818.currentEpoch();

      await expect(src7818.mint(alice.address, amount))
        .to.be.emit(src7818, EVENT_TRANSFER)
        .withArgs(ZeroAddress, alice.address, amount);
      expect(await src7818.balanceOf(alice.address)).equal(amount);
      expect(await src7818.balanceOfAtEpoch(epoch, alice.address)).equal(amount);
      expect(epoch).equal(0);

      await mine(blocksPerWindow * BigInt(2));
      const currentEpoch = await src7818.currentEpoch();
      expect(currentEpoch).equal(4);
      expect(await src7818.balanceOf(alice.address)).equal(0);
      expect(await src7818.balanceOfAtEpoch(epoch, alice.address)).equal(0);
      expect(await src7818.balanceOfAtEpoch(currentEpoch + BigInt(1), alice.address)).equal(0);
    });
  });
};
