import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { Create2Factory } from "../src/Create2Factory";

const deploySimpleAccountFactory: DeployFunction = async function (
  hre: HardhatRuntimeEnvironment
) {
  const provider = ethers.provider;
  const from = await provider.getSigner().getAddress();
  // const network = await provider.getNetwork();
  await new Create2Factory(ethers.provider).deployFactory();
  const ret = await hre.deployments.deploy("KaijuArcadeToken", {
    from:from,args: [
     from
    ],
    gasLimit: 6e6,
    log: false,
    deterministicDeployment: true,
  });
  console.log(
    `✓ Successfully deployed Kaiju Arcade Token to ${ret.address} in ${hre.network.name}`
  );
};

export default deploySimpleAccountFactory;
