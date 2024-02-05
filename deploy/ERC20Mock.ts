import {HardhatRuntimeEnvironment} from 'hardhat/types';
import {DeployFunction} from 'hardhat-deploy/types';

const ERC20Mock: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
	const {deployments, getNamedAccounts} = hre;
	const {deploy} = deployments;

	const { deployer } = await getNamedAccounts();

	await deploy('ERC20Mock', {
		from: deployer,
		args: [],
		log: true,
	});
};
export default ERC20Mock;

ERC20Mock.tags = ['ERC20Mock'];