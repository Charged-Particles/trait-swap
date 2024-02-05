import {HardhatRuntimeEnvironment} from 'hardhat/types';
import {DeployFunction} from 'hardhat-deploy/types';

const NFTMockMock: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
	const {deployments, getNamedAccounts} = hre;
	const {deploy} = deployments;

	const { deployer } = await getNamedAccounts();

	await deploy('NFTMock', {
		from: deployer,
		args: ['Game of NTF', 'GONFT'],
		log: true,
	});
};
export default NFTMockMock;

NFTMockMock.tags = ['NFTMock'];