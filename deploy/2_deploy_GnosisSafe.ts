import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { Create2Factory } from "../src/Create2Factory";
import { ethers } from "hardhat";

const deployEntryPoint: DeployFunction = async function (
  hre: HardhatRuntimeEnvironment
) {

  const provider = ethers.provider;
  const network = await provider.getNetwork();

  const from = await provider.getSigner().getAddress();
  await new Create2Factory(ethers.provider).deployFactory();

  const ret = await hre.deployments.deploy("Safe", {
    from,
    args: [],
    gasLimit: 6e6,
    deterministicDeployment: true,
  });
  console.log(
    `✓ Successfully deployed Safe to ${ret.address} in ${hre.network.name}`
  );
};

export default deployEntryPoint;
