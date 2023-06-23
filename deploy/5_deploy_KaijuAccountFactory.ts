import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { Create2Factory } from "../src/Create2Factory";
const SAFE_PROXY_FACTORY = process.env.SAFE_PROXY_FACTORY
const deploySimpleAccountFactory: DeployFunction = async function (
  hre: HardhatRuntimeEnvironment
) {
  const provider = ethers.provider;
  const from = await provider.getSigner().getAddress();
  const network = await provider.getNetwork();

  await new Create2Factory(ethers.provider).deployFactory();
  let gnosisSafeSingletonAddr;
  let gnosisProxyFactoryAddr;
  let eip4337ManagerAddr;
  if (hre.network.name === "hardhat") {
    const gnosisProxyFactory = await hre.deployments.get("SafeProxyFactory");
    gnosisProxyFactoryAddr = gnosisProxyFactory.address;
    const gnosisSafeSingleton = await hre.deployments.get("Safe");
    gnosisSafeSingletonAddr = gnosisSafeSingleton.address;
  } else {
    const gnosisSafeSingleton = await hre.deployments.get("Safe");
    gnosisSafeSingletonAddr = gnosisSafeSingleton.address;
    gnosisProxyFactoryAddr = SAFE_PROXY_FACTORY;
  }
  const eip4337Manager = await hre.deployments.get("EIP4337Manager");
  eip4337ManagerAddr = eip4337Manager.address;
  if (!eip4337ManagerAddr) {
    return;
  }
  console.log("   SafeProxyFactory", gnosisProxyFactoryAddr);
  console.log("   Safe", gnosisSafeSingletonAddr);
  console.log("   EIP43337Manager", eip4337ManagerAddr);
  const ret = await hre.deployments.deploy("KaijuAccountFactory", {
    from,
    args: [gnosisProxyFactoryAddr, gnosisSafeSingletonAddr, eip4337ManagerAddr],
    gasLimit: 6e6,
    log: false,
    deterministicDeployment: true,
  });
  console.log(
    `✓ Successfully deployed KaijuAccountFactory to ${ret.address} in ${hre.network.name}`
  ); //✗
};

export default deploySimpleAccountFactory;
