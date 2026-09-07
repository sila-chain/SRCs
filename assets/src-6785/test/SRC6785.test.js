const {deployContracts} = require("../scripts/deploy_contracts");
const {expect} = require('chai');

describe('SRC6785', () => {
    let src6785;
    const tokenId = 123;
    const utilityUrl1 = 'https://utility.url';

    beforeEach(async () => {
        src6785 = await deployContracts();
    });

    it('should support SRC6785 interface', async () => {
        await expect(await src6785.supportsInterface(
            await src6785._INTERFACE_ID_SRC6785(),
        )).to.be.true;
    });

    it('should allow setting first utility NFT', async () => {
        await expect(src6785.setUtilityUri(
            tokenId,
            utilityUrl1,
        )).to.emit(src6785, 'UpdateUtility').withArgs(tokenId, utilityUrl1);
    });

    it('should allow retrieving initial royalties amount for a NFT',
        async () => {
            await expect(src6785.setUtilityUri(
                tokenId,
                utilityUrl1,
            )).to.emit(src6785, 'UpdateUtility').withArgs(tokenId, utilityUrl1);

            await expect(await src6785.utilityUriOf(
                tokenId,
            )).to.equal(utilityUrl1);
    })

    it('should allow retrieving utility history for the NFT', async () => {
        await expect(src6785.setUtilityUri(
            tokenId,
            utilityUrl1,
        )).to.emit(src6785, 'UpdateUtility').withArgs(tokenId, utilityUrl1);
        let utilityUrl2 = utilityUrl1 + '_2';
        await expect(src6785.setUtilityUri(
            tokenId,
            utilityUrl2,
        )).to.emit(src6785, 'UpdateUtility').withArgs(tokenId, utilityUrl2);

        let history = await src6785.utilityHistoryOf(
            tokenId,
        );
        await expect(history.length).to.equal(2);
        await expect(history[0]).to.equal(utilityUrl1);
        await expect(history[1]).to.equal(utilityUrl2);
    })
});
