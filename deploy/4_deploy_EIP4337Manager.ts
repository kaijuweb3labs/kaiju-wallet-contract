import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { Create2Factory } from "../src/Create2Factory";
import { ethers } from "hardhat";
export const ENTRYPOINT_ADDRESS = process.env.ENTRYPOINT_ADDRESS
const deployEntryPoint: DeployFunction = async function (
  hre: HardhatRuntimeEnvironment
) {

  const provider = ethers.provider;
  const network = await provider.getNetwork();

  const from = await provider.getSigner().getAddress();
  await new Create2Factory(ethers.provider).deployFactory();
  let entrypointAddr = ENTRYPOINT_ADDRESS;
  if (hre.network.name === "hardhat") {
    const entrypoint = await hre.deployments.get("EntryPoint");
    entrypointAddr = entrypoint.address;
  }

  const ret = await hre.deployments.deploy("EIP4337Manager", {
    from,
    args: [entrypointAddr],
    gasLimit: 6e6,
    deterministicDeployment: true,
  });
  console.log(
    `✓ Successfully deployed EIP4337Manager to ${ret.address} in ${hre.network.name}`
  );
};

export default deployEntryPoint;
