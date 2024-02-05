// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import {IERC6551Registry} from "./interfaces/IERC6551Registry.sol";
import {IChargedParticles} from "./interfaces/IChargedParticles.sol";
import {NftTokenInfo} from "./lib/NftTokenInfo.sol";
import {ISmartAccount} from "./interfaces/ISmartAccount.sol";
import {ISmartAccountController} from "./interfaces/ISmartAccountController.sol";
import {IDynamicTraits} from "./interfaces/IDynamicTraits.sol";
import {SmartAccountTimelocks} from "./extensions/SmartAccountTimelocks.sol";

// import "hardhat/console.sol";

contract ChargedParticles is IChargedParticles, Ownable, ReentrancyGuard {
  using NftTokenInfo for address;

  // NFT contract => SmartAccount Implementation
  mapping (address => address) internal accountImplementations;
  address internal defaultAccountImplementation;

  // NFT contract => Execution Controller
  mapping (address => address) internal executionControllers;
  address internal defaultExecutionController;

  // Registry Version => Registry Address
  mapping (uint256 => address) internal erc6551registry;
  uint256 internal defaultRegistry;


  // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // Initialization

  constructor(address registry) Ownable() ReentrancyGuard() {
    erc6551registry[defaultRegistry] = registry;
    defaultAccountImplementation = address(new SmartAccountTimelocks());
  }


  // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // Energize (Deposit)

  /// @notice Fund Particle with Asset Token
  ///    Must be called by the account providing the Asset
  ///    Account must Approve THIS contract as Operator of Asset
  ///
  /// @param contractAddress      The Address to the Contract of the Token to Energize
  /// @param tokenId              The ID of the Token to Energize
  /// @param assetToken           The Address of the Asset Token being used
  /// @param assetAmount          The Amount of Asset Token to Energize the Token with
  function energizeParticle(
    address contractAddress,
    uint256 tokenId,
    address assetToken,
    uint256 assetAmount
  )
    external
    virtual
    override
    nonReentrant
    returns (address account)
  {
    // Find the SmartAccount for this NFT
    IERC6551Registry registry = IERC6551Registry(erc6551registry[defaultRegistry]);
    address accountImpl = getAccountImplementation(contractAddress);
    account = registry.createAccount(accountImpl, bytes32(0), block.chainid, contractAddress, tokenId);
    ISmartAccount smartAccount = ISmartAccount(payable(account));

    // Initialize the Account
    if (!smartAccount.isInitialized()) {
      address executionController = getExecutionController(contractAddress);
      smartAccount.initialize(address(this), executionController);
    }

    // Transfer to SmartAccount
    IERC20(assetToken).transferFrom(msg.sender, account, assetAmount);

    // Pre-approve Charged Particles to transfer back out
    smartAccount.execute(assetToken, 0, abi.encodeWithSelector(IERC20.approve.selector, address(this), type(uint256).max), 0);

    // Call "update" on SmartAccount
    if (IERC165(account).supportsInterface(type(ISmartAccount).interfaceId)) {
      smartAccount.handleTokenUpdate(true, assetToken, assetAmount);
    }
  }


  // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // Release (Withdraw)

  function releaseParticle(
    address receiver,
    address contractAddress,
    uint256 tokenId,
    address assetToken
  )
    external
    virtual
    override
    onlyNFTOwnerOrOperator(contractAddress, tokenId)
    nonReentrant
    returns (uint256 amount)
  {
    // Find the SmartAccount for this NFT
    IERC6551Registry registry = IERC6551Registry(erc6551registry[defaultRegistry]);
    address accountImpl = getAccountImplementation(contractAddress);
    address account = registry.account(accountImpl, bytes32(0), block.chainid, contractAddress, tokenId);

    // Transfer to Receiver
    amount = IERC20(assetToken).balanceOf(account);
    IERC20(assetToken).transferFrom(account, receiver, amount);

    // Call "update" on SmartAccount
    if (IERC165(account).supportsInterface(type(ISmartAccount).interfaceId)) {
      ISmartAccount(payable(account)).handleTokenUpdate(false, assetToken, amount);
    }
  }

  function releaseParticleAmount(
    address receiver,
    address contractAddress,
    uint256 tokenId,
    address assetToken,
    uint256 assetAmount
  )
    external
    virtual
    override
    onlyNFTOwnerOrOperator(contractAddress, tokenId)
    nonReentrant
    returns (uint256)
  {
    // Find the SmartAccount for this NFT
    IERC6551Registry registry = IERC6551Registry(erc6551registry[defaultRegistry]);
    address accountImpl = getAccountImplementation(contractAddress);
    address account = registry.account(accountImpl, bytes32(0), block.chainid, contractAddress, tokenId);

    // Transfer to Receiver
    IERC20(assetToken).transferFrom(account, receiver, assetAmount);

    // Call "update" on SmartAccount
    if (IERC165(account).supportsInterface(type(ISmartAccount).interfaceId)) {
      ISmartAccount(payable(account)).handleTokenUpdate(false, assetToken, assetAmount);
    }

    return assetAmount;
  }


  // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // Covalent Bonds (Nested NFTs)

  /// @notice Deposit other NFT Assets into the Particle
  ///    Must be called by the account providing the Asset
  ///    Account must Approve THIS contract as Operator of Asset
  ///
  /// @param contractAddress      The Address to the Contract of the Token to Energize
  /// @param tokenId              The ID of the Token to Energize
  /// @param nftTokenAddress      The Address of the NFT Token being deposited
  /// @param nftTokenId           The ID of the NFT Token being deposited
  /// @param nftTokenAmount       The amount of Tokens to Deposit (ERC1155-specific)
  function covalentBond(
    address contractAddress,
    uint256 tokenId,
    address nftTokenAddress,
    uint256 nftTokenId,
    uint256 nftTokenAmount
  )
    external
    virtual
    override
    nonReentrant
    returns (bool success)
  {
    // Find the SmartAccount for this NFT
    IERC6551Registry registry = IERC6551Registry(erc6551registry[defaultRegistry]);
    address accountImpl = getAccountImplementation(contractAddress);
    address account = registry.createAccount(accountImpl, bytes32(0), block.chainid, contractAddress, tokenId);
    ISmartAccount smartAccount = ISmartAccount(payable(account));

    // Initialize the Account
    if (!smartAccount.isInitialized()) {
      address executionController = getExecutionController(contractAddress);
      smartAccount.initialize(address(this), executionController);
    }

    // Transfer to SmartAccount and pre-approve Charged Particles to transfer back out
    if (nftTokenAddress.isERC1155()) {
      IERC1155(nftTokenAddress).safeTransferFrom(msg.sender, account, tokenId, nftTokenAmount, "");
      smartAccount.execute(nftTokenAddress, 0, abi.encodeWithSelector(IERC1155.setApprovalForAll.selector, address(this), true), 0);
    } else {
      IERC721(nftTokenAddress).safeTransferFrom(msg.sender, account, nftTokenId);
      smartAccount.execute(nftTokenAddress, 0, abi.encodeWithSelector(IERC721.setApprovalForAll.selector, address(this), true), 0);
    }

    // Call "update" on SmartAccount
    if (IERC165(account).supportsInterface(type(ISmartAccount).interfaceId)) {
      smartAccount.handleNFTUpdate(true, nftTokenAddress, nftTokenId, nftTokenAmount);
    }
    return true;
  }

  /// @notice Release NFT Assets from the Particle
  /// @param receiver             The Address to Receive the Released Asset Tokens
  /// @param contractAddress      The Address to the Contract of the Token to Energize
  /// @param tokenId              The ID of the Token to Energize
  /// @param nftTokenAddress      The Address of the NFT Token being deposited
  /// @param nftTokenId           The ID of the NFT Token being deposited
  /// @param nftTokenAmount       The amount of Tokens to Withdraw (ERC1155-specific)
  function breakCovalentBond(
    address receiver,
    address contractAddress,
    uint256 tokenId,
    address nftTokenAddress,
    uint256 nftTokenId,
    uint256 nftTokenAmount
  )
    external
    virtual
    override
    onlyNFTOwnerOrOperator(contractAddress, tokenId)
    nonReentrant
    returns (bool success)
  {
    // Find the SmartAccount for this NFT
    IERC6551Registry registry = IERC6551Registry(erc6551registry[defaultRegistry]);
    address accountImpl = getAccountImplementation(contractAddress);
    address account = registry.account(accountImpl, bytes32(0), block.chainid, contractAddress, tokenId);

    // Transfer to Receiver
    if (nftTokenAddress.isERC1155()) {
      IERC1155(nftTokenAddress).safeTransferFrom(account, receiver, tokenId, nftTokenAmount, "");
    } else {
      IERC721(nftTokenAddress).safeTransferFrom(account, receiver, nftTokenId);
    }

    // Call "update" on SmartAccount
    if (IERC165(account).supportsInterface(type(ISmartAccount).interfaceId)) {
      ISmartAccount(payable(account)).handleNFTUpdate(false, nftTokenAddress, nftTokenId, nftTokenAmount);
    }

    return true;
  }


  // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // ERC6551 Wallet Registry

  /// @dev ...
  function getCurrentRegistry() external view returns (address) {
    return erc6551registry[defaultRegistry];
  }

  /// @dev ...
  function getRegistry(uint256 registry) external view returns (address) {
    return erc6551registry[registry];
  }

  /// @dev ...
  function setRegistry(uint256 version, address registry) external onlyOwner {
    erc6551registry[version] = registry;
  }

  /// @dev ...
  function setDefaultRegistryVersion(uint256 version) external onlyOwner {
    defaultRegistry = version;
  }


  // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // SmartAccount Execution Controllers
  //  - any NFT contract can have its own custom execution controller

  /// @dev ...
  function setDefaultExecutionController(address executionController) public virtual onlyOwner {
    defaultExecutionController = executionController;
  }

  /// @dev ...
  function setCustomExecutionController(address nftContract, address executionController) public virtual onlyOwner {
    executionControllers[nftContract] = executionController;
  }

  /// @dev ...
  function getExecutionController(address nftContract) public view returns (address executionController) {
    executionController = executionControllers[nftContract];
    if (executionController == address(0)) {
      executionController = defaultExecutionController;
    }
  }


  // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // SmartAccount Implementations
  //  - any NFT contract can have its own custom execution controller

  /// @dev ...
  function setDefaultAccountImplementation(address accountImplementation) public virtual onlyOwner {
    defaultAccountImplementation = accountImplementation;
  }

  /// @dev ...
  function setCustomAccountImplementation(address nftContract, address accountImplementation) public virtual onlyOwner {
    accountImplementations[nftContract] = accountImplementation;
  }

  /// @dev ...
  function getAccountImplementation(address nftContract) public view returns (address accountImplementation) {
    accountImplementation = accountImplementations[nftContract];
    if (accountImplementation == address(0)) {
      accountImplementation = defaultAccountImplementation;
    }
  }


  // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // Internal Modifiers

  modifier onlyNFTOwnerOrOperator(address contractAddress, uint256 tokenId) {
    require(contractAddress.isNFTOwnerOrOperator(tokenId, msg.sender), "Invalid owner or operator");
    _;
  }
}
