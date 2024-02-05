import {HardhatRuntimeEnvironment} from 'hardhat/types';
import {DeployFunction} from 'hardhat-deploy/types';

const BufficornZK_Deploy: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
	const {deployments, getNamedAccounts} = hre;
	const {deploy} = deployments;
	const {deployer} = await getNamedAccounts();

	await deploy('BufficornZK', {
		from: deployer,
		args: ["BufficornZK", "BZK"],
		log: true,
	});
};
export default BufficornZK_Deploy;

BufficornZK_Deploy.tags = ['BufficornZK'];
