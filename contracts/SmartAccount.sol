// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {SmartAccountBase, NotAuthorized, InvalidInput} from "./lib/SmartAccountBase.sol";

/**
 * @title A smart contract account owned by a single ERC721 token
 */
contract SmartAccount is SmartAccountBase {
  uint256 public state;

  constructor() SmartAccountBase() {}


  /// @dev allows eth transfers by default
  receive() external payable virtual override {}

  /// @dev executes a low-level call against an account if the caller is authorized to make calls
  function execute(
    address to,
    uint256 value,
    bytes calldata data,
    uint8 operation
  )
    public
    payable
    virtual
    override
    onlyValidSigner
    returns (bytes memory)
  {
    require(operation == 0, "Only call operations are supported");
    ++state;

    // Perform custom checks/updates from within a custom controller
    _onExecute(to, value, data, operation);

    // Execute Call on Account
    return _call(to, value, data);
  }


  function handleTokenUpdate(
    bool isReceiving,
    address assetToken,
    uint256 assetAmount
  )
    public
    virtual
    override
    onlyValidSigner
  {
    // Perform custom checks/updates from within a custom controller
    _onUpdateToken(isReceiving, assetToken, assetAmount);
  }

  function handleNFTUpdate(
    bool isReceiving,
    address tokenContract,
    uint256 tokenId,
    uint256 tokenAmount
  )
    public
    virtual
    override
    onlyValidSigner
  {
    // Perform custom checks/updates from within a custom controller
    _onUpdateNFT(isReceiving, tokenContract, tokenId, tokenAmount);
  }

  function handleNFTBatchUpdate(
    bool isReceiving,
    address tokenContract,
    uint256[] calldata tokenIds,
    uint256[] calldata tokenAmounts
  )
    public
    virtual
    override
    onlyValidSigner
  {
    // Perform custom checks/updates from within a custom controller
    _onUpdateNFTBatch(isReceiving, tokenContract, tokenIds, tokenAmounts);
  }
}
