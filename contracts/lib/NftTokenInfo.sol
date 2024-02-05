// SPDX-License-Identifier: MIT

// NftTokenInfo.sol -- Part of the Charged Particles Protocol
// Copyright (c) 2021 Firma Lux, Inc. <https://charged.fi>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

pragma solidity ^0.8.13;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC1271} from "@openzeppelin/contracts/interfaces/IERC1271.sol";

library NftTokenInfo {
  bytes4 constant internal INTERFACE_SIGNATURE_ERC721 = 0x80ac58cd;
  bytes4 constant internal INTERFACE_SIGNATURE_ERC1155 = 0xd9b67a26;

  function isERC721(address contractAddress) internal view returns (bool) {
    return IERC165(contractAddress).supportsInterface(INTERFACE_SIGNATURE_ERC721);
  }

  function isERC1155(address contractAddress) internal view returns (bool) {
    return IERC165(contractAddress).supportsInterface(INTERFACE_SIGNATURE_ERC1155);
  }

  function getTokenUUID(address contractAddress, uint256 tokenId) internal pure returns (uint256) {
    return uint256(keccak256(abi.encodePacked(contractAddress, tokenId)));
  }

  function getTokenOwner(address contractAddress, uint256 tokenId) internal returns (address) {
    return _getTokenOwner(contractAddress, tokenId);
  }

  function isNFTOwnerOrOperator(address contractAddress, uint256 tokenId, address sender) internal returns (bool) {
    IERC721 tokenInterface = IERC721(contractAddress);
    address tokenOwner = _getTokenOwner(contractAddress, tokenId);
    return (sender == tokenOwner || tokenInterface.isApprovedForAll(tokenOwner, sender));
  }

  function _getTokenOwner(address contractAddress, uint256 tokenId) internal returns (address) {
    // solhint-disable-next-line
    (bool success, bytes memory returnData) = contractAddress.call(abi.encodeWithSelector(IERC721.ownerOf.selector, tokenId));
    if (success) {
      return abi.decode(returnData, (address));
    } else {
      return address(0x0);
    }
  }
}
