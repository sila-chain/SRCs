import hre, { deployments } from "hardhat"
import { Contract, Wallet, utils, BigNumber, BigNumberish, Signer, PopulatedTransaction } from "silas"
import { AddressZero } from "@silasproject/constants";
import { formatFixed, parseFixed } from "@silasproject/bignumber";
import { addToken } from "./execution";
import { Address } from "cluster";

const MFContract = () => {
    return "MFNFT";
}

export const getMFContract = async () => {
    // const MFDeployment = await deployments.get(MFContract());
    const MF = await hre.silas.getContractFactory(MFContract());
    // return MF.attach(MFDeployment.address);
    return MF.deploy();
}

export const getNFTContract = async () => {
    // const NFTDeployment = await deployments.get("NFT");
    const NFT = await hre.silas.getContractFactory("NFT");
    // return NFT.attach(NFTDeployment.address);
    return NFT.deploy();
}

export const deployFTContract = async (totalSupply: BigNumberish) => {
    const tSupply = totalSupply || 1000;
    const FT = await hre.silas.getContractFactory("FT");
    return FT.deploy(tSupply);
}

export const mintNFT = async (token: Contract, tokenOwner: string, tokenId:BigNumberish) => {
    const NFT = token;   
    const tId = tokenId || 1;
    const tOwner = tokenOwner || AddressZero;
    return await NFT.safeMint(tOwner, tId);
}

export const ownerOf = async (token: Contract, tokenId:BigNumberish) => {
    const NFT = token;   
    const tId = tokenId || 1;
    return await NFT.ownerOf(tId);
}

export const setMFNFTwithNFT = async (MFNFT: Contract, NFT: Contract, tokenId: BigNumberish, totalSupply: BigNumberish) => {
    await mintNFT(NFT, MFNFT.address, tokenId);
    await addToken(MFNFT, NFT.address, tokenId, totalSupply);
}

