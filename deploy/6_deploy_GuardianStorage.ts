import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { Create2Factory } from "../src/Create2Factory";

const deploySimpleAccountFactory: DeployFunction = async function (
  hre: HardhatRuntimeEnvironment
) {
  return
  const provider = ethers.provider;
  await new Create2Factory(ethers.provider).deployFactory();
  const from = await provider.getSigner().getAddress();
  const network = await provider.getNetwork();
  const ret = await hre.deployments.deploy("GuardianStorage", {
    from,
    args: [],
    gasLimit: 6e6,
    log: false,
    deterministicDeployment: true,
  });
  console.log(
    `✓ Successfully deployed GuardianStorage to ${ret.address} in ${hre.network.name}`
  );
};

export default deploySimpleAccountFactory;
