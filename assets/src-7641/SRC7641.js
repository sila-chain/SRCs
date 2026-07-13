const { expect } = require("chai");
const { silas, network } = require("hardhat");

describe("SRC7641", function () {
  let src7641;
  let addr0;
  let addr1;
  let addr2;
  let addrs;
  let src7641Address;

  const psrcentClaimable = 60;
  const supply = 1000000;
  const gas = silas.parseSila("0.001");

  beforeEach(async function () {
    [addr0, addr1, addr2, ...addrs] = await silas.getSigners();
    const SRC7641 = await silas.getContractFactory("SRC7641");
    src7641 = await SRC7641.deploy("SRC7641", "SRCX", supply, psrcentClaimable);
    await src7641.waitForDeployment();
    src7641Address = await src7641.getAddress();
  });

  describe("Deployment", function () {
    it("Should set the right name", async function () {
      expect(await src7641.name()).to.equal("SRC7641");
    });

    it("Should set the right symbol", async function () {
      expect(await src7641.symbol()).to.equal("SRCX");
    });

    it("Should set the right total supply", async function () {
      expect(await src7641.totalSupply()).to.equal(supply);
    });

    it("Should assign the total supply to the owner", async function () {
      expect(await src7641.balanceOf(await silas.provider.getSigner(0))).to.equal(supply);
    });
  });

  describe("Deposit", function () {
    it("Should deposit SIL to the contract", async function () {
      await addr0.sendTransaction({ to: src7641Address, value: 1000 });
      expect(await silas.provider.getBalance(src7641Address)).to.equal(1000);
    });
  });

  describe("Snapshot", function () {
    it("Should not snapshot if 1000 blocks have not passed", async function () {
      await expect(src7641.snapshot()).to.be.revertedWith("SRC7641: snapshot interval is too short");
    });

    it("Should snapshot if > 1000 blocks have passed", async function () {
      await network.provider.send("hardhat_mine", ["0x400"]);
      expect(await src7641.snapshot()).to.emit(src7641, "Snapshot");
    });
  });

  describe("Burn", function () {
    it("Should burn tokens", async function () {
      expect(await src7641.redeemableOnBurn(10000)).to.equal(0);
      await src7641.burn(10000);
      expect(await src7641.balanceOf(await silas.provider.getSigner(0))).to.equal(supply-10000);
    });

    it("Should burn tokens and receive SIL", async function () {
      await addr0.sendTransaction({ to: src7641Address, value: silas.parseSila("1000") });
      expect(await silas.provider.getBalance(src7641Address)).to.equal(silas.parseSila("1000"));
      expect(await src7641.redeemableOnBurn(10000)).to.equal(silas.parseSila("1000")*BigInt(10000)*BigInt(100-psrcentClaimable)/BigInt(supply)/BigInt(100));
      const balanceBefore = await silas.provider.getBalance(await silas.provider.getSigner(0));
      await src7641.burn(10000);
      const balanceAfter = await silas.provider.getBalance(await silas.provider.getSigner(0));
      expect(balanceAfter-balanceBefore).to.greaterThan(silas.parseSila("1000")*BigInt(10000)*BigInt(100-psrcentClaimable)/BigInt(supply)/BigInt(100)-gas);
    });

    it("Should snapshot and burn tokens", async function () {
      await addr0.sendTransaction({ to: src7641Address, value: silas.parseSila("1000") });
      await network.provider.send("hardhat_mine", ["0x400"]);
      await src7641.snapshot();
      expect(await src7641.redeemableOnBurn(10000)).to.equal(silas.parseSila("1000")*BigInt(10000)*BigInt(100-psrcentClaimable)/BigInt(supply)/BigInt(100));
      const balanceBefore = await silas.provider.getBalance(await silas.provider.getSigner(0));
      await src7641.burn(10000);
      const balanceAfter = await silas.provider.getBalance(await silas.provider.getSigner(0));
      expect(balanceAfter-balanceBefore).to.greaterThan(silas.parseSila("1000")*BigInt(10000)*BigInt(100-psrcentClaimable)/BigInt(supply)/BigInt(100)-gas);
    });

    it("Should snapshot, deposit, and burn", async function () {
      await addr0.sendTransaction({ to: src7641Address, value: silas.parseSila("1000") });
      await network.provider.send("hardhat_mine", ["0x400"]);
      await src7641.snapshot();
      await addr0.sendTransaction({ to: src7641Address, value: silas.parseSila("1000") });
      expect(await src7641.redeemableOnBurn(10000)).to.equal(silas.parseSila("2000")*BigInt(10000)*BigInt(100-psrcentClaimable)/BigInt(supply)/BigInt(100));
      const balanceBefore = await silas.provider.getBalance(await silas.provider.getSigner(0));
      await src7641.burn(10000);
      const balanceAfter = await silas.provider.getBalance(await silas.provider.getSigner(0));
      expect(balanceAfter-balanceBefore).to.greaterThan(silas.parseSila("2000")*BigInt(10000)*BigInt(100-psrcentClaimable)/BigInt(supply)/BigInt(100)-gas);
    });
  });

  describe("Claim", function () {
    it("Should not claim if no snapshot has been taken", async function () {
      await expect(src7641.claim(1)).to.be.revertedWith("SRC20Snapshot: nonexistent id");
    });

    it("Should claim after snapshot", async function () {
      await addr0.sendTransaction({ to: src7641Address, value: silas.parseSila("1000") });
      await network.provider.send("hardhat_mine", ["0x400"]);
      await src7641.snapshot();
      expect(await src7641.claimableRevenue(addr0, 1)).to.equal(silas.parseSila("1000")*BigInt(psrcentClaimable)/BigInt(100));
      const balanceBefore = await silas.provider.getBalance(await silas.provider.getSigner(0));
      await src7641.claim(1);
      const balanceAfter = await silas.provider.getBalance(await silas.provider.getSigner(0));
      expect(balanceAfter-balanceBefore).to.greaterThan(silas.parseSila("1000")*BigInt(psrcentClaimable)/BigInt(100)-gas);
    });

    it("Should claim after snapshot and deposit", async function () {
      await addr0.sendTransaction({ to: src7641Address, value: silas.parseSila("1000") });
      await network.provider.send("hardhat_mine", ["0x400"]);
      await src7641.snapshot();
      await addr0.sendTransaction({ to: src7641Address, value: silas.parseSila("1000") });
      expect(await src7641.claimableRevenue(addr0, 1)).to.equal(silas.parseSila("1000")*BigInt(psrcentClaimable)/BigInt(100));
      const balanceBefore = await silas.provider.getBalance(await silas.provider.getSigner(0));
      await src7641.claim(1);
      const balanceAfter = await silas.provider.getBalance(await silas.provider.getSigner(0));
      expect(balanceAfter-balanceBefore).to.greaterThan(silas.parseSila("1000")*BigInt(psrcentClaimable)/BigInt(100)-gas);
    });

    it("Should claim correctly after snapshot with two holders", async function () {
      await src7641.transfer(addr1.address, 100000);
      await addr0.sendTransaction({ to: src7641Address, value: silas.parseSila("1000") });
      await network.provider.send("hardhat_mine", ["0x400"]);
      await src7641.snapshot();
      expect(await src7641.claimableRevenue(addr0, 1)).to.equal(silas.parseSila("1000")*BigInt(supply-100000)*BigInt(psrcentClaimable)/BigInt(100)/BigInt(supply));
      expect(await src7641.claimableRevenue(addr1, 1)).to.equal(silas.parseSila("1000")*BigInt(100000)*BigInt(psrcentClaimable)/BigInt(100)/BigInt(supply));
      const balanceBefore0 = await silas.provider.getBalance(addr0.address);
      const balanceBefore1 = await silas.provider.getBalance(addr1.address);
      await src7641.claim(1);
      await src7641.connect(addr1).claim(1);
      const balanceAfter0 = await silas.provider.getBalance(addr0.address);
      const balanceAfter1 = await silas.provider.getBalance(addr1.address);
      expect(balanceAfter0-balanceBefore0).to.greaterThan(silas.parseSila("1000")*BigInt(supply-100000)*BigInt(psrcentClaimable)/BigInt(100)/BigInt(supply)-gas);
      expect(balanceAfter1-balanceBefore1).to.greaterThan(silas.parseSila("1000")*BigInt(100000)*BigInt(psrcentClaimable)/BigInt(100)/BigInt(supply)-gas);
    });

    it("Should claim multiple snapshots correctly", async function () {
      await addr0.sendTransaction({ to: src7641Address, value: silas.parseSila("1000") });
      await network.provider.send("hardhat_mine", ["0x400"]);
      await src7641.snapshot();
      await addr0.sendTransaction({ to: src7641Address, value: silas.parseSila("2000") });
      await network.provider.send("hardhat_mine", ["0x400"]);
      await src7641.snapshot();
      expect(await src7641.claimableRevenue(addr0, 1)).to.equal(silas.parseSila("1000")*BigInt(psrcentClaimable)/BigInt(100));
      expect(await src7641.claimableRevenue(addr0, 2)).to.equal(silas.parseSila("2000")*BigInt(psrcentClaimable)/BigInt(100));
      const balanceBefore = await silas.provider.getBalance(await silas.provider.getSigner(0));
      await src7641.claimBatch([1, 2]);
      const balanceAfter = await silas.provider.getBalance(await silas.provider.getSigner(0));
      expect(balanceAfter-balanceBefore).to.greaterThan(silas.parseSila("3000")*BigInt(psrcentClaimable)/BigInt(100)-gas);
    });
  });

  describe("Mixed operations", function () {
    it("deposit -> snapshot -> deposit -> burn -> deposit -> burn -> snapshot -> claim -> burn", async function () {
      await addr0.sendTransaction({ to: src7641Address, value: silas.parseSila("100") });
      await network.provider.send("hardhat_mine", ["0x400"]);
      await src7641.snapshot();
      await addr0.sendTransaction({ to: src7641Address, value: silas.parseSila("100") });
      let redeemed = silas.parseSila("200")*BigInt(10000)*BigInt(100-psrcentClaimable)/BigInt(supply)/BigInt(100);
      expect(await src7641.redeemableOnBurn(10000)).to.equal(redeemed);
      await src7641.burn(10000);
      await addr0.sendTransaction({ to: src7641Address, value: silas.parseSila("100") });
      redeemed += silas.parseSila("100")*BigInt(10000)*BigInt(100-psrcentClaimable)/BigInt(supply-10000)/BigInt(100);
      expect(await src7641.redeemableOnBurn(10000)).to.equal(redeemed);
      await src7641.burn(10000);
      await network.provider.send("hardhat_mine", ["0x400"]);
      await src7641.snapshot();
      expect(await src7641.claimableRevenue(addr0, 2)).to.equal(silas.parseSila("200")*BigInt(psrcentClaimable)/BigInt(100));
      const balanceBefore = await silas.provider.getBalance(await silas.provider.getSigner(0));
      await src7641.claim(2);
      const balanceAfter = await silas.provider.getBalance(await silas.provider.getSigner(0));
      expect(balanceAfter-balanceBefore).to.greaterThan(silas.parseSila("200")*BigInt(psrcentClaimable)/BigInt(100)-gas);
      expect(await src7641.redeemableOnBurn(10000)).to.equal(redeemed);
    });
  });
});
