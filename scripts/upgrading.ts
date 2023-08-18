import hre from "hardhat";
import "dotenv/config";

async function transferOwnership() {
    const multisigAddress = "0x14ADDeFA99223984396ddAE75Bf608A30a086074";
    const tokenProxyAdd = "0x7CC4689147a41f54b8504eC9Bbb9D9F656AD1D81";

    var UpgradeableToken = await hre.ethers.getContractFactory(
        "UpgradeableToken"
    );
    var upgradeableToken = UpgradeableToken.attach(tokenProxyAdd);

    console.log("Transferring ownership of ProxyAdmin...");
    await upgradeableToken.transferOwnership(multisigAddress);

    console.log("Transferred ownership of ProxyAdmin to:", multisigAddress);
}

async function proposeUpgrade() {
    const multisigAddress = "0x14ADDeFA99223984396ddAE75Bf608A30a086074";
    const tokenProxyAdd = "0x7CC4689147a41f54b8504eC9Bbb9D9F656AD1D81";

    const UpgradeableToken2 = await hre.ethers.getContractFactory(
        "UpgradeableToken2"
    );
    console.log("Preparing proposal...");
    const proposal = await defender.proposeUpgrade(
        tokenProxyAdd,
        UpgradeableToken2,
        { title: "Propose Upgrade to V2 for Token", multisig: multisigAddress }
    );
    console.log("Upgrade proposal created at:", proposal.url);
    console.log(
        "New Implementation Address:",
        proposal.metadata.newImplementationAddress
    );
}

// transferOwnership()
proposeUpgrade()
    //
    .catch((error) => {
        console.error(error);
        process.exitCode = 1;
    });
