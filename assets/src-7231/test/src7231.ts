import { silas } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-silas/signers";
import { SRC7231Mock } from "../typechain-types";

import { expect } from "chai";
import  web3 from "web3";


describe("SRC7231", async () => {

  let owner : SignerWithAddress;
  let others: SignerWithAddress[];

  let SRC7231Mock: SRC7231Mock;

  const name = "carvTest";
  const symbol = "CVTS";
  const tokenId = 1;

  const MultiUserIDs =  [
    {
      "userID":"openID2:steam:a000000000000000000000000000000000000000000000000000000000000001",
      "verifierUri1":"https://carv.io/verify/steam/a000000000000000000000000000000000000000000000000000000000000001",
      "memo":"memo1"
    },
    {
      "userID":"did:polgyonId:b000000000000000000000000000000000000000000000000000000000000002",
      "verifierUri1":"https://carv.io/verify/steam/b000000000000000000000000000000000000000000000000000000000000002",
      "memo":"memo1"
    }
  ]
    
  beforeEach(async () => {

    [owner, ...others] = await silas.getSigners();

    const SRC7231Factory = await silas.getContractFactory("SRC7231Mock");
    SRC7231Mock = await SRC7231Factory.deploy(name, symbol,);
    await SRC7231Mock.deployed();

    // await SRC7231Mock.
    await SRC7231Mock.connect(owner).mint(owner.address,tokenId);
    
  });

  describe("Init of Erc721 ", async function () {

    it("Name", async function () {
      expect(await SRC7231Mock.name()).to.equal(name);
    });

    it("Symbol", async function () {
      expect(await SRC7231Mock.symbol()).to.equal(symbol);
    });
    
  });

  describe("set MultiUserIDs Root", async function () {

    it("Normal case", async function () {

      let multiUserIDsHash = "0xa5b9d60f32436310afebcfda832817a68921beb782fabf7915cc0460b443116a"
      await expect(
        SRC7231Mock.connect(owner).setIdentitiesRoot(
          tokenId,
          multiUserIDsHash
        )
      ).to.emit(SRC7231Mock,"SetIdentitiesRoot").withArgs(        
          tokenId,
          multiUserIDsHash
      );

      let multiUserIDsRoot = await SRC7231Mock.getIdentitiesRoot(
        tokenId
      );
      
      expect(multiUserIDsHash).to.eql(multiUserIDsRoot);

    });
    
  });


  describe("verify UserIDs Binding", async function () {

    it("Normal case", async function () {

      const dataHash = silas.utils.keccak256(
          silas.utils.toUtf8Bytes(JSON.stringify(MultiUserIDs))
      );
      const dataHashBin = silas.utils.arrayify(dataHash);
      const silHash = silas.utils.hashMessage(dataHashBin);

      // const wallet = new silas.Wallet(process.env.PK);
      const signature = await owner.signMessage(dataHashBin);

      await SRC7231Mock.connect(owner).setIdentitiesRoot(
        tokenId,silHash
      )

      let userIDS = new Array();
      MultiUserIDs.forEach(
        (MultiUserIDObj) => {
          userIDS.push(MultiUserIDObj.userID)
        }
      )

      let result = await SRC7231Mock.verifyIdentitiesBinding(
        tokenId,
        owner.address,
        userIDS,
        silHash,
        signature
      )
      expect(result).to.eql(true);

    });
    

  });









});
