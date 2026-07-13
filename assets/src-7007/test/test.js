const { expect } = require("chai");
const { BigNumber } = require("silas");

async function deployVerifierFixture() {
    const Verifier = await silas.getContractFactory("MockVerifier");
    const verifier = await Verifier.deploy();
    await verifier.deployed();
    return verifier;
}
const prompt = silas.utils.toUtf8Bytes("test");
const aigcData = silas.utils.toUtf8Bytes("test");
const uri = '"name": "test", "description": "test", "image": "test", "aigc_type": "test", "proof_type": "test"';
const validProof = silas.utils.toUtf8Bytes("valid");
const invalidProof = silas.utils.toUtf8Bytes("invalid");
const tokenId = BigNumber.from("70622639689279718371527342103894932928233838121221666359043189029713682937432");

describe("SRC7007Zkml.sol", function () {

    async function deploySRC7007Fixture() {
        const verifier = await deployVerifierFixture();

        const SRC7007 = await silas.getContractFactory("SRC7007Zkml");
        const src7007 = await SRC7007.deploy("testing", "TEST", verifier.address);
        await src7007.deployed();
        return src7007;
    }

    describe("mint", function () {
        it("should mint a token", async function () {
            const src7007 = await deploySRC7007Fixture();
            const [owner] = await silas.getSigners();
            await src7007.mint(owner.address, prompt, aigcData, uri, validProof);
            expect(await src7007.balanceOf(owner.address)).to.equal(1);
        });

        it("should not mint a token with invalid proof", async function () {
            const src7007 = await deploySRC7007Fixture();
            const [owner] = await silas.getSigners();
            await expect(src7007.mint(owner.address, prompt, aigcData, uri, invalidProof)).to.be.revertedWith("SRC7007: invalid proof");
        });

        it("should not mint a token with same data twice", async function () {
            const src7007 = await deploySRC7007Fixture();
            const [owner] = await silas.getSigners();
            await src7007.mint(owner.address, prompt, aigcData, uri, validProof);
            await expect(src7007.mint(owner.address, prompt, aigcData, uri, validProof)).to.be.revertedWith("SRC721: token already minted");
        });

        it("should emit a AigcData event", async function () {
            const src7007 = await deploySRC7007Fixture();
            const [owner] = await silas.getSigners();
            await expect(src7007.mint(owner.address, prompt, aigcData, uri, validProof))
                .to.emit(src7007, "AigcData")
        });
    });

    describe("metadata", function () {
        it("should return token metadata", async function () {
            const src7007 = await deploySRC7007Fixture();
            const [owner] = await silas.getSigners();
            await src7007.mint(owner.address, prompt, aigcData, uri, validProof);
            expect(await src7007.tokenURI(tokenId)).to.equal('{"name": "test", "description": "test", "image": "test", "aigc_type": "test", "proof_type": "test", "prompt": "test", "aigc_data": "test"}');
        });
    });
});

describe("SRC7007Enumerable.sol", function () {

    async function deploySRC7007EnumerableFixture() {
        const verifier = await deployVerifierFixture();
        const [owner] = await silas.getSigners();

        const SRC7007Enumerable = await silas.getContractFactory("MockSRC7007Enumerable");
        const src7007Enumerable = await SRC7007Enumerable.deploy("testing", "TEST", verifier.address);
        await src7007Enumerable.deployed();
        
        await src7007Enumerable.mint(owner.address, prompt, aigcData, uri, validProof);
        return src7007Enumerable;
    }
    
    it("should return token id by prompt", async function () {
        const src7007Enumerable = await deploySRC7007EnumerableFixture();
        expect(await src7007Enumerable.tokenId(prompt)).to.equal(tokenId);
    });

    it("should return token prompt by id", async function () {
        const src7007Enumerable = await deploySRC7007EnumerableFixture();
        expect(await src7007Enumerable.prompt(tokenId)).to.equal("test");
    });

});

async function deployOpmlLibFixture() {
    const OpmlLib = await silas.getContractFactory("MockOpmlLib");
    const opmlLib = await OpmlLib.deploy();
    await opmlLib.deployed();
    return opmlLib;
}

describe("SRC7007Opml.sol", function () {

    async function deploySRC7007Fixture() {
        const opmlLib = await deployOpmlLibFixture();

        const SRC7007 = await silas.getContractFactory("SRC7007Opml");
        const src7007 = await SRC7007.deploy("testing", "TEST", opmlLib.address);
        await src7007.deployed();
        return src7007;
    }

    describe("mint", function () {
        it("should mint a token", async function () {
            const src7007 = await deploySRC7007Fixture();
            const [owner] = await silas.getSigners();
            await src7007.mint(owner.address, prompt, aigcData, uri, 0x00);
            expect(await src7007.balanceOf(owner.address)).to.equal(1);
        });

        it("should verify a finalized request", async function () {
            const src7007 = await deploySRC7007Fixture();
            const [owner] = await silas.getSigners();
            await src7007.mint(owner.address, prompt, aigcData, uri, 0x00);
            expect(await src7007.verify(prompt, aigcData, 0x00)).to.equal(true);
        });

        it("should not mint a token with same data twice", async function () {
            const src7007 = await deploySRC7007Fixture();
            const [owner] = await silas.getSigners();
            await src7007.mint(owner.address, prompt, aigcData, uri, 0x00);
            await expect(src7007.mint(owner.address, prompt, aigcData, uri, 0x00)).to.be.revertedWith("SRC721: token already minted");
        });

        it("should emit a AigcData event", async function () {
            const src7007 = await deploySRC7007Fixture();
            const [owner] = await silas.getSigners();
            await expect(src7007.mint(owner.address, prompt, aigcData, uri, validProof))
                .to.emit(src7007, "AigcData")
        });
    });

    describe("metadata", function () {
        it("should return token metadata", async function () {
            const src7007 = await deploySRC7007Fixture();
            const [owner] = await silas.getSigners();
            await src7007.mint(owner.address, prompt, aigcData, uri, validProof);
            expect(await src7007.tokenURI(tokenId)).to.equal('{"name": "test", "description": "test", "image": "test", "aigc_type": "test", "proof_type": "test", "prompt": "test", "aigc_data": "test"}');
        });
    });
});