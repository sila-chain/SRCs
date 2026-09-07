import { expect } from "chai";
import { calculateSlidingWindowState, deploySRC7818 } from "../utils.test";
import { EVENT_TRANSFER } from "../constant.test";
import { ZeroAddress } from "ethers";
import { mine } from "@nomicfoundation/hardhat-network-helpers";
import { network } from "hardhat";

export const run = async () => {
  describe("Interface", async function () {
    beforeEach(async function () {
      await network.provider.send("hardhat_reset");
    });
    
    it("[ISRC20][ISRC7818][Override] totalSupply", async function () {
      const { src7818 } = await deploySRC7818({});
      // Due to token can expiration there is no actual totalSupply.
      expect(await src7818.totalSupply()).to.equal(0);
    });

    it("[ISRC7818] currentEpoch ", async function () {
      const { src7818 } = await deploySRC7818({});
      expect(await src7818.currentEpoch()).to.equal(0);
      await mine(await src7818.epochLength());
      expect(await src7818.currentEpoch()).to.equal(1);
    });

    it("[ISRC7818] epochType ", async function () {
      const { src7818 } = await deploySRC7818({});
      expect(await src7818.epochType()).to.equal(0);
    });

    it("[ISRC7818] epochLength", async function () {
      const { src7818 } = await deploySRC7818({});
      const self = calculateSlidingWindowState({});
      expect(await src7818.epochLength()).to.equal(self._blocksPerEpoch);
    });

    it("[ISRC7818] validityDuration", async function () {
      const { src7818 } = await deploySRC7818({});
      const self = calculateSlidingWindowState({});
      expect(await src7818.validityDuration()).to.equal(self._windowSize);
    });

    it("[ISRC7818] isEpochExpired ", async function () {
      const { src7818, alice } = await deploySRC7818({});
      const amount = 1;
      await expect(src7818.mint(alice.address, amount))
        .to.be.emit(src7818, EVENT_TRANSFER)
        .withArgs(ZeroAddress, alice.address, amount);
      const epoch = await src7818.currentEpoch();
      expect(await src7818.isEpochExpired(epoch)).to.equal(false);
      await mine(
        (await src7818.epochLength()) *
          ((await src7818.validityDuration()) + BigInt(2))
      );
      expect(await src7818.isEpochExpired(epoch)).to.equal(true);
    });
  });
};
