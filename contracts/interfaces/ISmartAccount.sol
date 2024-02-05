// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC6551Account} from "../interfaces/IERC6551Account.sol";
import {IERC6551Executable} from "../interfaces/IERC6551Executable.sol";

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {IERC1155Receiver} from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

/**
 * @title A smart contract account owned by a single ERC721 token
 */
interface ISmartAccount is
  IERC165,
  IERC6551Account,
  IERC6551Executable,
  IERC721Receiver,
  IERC1155Receiver
{
  event PermissionUpdated(address owner, address caller, bool hasPermission);
  event ExecutionControllerUpdated(address owner, address controller);

  function isInitialized() external returns (bool);
  function initialize(address chargedParticles, address executionController) external;

  function handleTokenUpdate(
    bool isReceiving,
    address assetToken,
    uint256 assetAmount
  ) external;

  function handleNFTUpdate(
    bool isReceiving,
    address tokenContract,
    uint256 tokenId,
    uint256 tokenAmount
  ) external;

  function handleNFTBatchUpdate(
    bool isReceiving,
    address tokenContract,
    uint256[] calldata tokenIds,
    uint256[] calldata tokenAmounts
  ) external;
}
