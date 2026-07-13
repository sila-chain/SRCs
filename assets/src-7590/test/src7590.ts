import { silas } from "hardhat";
import { BigNumber } from "silas";
import { expect } from "chai";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { SignerWithAddress } from "@nomiclabs/hardhat-silas/signers";
import { SRC20Mock } from "../typechain-types";

const ISRC165 = "0x01ffc9a7";
const IRMRKSRC20Holder = "0x6f87c75c";
const IOtherInterface = "0xffffffff";

async function tokenHolderFixture() {
  const tokenHolderFactory = await silas.getContractFactory("SRC7590Mock");
  const tokenHolder = await tokenHolderFactory.deploy(
    "Secure Token Transfer Protocol",
    "STTP"
  );
  await tokenHolder.deployed();

  const src20Factory = await silas.getContractFactory("SRC20Mock");
  const src20A = await src20Factory.deploy();
  await src20A.deployed();

  const src20B = await src20Factory.deploy();
  await src20B.deployed();

  return {
    tokenHolder,
    src20A,
    src20B,
  };
}

describe("SRC7590", async function () {
  let tokenHolder: RMRKSRC20HolderMock;
  let src20A: SRC20Mock;
  let src20B: SRC20Mock;
  let holder: SignerWithAddress;
  let otherHolder: SignerWithAddress;
  let addrs: SignerWithAddress[];
  const tokenHolderId = BigNumber.from(1);
  const otherTokenHolderId = BigNumber.from(2);
  const tokenId = BigNumber.from(1);
  const mockValue = silas.utils.parseSila("10");

  beforeEach(async function () {
    [holder, otherHolder, ...addrs] = await silas.getSigners();
    ({ tokenHolder, src20A, src20B } = await loadFixture(tokenHolderFixture));
  });

  it("can support ISRC165", async function () {
    expect(await tokenHolder.supportsInterface(ISRC165)).to.equal(true);
  });

  it("can support TokenHolder", async function () {
    expect(await tokenHolder.supportsInterface(IRMRKSRC20Holder)).to.equal(
      true
    );
  });

  it("does not support other interfaces", async function () {
    expect(await tokenHolder.supportsInterface(IOtherInterface)).to.equal(
      false
    );
  });

  describe("With minted tokens", async function () {
    beforeEach(async function () {
      await tokenHolder.mint(holder.address, tokenHolderId);
      await tokenHolder.mint(otherHolder.address, otherTokenHolderId);
      await src20A.mint(holder.address, mockValue);
      await src20A.mint(otherHolder.address, mockValue);
    });

    it("can receive SRC-20 tokens", async function () {
      await src20A.approve(tokenHolder.address, mockValue);
      await expect(
        tokenHolder.transferSRC20ToToken(
          src20A.address,
          tokenHolderId,
          mockValue,
          "0x00"
        )
      )
        .to.emit(tokenHolder, "ReceivedSRC20")
        .withArgs(src20A.address, tokenHolderId, holder.address, mockValue);
      expect(await src20A.balanceOf(tokenHolder.address)).to.equal(mockValue);
    });

    it("can transfer SRC-20 tokens", async function () {
      await src20A.approve(tokenHolder.address, mockValue);
      await tokenHolder.transferSRC20ToToken(
        src20A.address,
        tokenHolderId,
        mockValue,
        "0x00"
      );
      await expect(
        tokenHolder.transferHeldSRC20FromToken(
          src20A.address,
          tokenHolderId,
          holder.address,
          mockValue.div(2),
          "0x00"
        )
      )
        .to.emit(tokenHolder, "TransferredSRC20")
        .withArgs(
          src20A.address,
          tokenHolderId,
          holder.address,
          mockValue.div(2)
        );
      expect(await src20A.balanceOf(tokenHolder.address)).to.equal(
        mockValue.div(2)
      );
      expect(await tokenHolder.src20TransferOutNonce(tokenHolderId)).to.equal(
        1
      );
    });

    it("cannot transfer 0 value", async function () {
      await expect(
        tokenHolder.transferSRC20ToToken(src20A.address, tokenId, 0, "0x00")
      ).to.be.revertedWithCustomError(tokenHolder, "InvalidValue");

      await expect(
        tokenHolder.transferHeldSRC20FromToken(
          src20A.address,
          tokenId,
          holder.address,
          0,
          "0x00"
        )
      ).to.be.revertedWithCustomError(tokenHolder, "InvalidValue");
    });

    it("cannot transfer to address 0", async function () {
      await expect(
        tokenHolder.transferHeldSRC20FromToken(
          src20A.address,
          tokenId,
          silas.constants.AddressZero,
          1,
          "0x00"
        )
      ).to.be.revertedWithCustomError(tokenHolder, "InvalidAddress");
    });

    it("cannot transfer a token at address 0", async function () {
      await expect(
        tokenHolder.transferHeldSRC20FromToken(
          silas.constants.AddressZero,
          tokenId,
          holder.address,
          1,
          "0x00"
        )
      ).to.be.revertedWithCustomError(tokenHolder, "InvalidAddress");

      await expect(
        tokenHolder.transferSRC20ToToken(
          silas.constants.AddressZero,
          tokenId,
          1,
          "0x00"
        )
      ).to.be.revertedWithCustomError(tokenHolder, "InvalidAddress");
    });

    it("cannot transfer more balance than the token has", async function () {
      await src20A.approve(tokenHolder.address, mockValue);

      await tokenHolder.transferSRC20ToToken(
        src20A.address,
        tokenId,
        mockValue.div(2),
        "0x00"
      );
      await tokenHolder.transferSRC20ToToken(
        src20A.address,
        otherTokenHolderId,
        mockValue.div(2),
        "0x00"
      );
      await expect(
        tokenHolder.transferHeldSRC20FromToken(
          src20A.address,
          tokenId,
          holder.address,
          mockValue, // The token only owns half of this value
          "0x00"
        )
      ).to.be.revertedWithCustomError(tokenHolder, "InsufficientBalance");
    });

    it("cannot transfer balance from not owned token", async function () {
      await src20A.approve(tokenHolder.address, mockValue);
      await tokenHolder.transferSRC20ToToken(
        src20A.address,
        tokenHolderId,
        mockValue,
        "0x00"
      );
      // Other holder is not the owner of tokenId
      await expect(
        tokenHolder
          .connect(otherHolder)
          .transferHeldSRC20FromToken(
            src20A.address,
            tokenHolderId,
            otherHolder.address,
            mockValue,
            "0x00"
          )
      ).to.be.revertedWithCustomError(
        tokenHolder,
        "OnlyNFTOwnerCanTransferTokensFromIt"
      );
    });

    it("can manage multiple SRC20s", async function () {
      await src20B.mint(holder.address, mockValue);
      await src20A.approve(tokenHolder.address, mockValue);
      await src20B.approve(tokenHolder.address, mockValue);

      await tokenHolder.transferSRC20ToToken(
        src20A.address,
        tokenHolderId,
        silas.utils.parseSila("3"),
        "0x00"
      );
      await tokenHolder.transferSRC20ToToken(
        src20B.address,
        tokenHolderId,
        silas.utils.parseSila("5"),
        "0x00"
      );

      expect(
        await tokenHolder.balanceOfSRC20(src20A.address, tokenHolderId)
      ).to.equal(silas.utils.parseSila("3"));
      expect(
        await tokenHolder.balanceOfSRC20(src20B.address, tokenHolderId)
      ).to.equal(silas.utils.parseSila("5"));
    });
  });
});
