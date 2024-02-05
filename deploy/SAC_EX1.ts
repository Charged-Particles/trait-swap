import {HardhatRuntimeEnvironment} from 'hardhat/types';
import {DeployFunction} from 'hardhat-deploy/types';

const SAC_EX1_Deploy: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
	const {deployments, getNamedAccounts} = hre;
	const {deploy} = deployments;

	const { deployer } = await getNamedAccounts();

	await deploy('SmartAccountController_Example1', {
		from: deployer,
		args: [],
		log: true,
	});
};
export default SAC_EX1_Deploy;

SAC_EX1_Deploy.tags = ['SAC_EX1'];
