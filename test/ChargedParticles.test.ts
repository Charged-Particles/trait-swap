import { expect } from "chai";
import { ethers, network, getNamedAccounts, deployments } from 'hardhat';
import { ChargedParticles, IERC6551Registry, ERC20Mock, NFTMock } from "../typechain-types";

describe('ChargedParticles', async function () {
  const REGISTRY = 	'0x000000006551c19487814612e58FE06813775758'; // ERC6551Registry - Same on All Chains
  const salt = ethers.encodeBytes32String('');
  const interfaceIds = {
    ISmartAccount:            '0x2f62b227',
    ISmartAccountController:  '0x39b43188',
    IChargedParticles:        '0xfb86e1eb',
    IDynamicTraits:           '0x33c2cbef',
  };

  // Contracts
  let chargedParticles: ChargedParticles;
  let registryContract: IERC6551Registry;
  let nftMock: NFTMock;
  let erc20Mock: ERC20Mock;

  // Addresses
  let chargedParticlesAddress: string;
  let nftMockAddress: string;
  let erc20MockAddress: string;

  // Signers
  let deployer: string;
  let receiver: string;

  const calculateAccountAddress = async (nftContractAddress: string, nftTokenId: number) => {
    const smartAccountImplementation = await chargedParticles.getAccountImplementation(nftContractAddress);
    const newAccountAddress = await registryContract.account(
      smartAccountImplementation,
      salt,
      network.config.chainId ?? 1,
      nftContractAddress,
      nftTokenId,
    );
    return newAccountAddress;
  };

  before(async function () {
    const { deployer: deployerAccount, user1 } = await getNamedAccounts();
    deployer = deployerAccount;
    receiver = user1;
  });

  beforeEach(async function () {
    await deployments.fixture([ 'Setup_CPU', 'Setup_SAC_EX1', 'NFTMock', 'ERC20Mock' ]);

    chargedParticles = await ethers.getContract('ChargedParticles');
    nftMock = await ethers.getContract('NFTMock');
    erc20Mock = await ethers.getContract('ERC20Mock');

    registryContract = await ethers.getContractAt('IERC6551Registry', REGISTRY);

    nftMockAddress = await nftMock.getAddress();
    erc20MockAddress = await erc20Mock.getAddress();
    chargedParticlesAddress = await chargedParticles.getAddress();
  });


  it('Deploys ChargedParticles', async function () {
    const chargedParticlesAddress = await chargedParticles.getAddress();
    expect(chargedParticlesAddress).to.not.be.empty;
  });


  it('Deploys a SmartAccount for an NFT', async function () {
    const tokenId = 1;

    await nftMock.mint(deployer, tokenId).then(tx => tx.wait());
    expect(await nftMock.balanceOf(deployer)).to.be.equal(1);

    await erc20Mock.mint(deployer, 10000n).then(tx => tx.wait());
    expect(await erc20Mock.balanceOf(deployer)).to.be.equal(10000n);

    // Calculate Expected Account Address via Registry
    const newAccountAddress = await calculateAccountAddress(nftMockAddress, tokenId);
    expect(newAccountAddress).to.not.be.empty;

    // Energize NFT in order to Create new Smart Account
    await erc20Mock.approve(chargedParticlesAddress, 100n).then(tx => tx.wait());
    const newAccountReceipt = await chargedParticles.energizeParticle(
      nftMockAddress,
      tokenId,
      erc20MockAddress,
      100n,
    ).then(tx => tx.wait());
    expect(newAccountReceipt).to.haveOwnProperty('hash');

    // Confirm new SmartAccount was actually created
    const smartAccountCode = await ethers.provider.getCode(newAccountAddress);
    expect(smartAccountCode.replace('0x', '')).to.not.be.empty;

    // Confirm SmartAccount Supports correct Interface
    const smartAccountContract = await ethers.getContractAt('SmartAccount', newAccountAddress);
    const isSmartAccount = await smartAccountContract.supportsInterface(interfaceIds.ISmartAccount);
    expect(isSmartAccount).to.be.true;

    // Confirm SmartAccount knows its Parent Token
    const smartAccountToken = await smartAccountContract.token();
    expect(smartAccountToken).to.be.lengthOf(3);
    expect(smartAccountToken[0]).to.be.equal(network.config.chainId);
    expect(smartAccountToken[1]).to.be.equal(nftMockAddress);
    expect(smartAccountToken[2]).to.be.equal(tokenId);
  });


  it('Energizes and Releases an NFT', async function () {
    const tokenId = 1;

    await nftMock.mint(deployer, tokenId).then(tx => tx.wait());
    expect(await nftMock.balanceOf(deployer)).to.be.equal(1);

    await erc20Mock.mint(deployer, 10000n).then(tx => tx.wait());
    expect(await erc20Mock.balanceOf(deployer)).to.be.equal(10000n);

    // Calculate Expected Account Address via Registry
    const newAccountAddress = await calculateAccountAddress(nftMockAddress, tokenId);
    expect(newAccountAddress).to.not.be.empty;

    // Energize NFT
    await erc20Mock.approve(chargedParticlesAddress, 10000n).then(tx => tx.wait());
    await chargedParticles.energizeParticle(
      nftMockAddress,
      tokenId,
      erc20MockAddress,
      1500n,
    ).then(tx => tx.wait());
    expect(await erc20Mock.balanceOf(newAccountAddress)).to.be.equal(1500n);
    expect(await erc20Mock.balanceOf(deployer)).to.be.equal(8500n);

    // Release NFT by Amount
    await chargedParticles.releaseParticleAmount(
      deployer,
      nftMockAddress,
      tokenId,
      erc20MockAddress,
      500n,
    ).then(tx => tx.wait());
    expect(await erc20Mock.balanceOf(newAccountAddress)).to.be.equal(1000n);
    expect(await erc20Mock.balanceOf(deployer)).to.be.equal(9000n);

    // Release Remainder from NFT
    await chargedParticles.releaseParticle(
      deployer,
      nftMockAddress,
      tokenId,
      erc20MockAddress,
    ).then(tx => tx.wait());
    expect(await erc20Mock.balanceOf(newAccountAddress)).to.be.equal(0);
    expect(await erc20Mock.balanceOf(deployer)).to.be.equal(10000n);
  });


  it('Bonds and Breaks an NFT', async() => {
    const tokenId = 1;
    const depositedTokenId = 2;

    await nftMock.mint(deployer, tokenId).then(tx => tx.wait());
    await nftMock.mint(deployer, depositedTokenId).then(tx => tx.wait());
    expect(await nftMock.balanceOf(deployer)).to.be.equal(2);

    // Calculate Expected Account Address via Registry
    const newAccountAddress = await calculateAccountAddress(nftMockAddress, tokenId);
    expect(newAccountAddress).to.not.be.empty;

    // Give permission to Bond
    await nftMock.approve(chargedParticlesAddress, depositedTokenId).then(tx => tx.wait());
    expect(await nftMock.getApproved(depositedTokenId)).to.be.eq(chargedParticlesAddress);

    // Bond
    const bondReceipt = await chargedParticles.covalentBond(
      nftMockAddress,
      tokenId,
      nftMockAddress,
      depositedTokenId,
      1n // amount
    ).then(tx => tx.wait());
    expect(bondReceipt).to.haveOwnProperty('hash');

    // Confirm Nested NFT Owner
    expect(await nftMock.ownerOf(depositedTokenId)).to.be.eq(newAccountAddress);

    // Break-Bond
    const breakReceipt = await chargedParticles.breakCovalentBond(
      receiver,
      nftMockAddress,
      tokenId,
      nftMockAddress,
      depositedTokenId,
      1
    ).then(tx => tx.wait());
    expect(breakReceipt).to.haveOwnProperty('hash');

    // Confirm New Owner
    expect(await nftMock.ownerOf(depositedTokenId)).to.be.eq(receiver);
  });
});
