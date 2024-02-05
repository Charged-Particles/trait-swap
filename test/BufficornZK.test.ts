import { expect } from "chai";
import { ethers, network, getNamedAccounts, deployments } from 'hardhat';
import { ChargedParticles, BufficornZK, IERC6551Registry, ERC20Mock, NFTMock } from "../typechain-types";

describe('BufficornZK', async function () {
  const REGISTRY = 	'0x000000006551c19487814612e58FE06813775758'; // ERC6551Registry - Same on All Chains
  const salt = ethers.encodeBytes32String('');

  // Contracts
  let chargedParticles: ChargedParticles;
  let registryContract: IERC6551Registry;
  let bufficorn: BufficornZK;

  // Addresses
  let chargedParticlesAddress: string;
  let bufficornAddress: string;

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
    await deployments.fixture([ 'Setup_Bufficorn', 'Setup_SAC_EX1', 'NFTMock', 'ERC20Mock' ]);

    chargedParticles = await ethers.getContract('ChargedParticles');
    bufficorn = await ethers.getContract('BufficornZK');

    registryContract = await ethers.getContractAt('IERC6551Registry', REGISTRY);

    chargedParticlesAddress = await chargedParticles.getAddress();
    bufficornAddress = await bufficorn.getAddress();
  });


  it('Deploys BufficornZK', async function () {
    const bufficornAddress = await bufficorn.getAddress();
    expect(bufficornAddress).to.not.be.empty;
  });


  it('Manages Trait-Swapping when NFTs are Added and Removed', async function () {
    const bufficornTokenId = 1;

    // Mint a Bufficorn NFT
    await bufficorn.mint(bufficornTokenId).then(tx => tx.wait()); // Token ID: 1
    expect(await bufficorn.balanceOf(deployer)).to.be.equal(bufficornTokenId);

    // Confirm Zero Traits
    expect(await bufficorn.getTraits(bufficornTokenId)).to.be.equal(0);

    // Mint some Bufficorn Trait-NFTs
    await bufficorn.mintWithTraits(2, 1n)  //  Token ID: 2, Trait-bit = 00000001
    await bufficorn.mintWithTraits(3, 2n)  //  Token ID: 3, Trait-bit = 00000010
    await bufficorn.mintWithTraits(4, 4n)  //  Token ID: 4, Trait-bit = 00000100
    await bufficorn.mintWithTraits(5, 8n)  //  Token ID: 5, Trait-bit = 00001000
    await bufficorn.mintWithTraits(6, 16n) //  Token ID: 6, Trait-bit = 00010000
    expect(await bufficorn.balanceOf(deployer)).to.be.equal(6);

    // Confirm Traits
    expect(await bufficorn.getTraits(2)).to.be.equal(1n);
    expect(await bufficorn.getTraits(3)).to.be.equal(2n);
    expect(await bufficorn.getTraits(4)).to.be.equal(4n);
    expect(await bufficorn.getTraits(5)).to.be.equal(8n);
    expect(await bufficorn.getTraits(6)).to.be.equal(16n);

    // Calculate Expected Account Address via Registry
    const newAccountAddress = await calculateAccountAddress(bufficornAddress, bufficornTokenId);
    expect(newAccountAddress).to.not.be.empty;

    // Give permission to Bond
    await bufficorn.approve(chargedParticlesAddress, 2).then(tx => tx.wait());
    await bufficorn.approve(chargedParticlesAddress, 3).then(tx => tx.wait());
    await bufficorn.approve(chargedParticlesAddress, 4).then(tx => tx.wait());
    await bufficorn.approve(chargedParticlesAddress, 5).then(tx => tx.wait());
    await bufficorn.approve(chargedParticlesAddress, 6).then(tx => tx.wait());

    // Bond Trait 1 to Bufficorn
    await chargedParticles.covalentBond(bufficornAddress, bufficornTokenId, bufficornAddress, 2, 1n).then(tx => tx.wait());

    // Confirm Nested Trait-NFT Owner
    expect(await bufficorn.ownerOf(2)).to.be.eq(newAccountAddress);

    // Confirm Bufficorn Traits
    expect(await bufficorn.getTraits(bufficornTokenId)).to.be.eq(1n); // Bufficorn has a Single Trait (00000001)

    // Bond and Confirm Trait 2
    await chargedParticles.covalentBond(bufficornAddress, bufficornTokenId, bufficornAddress, 3, 1n).then(tx => tx.wait());
    expect(await bufficorn.ownerOf(3)).to.be.eq(newAccountAddress);
    expect(await bufficorn.getTraits(bufficornTokenId)).to.be.eq(3n); // Bufficorn has 2 Traits (00000011)

    // Bond and Confirm Trait 3
    await chargedParticles.covalentBond(bufficornAddress, bufficornTokenId, bufficornAddress, 4, 1n).then(tx => tx.wait());
    expect(await bufficorn.ownerOf(4)).to.be.eq(newAccountAddress);
    expect(await bufficorn.getTraits(bufficornTokenId)).to.be.eq(7n); // Bufficorn has 3 Traits (00000111)

    // Bond and Confirm Trait 4
    await chargedParticles.covalentBond(bufficornAddress, bufficornTokenId, bufficornAddress, 5, 1n).then(tx => tx.wait());
    expect(await bufficorn.ownerOf(5)).to.be.eq(newAccountAddress);
    expect(await bufficorn.getTraits(bufficornTokenId)).to.be.eq(15n); // Bufficorn has 4 Traits (00001111)

    // Bond and Confirm Trait 5
    await chargedParticles.covalentBond(bufficornAddress, bufficornTokenId, bufficornAddress, 6, 1n).then(tx => tx.wait());
    expect(await bufficorn.ownerOf(6)).to.be.eq(newAccountAddress);
    expect(await bufficorn.getTraits(bufficornTokenId)).to.be.eq(31n); // Bufficorn has 5 Traits (00011111)


    // Break-Bond Trait 3 from Bufficorn
    await chargedParticles.breakCovalentBond(deployer, bufficornAddress, bufficornTokenId, bufficornAddress, 4, 1n).then(tx => tx.wait());

    // Confirm Nested Trait-NFT Owner
    expect(await bufficorn.ownerOf(4)).to.be.eq(deployer);

    // Confirm Bufficorn Traits
    expect(await bufficorn.getTraits(bufficornTokenId)).to.be.eq(27n); // Bufficorn has 4 Traits (00011011)

    // Break-Bond and Confirm Trait 2 Removed
    await chargedParticles.breakCovalentBond(deployer, bufficornAddress, bufficornTokenId, bufficornAddress, 3, 1n).then(tx => tx.wait());
    expect(await bufficorn.ownerOf(3)).to.be.eq(deployer);
    expect(await bufficorn.getTraits(bufficornTokenId)).to.be.eq(25n); // Bufficorn has 3 Traits (00011001)

    // Break-Bond and Confirm Trait 5 Removed
    await chargedParticles.breakCovalentBond(deployer, bufficornAddress, bufficornTokenId, bufficornAddress, 6, 1n).then(tx => tx.wait());
    expect(await bufficorn.ownerOf(6)).to.be.eq(deployer);
    expect(await bufficorn.getTraits(bufficornTokenId)).to.be.eq(9n); // Bufficorn has 2 Traits (00001001)

    // Break-Bond and Confirm Trait 1 Removed
    await chargedParticles.breakCovalentBond(deployer, bufficornAddress, bufficornTokenId, bufficornAddress, 2, 1n).then(tx => tx.wait());
    expect(await bufficorn.ownerOf(2)).to.be.eq(deployer);
    expect(await bufficorn.getTraits(bufficornTokenId)).to.be.eq(8n); // Bufficorn has 1 Trait (00001000)

    // Break-Bond and Confirm Trait 4 Removed
    await chargedParticles.breakCovalentBond(deployer, bufficornAddress, bufficornTokenId, bufficornAddress, 5, 1n).then(tx => tx.wait());
    expect(await bufficorn.ownerOf(5)).to.be.eq(deployer);
    expect(await bufficorn.getTraits(bufficornTokenId)).to.be.eq(0); // Bufficorn has 0 Traits (00000000)

    // Confirm Owner of all NFTs
    expect(await bufficorn.balanceOf(deployer)).to.be.equal(6);
  });

  it('includes the Traits in the TokenURI', async function () {
    const bufficornTokenId = 1;

    // Mint a Bufficorn NFT
    await bufficorn.mint(bufficornTokenId).then(tx => tx.wait()); // Token ID: 1
    expect(await bufficorn.balanceOf(deployer)).to.be.equal(bufficornTokenId);

    // Confirm Zero Traits
    expect(await bufficorn.getTraits(bufficornTokenId)).to.be.equal(0);

    // Mint some Bufficorn Trait-NFTs
    await bufficorn.mintWithTraits(2, 1n)  //  Token ID: 2, Trait-bit = 00000001
    await bufficorn.mintWithTraits(3, 2n)  //  Token ID: 3, Trait-bit = 00000010
    await bufficorn.mintWithTraits(4, 4n)  //  Token ID: 4, Trait-bit = 00000100
    await bufficorn.mintWithTraits(5, 8n)  //  Token ID: 5, Trait-bit = 00001000
    await bufficorn.mintWithTraits(6, 16n) //  Token ID: 6, Trait-bit = 00010000
    expect(await bufficorn.balanceOf(deployer)).to.be.equal(6);

    // Calculate Expected Account Address via Registry
    const newAccountAddress = await calculateAccountAddress(bufficornAddress, bufficornTokenId);
    expect(newAccountAddress).to.not.be.empty;

    // Give permission to Bond
    await bufficorn.approve(chargedParticlesAddress, 2).then(tx => tx.wait());
    await bufficorn.approve(chargedParticlesAddress, 3).then(tx => tx.wait());
    await bufficorn.approve(chargedParticlesAddress, 4).then(tx => tx.wait());
    await bufficorn.approve(chargedParticlesAddress, 5).then(tx => tx.wait());
    await bufficorn.approve(chargedParticlesAddress, 6).then(tx => tx.wait());

    // Bond Traits to Bufficorn
    await chargedParticles.covalentBond(bufficornAddress, bufficornTokenId, bufficornAddress, 2, 1n).then(tx => tx.wait());
    await chargedParticles.covalentBond(bufficornAddress, bufficornTokenId, bufficornAddress, 3, 1n).then(tx => tx.wait());
    await chargedParticles.covalentBond(bufficornAddress, bufficornTokenId, bufficornAddress, 4, 1n).then(tx => tx.wait());
    await chargedParticles.covalentBond(bufficornAddress, bufficornTokenId, bufficornAddress, 5, 1n).then(tx => tx.wait());
    await chargedParticles.covalentBond(bufficornAddress, bufficornTokenId, bufficornAddress, 6, 1n).then(tx => tx.wait());

    // Confirm Token URI includes Traits
    const tokenUri = await bufficorn.tokenURI(bufficornTokenId);
    expect(tokenUri).to.be.equal('http://www.bufficorn-zk.com/1/31');
  });
});
