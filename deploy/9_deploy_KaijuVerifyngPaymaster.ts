import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { ENTRYPOINT_ADDRESS } from "./4_deploy_EIP4337Manager";


const deploySimpleAccountFactory: DeployFunction = async function (
  hre: HardhatRuntimeEnvironment
) {
  const provider = ethers.provider;
  const from = await provider.getSigner().getAddress();
  // const network = await provider.getNetwork();
  const ret = await hre.deployments.deploy("KaijuVerifyingPaymaster", {
    from:from,
    args: [ENTRYPOINT_ADDRESS,process.env.VERIFYING_SIGNER],
    gasLimit: 6e6,
    log: false,
    deterministicDeployment: false,
  });
  console.log(
    `✓ Successfully deployed KaijuVerifyingPaymaster to ${ret.address} in ${hre.network.name}`
  );
};

export default deploySimpleAccountFactory;
