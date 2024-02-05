import {HardhatRuntimeEnvironment} from 'hardhat/types';
import {DeployFunction} from 'hardhat-deploy/types';

const ChargedParticles_Deploy: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
	const {deployments, getNamedAccounts} = hre;
	const {deploy} = deployments;
	const {deployer} = await getNamedAccounts();

	await deploy('ChargedParticles', {
		from: deployer,
		args: ['0x000000006551c19487814612e58FE06813775758'], // ERC6551Registry - Same on All Chains
		log: true,
	});
};
export default ChargedParticles_Deploy;

ChargedParticles_Deploy.tags = ['ChargedParticles'];
