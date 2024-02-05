import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from 'hardhat-deploy/types';
import { SmartAccountController_Example1 } from '../typechain-types';
// import { ContractTransactionReceipt, EventLog, Log } from 'ethers';

const Setup_SAC_EX1: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
	const { network, deployments, ethers } = hre;
  // const chainId = network.config.chainId ?? 1;

  // Load SmartAccountController_Example1
  const ex1: SmartAccountController_Example1 = await ethers.getContract('SmartAccountController_Example1');
  // const ex1Address = await ex1.getAddress();

  // TODO:
  // const tx = await ex1.setAllowedMethod();
  // const rc: ContractTransactionReceipt | null = await tx.wait();
  // if (rc !== null) {
  //   console.log(`    -- Allowed Method has been set...`);
  // }
  // console.log(` -- TODO: Set any Banned Methods on SmartAccountController_Example1`);

};
export default Setup_SAC_EX1;

Setup_SAC_EX1.dependencies = ['SAC_EX1'];
Setup_SAC_EX1.tags = ['Setup_SAC_EX1'];