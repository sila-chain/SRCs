const {deployContracts} = require("../scripts/deploy_contracts");
const {expect} = require('chai');

describe("SRC6786", () => {

    let src721Royalty;
    let src721;
    let royaltyDebtRegistry;
    const tokenId = 666;

    beforeEach(async () => {
        const contracts = await deployContracts();
        src721Royalty = contracts.src721Royalty;
        src721 = contracts.src721;
        royaltyDebtRegistry = contracts.royaltyDebtRegistry;
    })

    it('should support SRC6786 interface', async () => {
        await expect(await royaltyDebtRegistry.supportsInterface("0x253b27b0")).to.be.true;
    })

    it('should allow paying royalties for a SRC2981 NFT', async () => {
        await expect(royaltyDebtRegistry.payRoyalties(
            src721Royalty.address,
            tokenId,
            {value: 1000}
        )).to.emit(royaltyDebtRegistry, 'RoyaltiesPaid')
            .withArgs(src721Royalty.address, tokenId, 1000);
    })

    it('should not allow paying royalties for a non-SRC2981 NFT', async () => {
        await expect(royaltyDebtRegistry.payRoyalties(
            src721.address,
            tokenId,
            {value: 1000}
        )).to.be.revertedWithCustomError(royaltyDebtRegistry,'CreatorError')
            .withArgs(src721.address, tokenId);
    })

    it('should allow retrieving initial royalties amount for a NFT', async () => {
        await expect(await royaltyDebtRegistry.getPaidRoyalties(
            src721Royalty.address,
            tokenId
        )).to.equal(0);
    })

    it('should allow retrieving royalties amount after payments for a NFT', async () => {
        await royaltyDebtRegistry.payRoyalties(
            src721Royalty.address,
            tokenId,
            {value: 2000}
        );

        await royaltyDebtRegistry.payRoyalties(
            src721Royalty.address,
            tokenId,
            {value: 3666}
        )

        await expect(await royaltyDebtRegistry.getPaidRoyalties(
            src721Royalty.address,
            tokenId
        )).to.equal(5666);
    })
});
