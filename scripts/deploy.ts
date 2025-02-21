import { getInitialTestAccountsWallets } from '@aztec/accounts/testing';
import { 
    createPXEClient, 
    waitForPXE, 
    AztecAddress,
    Contract,
    DeployMethod 
} from '@aztec/aztec.js';
import { ContractArtifact } from '@aztec/noir-contracts/types';

// Contract artifactlarını import et
import HADArtifact from '../target/had_contract.json';
import HADBridgeArtifact from '../target/had_bridge.json';

// LayerZero endpoint adresleri
const LAYERZERO_ENDPOINTS = {
    "goerli": "0xbfD2135BFfbb0B5378b56643c2Df8a87552Bfa23",
    "mumbai": "0xf69186dfBa60DdB133E91E9A4B5673624293d8F8",
    "arbitrum-goerli": "0x6aB5Ae6822647046626e83ee6dB8187151E1d5ab",
    "optimism-goerli": "0xae92d5aD7583AD66E49A0c67BAd18F6ba52dDDc1",
    "bsc-testnet": "0x6Fcb97553D41516Cb228ac03FdC8B9a0a9df04A1"
};

// Kullanmak istediğiniz ağı seçin
const SELECTED_NETWORK = "goerli"; // veya "mumbai", "arbitrum-goerli" vs.
const LAYERZERO_ENDPOINT_ADDRESS = AztecAddress.fromString(LAYERZERO_ENDPOINTS[SELECTED_NETWORK]);

async function main() {
    // PXE client'ı başlat
    const pxe = await createPXEClient('http://localhost:8080');
    await waitForPXE(pxe);
    
    const wallets = await getInitialTestAccountsWallets(pxe);
    const ownerWallet = wallets[0];
    const ownerAddress = await ownerWallet.getAddress();

    console.log('Deploying HAD NFT contract...');

    // HAD NFT kontratını deploy et
    const hadContract = new Contract(
        'HAD',
        HADArtifact as ContractArtifact,
        ownerWallet
    );

    const deployTx = await hadContract.deploy(ownerAddress).send();
    const deployReceipt = await deployTx.wait();
    
    console.log(`HAD NFT deployed at: ${deployReceipt.contractAddress}`);

    console.log('Deploying HAD Bridge contract...');

    // Bridge kontratını deploy et
    const hadBridge = new Contract(
        'HADBridge',
        HADBridgeArtifact as ContractArtifact,
        ownerWallet
    );

    const bridgeDeployTx = await hadBridge.deploy(
        deployReceipt.contractAddress,
        LAYERZERO_ENDPOINT_ADDRESS
    ).send();
    const bridgeDeployReceipt = await bridgeDeployTx.wait();
    
    console.log(`HAD Bridge deployed at: ${bridgeDeployReceipt.contractAddress}`);
}

main().catch((err) => {
    console.error('Deployment failed:', err);
    process.exit(1);
}); 