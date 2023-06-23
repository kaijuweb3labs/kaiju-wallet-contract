import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { Create2Factory } from "../src/Create2Factory";
import { ethers } from "hardhat";

const deployEntryPoint: DeployFunction = async function (
  hre: HardhatRuntimeEnvironment
) {
  if (hre.network.name !== "hardhat") {
    console.log("Entrypoint deployment skipped!");
    return;
  }


  const provider = ethers.provider;
  const network = await provider.getNetwork();
  // only deploy on local test network.
  if (network.chainId !== 31337 && network.chainId !== 1337) {
    return;
  }
  const from = await provider.getSigner().getAddress();
  await new Create2Factory(ethers.provider).deployFactory();

  const ret = await hre.deployments.deploy("EntryPoint", {
    from,
    args: [],
    gasLimit: 6e6,
    deterministicDeployment: true,
  });
  console.log(
    `✓ Successfully deployed Entrypoint to ${ret.address} in ${hre.network.name}`
  );
};

export default deployEntryPoint;
