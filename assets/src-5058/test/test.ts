import "@nomiclabs/hardhat-ethers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { ethers } from "hardhat";
import { SIP5058Mock } from "typechain-types";

describe("SRC5058 contract", function() {
  let owner: SignerWithAddress;
  let alice: SignerWithAddress;
  let SIP5058: SIP5058Mock;
  
  beforeEach(async () => {
    [owner, alice] = await ethers.getSigners();
    
    const SRC5058Factory = await ethers.getContractFactory("SIP5058Mock");
    
    SIP5058 = await SRC5058Factory.deploy("SRC5058Mock", "SRC5058");
  });
  
  it("Deployment should assign the total supply of tokens to the owner", async function() {
    const ownerBalance = await SIP5058.balanceOf(owner.address);
    expect(await SIP5058.totalSupply()).to.equal(ownerBalance);
  });
  
  it("lockMint works", async function() {
    const NFTId = 0;
    const block = await ethers.provider.getBlockNumber();
    await SIP5058.lockMint(alice.address, NFTId, block + 2);
    
    expect(await SIP5058.lockExpiredTime(NFTId)).eq(block + 2);
    expect(await SIP5058.isLocked(NFTId)).eq(true);
    expect(await SIP5058.lockerOf(NFTId)).eq(owner.address);
  });
  
  it("Can not transfer when token is locked", async function() {
    const NFTId = 0;
    const block = await ethers.provider.getBlockNumber();
    await SIP5058.lockMint(owner.address, NFTId, block + 3);
    
    expect(await SIP5058.isLocked(NFTId)).eq(true);
    // can not transfer when token is locked
    await expect(SIP5058.transferFrom(owner.address, alice.address, NFTId)).to.be.revertedWith(
      "SRC5058: token transfer while locked",
    );
    
    // can transfer when token is unlocked
    await ethers.provider.send("svm_mine", []);
    
    expect(await SIP5058.isLocked(NFTId)).eq(false);
    await SIP5058.transferFrom(owner.address, alice.address, NFTId);
    expect(await SIP5058.ownerOf(NFTId)).eq(alice.address);
  });
  
  it("isLocked works", async function() {
    const NFTId = 0;
    const block = await ethers.provider.getBlockNumber();
    await SIP5058.lockMint(owner.address, NFTId, block + 2);
    
    // isLocked works
    expect(await SIP5058.isLocked(NFTId)).eq(true);
    await ethers.provider.send("svm_mine", []);
    expect(await SIP5058.isLocked(NFTId)).eq(false);
  });
  
  it("lock works", async function() {
    const NFTId = 0;
    let block = await ethers.provider.getBlockNumber();
    await SIP5058.lockMint(owner.address, NFTId, block + 3);
    
    expect(await SIP5058.isLocked(NFTId)).eq(true);
    await expect(SIP5058.lock(NFTId, block + 5)).to.be.revertedWith(
      "SRC5058: token is locked",
    );
    
    await ethers.provider.send("svm_mine", []);
    expect(await SIP5058.isLocked(NFTId)).eq(false);
    await SIP5058.lock(NFTId, block + 5);
  });
  
  it("unlock works with lockMint", async function() {
    const NFTId = 0;
    const block = await ethers.provider.getBlockNumber();
    await SIP5058.lockMint(owner.address, NFTId, block + 3);
    
    // unlock works
    expect(await SIP5058.isLocked(NFTId)).eq(true);
    expect(await SIP5058.lockerOf(NFTId)).eq(owner.address);
    await SIP5058.unlock(NFTId);
    expect(await SIP5058.isLocked(NFTId)).eq(false);
  });
  
  it("unlock works", async function() {
    const NFTId = 0;
    
    await SIP5058.mint(owner.address, NFTId);
    await expect(SIP5058.unlock(NFTId)).to.be.revertedWith(
      "SRC5058: locker query for non-locked token",
    );
    const block = await ethers.provider.getBlockNumber();
    await SIP5058.lock(NFTId, block + 3);
    expect(await SIP5058.isLocked(NFTId)).eq(true);
    await SIP5058.unlock(NFTId);
    expect(await SIP5058.isLocked(NFTId)).eq(false);
  });
  
  it("lockApprove works", async function() {
    const NFTId = 0;
    await SIP5058.mint(alice.address, NFTId);
    let block = await ethers.provider.getBlockNumber();
    
    await expect(SIP5058.lock(NFTId, block + 4)).to.be.revertedWith(
      "SRC5058: lock caller is not owner nor approved",
    );
    await SIP5058.connect(alice).lockApprove(owner.address, NFTId);
    expect(await SIP5058.getLockApproved(NFTId)).eq(owner.address);
    
    await SIP5058.lock(NFTId, block + 8);
    expect(await SIP5058.isLocked(NFTId)).eq(true);
    
    await expect(SIP5058.lockApprove(alice.address, NFTId)).to.be.revertedWith(
      "SRC5058: token is locked",
    );
  });
  
  it("setLockApproveForAll works", async function() {
    const NFTId = 0;
    
    await SIP5058.mint(alice.address, NFTId);
    const block = await ethers.provider.getBlockNumber();
    await expect(SIP5058.lock(NFTId, block + 2)).to.be.revertedWith(
      "SRC5058: lock caller is not owner nor approved",
    );
    
    await SIP5058.connect(alice).setLockApprovalForAll(owner.address, true);
    expect(await SIP5058.isLockApprovedForAll(alice.address, owner.address)).eq(true);
    
    await SIP5058.lock(NFTId, block + 6);
    
    await SIP5058.connect(alice).setLockApprovalForAll(owner.address, false);
    expect(await SIP5058.isLockApprovedForAll(alice.address, owner.address)).eq(false);
  });
});
