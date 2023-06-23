import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { Create2Factory } from "../src/Create2Factory";

const deploySimpleAccountFactory: DeployFunction = async function (
  hre: HardhatRuntimeEnvironment
) {
  return
  const provider = ethers.provider;
  const from = await provider.getSigner().getAddress();
  const network = await provider.getNetwork();
  await new Create2Factory(ethers.provider).deployFactory();
  // only deploy on local test network.
  // if (network.chainId !== 31337 && network.chainId !== 1337) {
  //   return;
  // }
  const guardianStorage = await hre.deployments.get("GuardianStorage");
  const ret = await hre.deployments.deploy("KaijuAccountRecoveryModule", {
    from,
    args: [
      guardianStorage.address,
      300, //5 minute recovery period
    ],
    gasLimit: 6e6,
    log: false,
    deterministicDeployment: true,
  });
  console.log(
    `✓ Successfully deployed KaijuAccountRecoveryModule to ${ret.address} in ${hre.network.name}`
  );
};

export default deploySimpleAccountFactory;
