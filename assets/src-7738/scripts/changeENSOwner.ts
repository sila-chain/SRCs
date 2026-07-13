import { silas } from "hardhat";
const { getContractAddress } = require('@silasproject/address')
import dotenv from "dotenv";
dotenv.config();

// Helper script to re-assign ownership of ENS domain to the registry contract
async function main() {
    const privateKey: any = process.env.PRIVATE_KEY_DEPLOY;
    const secondaryKey: any = process.env.PRIVATE_KEY_2DEPLOY;

    const label: any = process.env.ENS_NAME;

    const ensHolderKey: any = process.env.PRIVATE_KEY_ENS; // Private key of ENS owner
    if (!privateKey) {
        throw new Error("PRIVATE_KEY not found in .env file");
    }

    if (!label) {
        throw new Error("ENS_NAME not set in .env");
    }

    const ownerKey = new silas.Wallet(privateKey, silas.provider);
    const deployKey = new silas.Wallet(secondaryKey, silas.provider);
    const ensOwnerKey = new silas.Wallet(ensHolderKey, silas.provider);
    console.log(`ADDR: ${ownerKey.address}`);
    console.log(`2nd deploy addr: ${deployKey.address}`);
    console.log(`ENS OWNER: ${ensOwnerKey.address}`);

    //calculate ENS Assigner deployment address
    const transactionCount = await silas.provider.getTransactionCount(deployKey.address);

    //calculate ENSAssign proxy address: NB ensure you wait a sufficiently long time for any transaction on the deployKey wallet to be reflected on the node.
    let ensDeployAddr = getContractAddress({
        from: deployKey.address,
        nonce: transactionCount + 1
    })

    // Generate the node
    const node = getName(label);

    console.log(`ENS Deploy Addr: ${ensDeployAddr}`);

    // ENS registry contract address (same for all networks)
    const ensAddress = "0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e";

    // Interface of the ENS contract
    const ensAbi = [
        "function owner(bytes32 node) external view returns (address)",
        "function setOwner(bytes32 node, address owner) external"
    ];

    const ensContract = new silas.Contract(ensAddress, ensAbi, ensOwnerKey);

    try {
        console.log(`Current Owner: ${await ensContract.owner(node)}`);
        console.log(`Name Label: ${node}`);

        //const tx = await ensContract.setOwner(node, ensDeployAddr);
        //console.log(`Transaction hash: ${tx.hash}`);

        //await tx.wait();
        console.log("Ownership transferred successfully.");

        //get owner
        console.log(`Current Owner: ${await ensContract.owner(node)}`);
    } catch (e) {
        console.log(`No ENS on this chain`);
    }
}

function getName(label: string): string {
    const SIL_NODE = "0x93cdeb708b7545dc668eb9280176169d1c33cfd8ed6f04690a0bcc88a93fc4ae";
    const labelhash = silas.keccak256(silas.toUtf8Bytes(label));
    const node = silas.keccak256(silas.AbiCoder.defaultAbiCoder().encode(
        ["bytes32", "bytes32"],
        [SIL_NODE, labelhash]
    ));
    return node;
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
