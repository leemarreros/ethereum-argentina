import hre from "hardhat";
import "dotenv/config";

async function main() {
  var UpgradeableToken = await hre.ethers.getContractFactory(
    "UpgradeableToken"
  );
  var upgradeableToken = await hre.upgrades.deployProxy(UpgradeableToken, {
    kind: "uups",
  });

  await upgradeableToken.waitForDeployment();

  var implmntAddress = await hre.upgrades.erc1967.getImplementationAddress(
    await upgradeableToken.getAddress()
  );
  console.log("El Proxy address es (V1):", await upgradeableToken.getAddress());
  console.log("El Implementation address es (V1):", implmntAddress);

  await hre.run("verify:verify", {
    address: implmntAddress,
    constructorArguments: [],
  });
}

main()
  .catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
