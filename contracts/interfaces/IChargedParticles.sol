// SPDX-License-Identifier: MIT

// IChargedParticles.sol -- Part of the Charged Particles Protocol
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

/**
 * @notice Interface for Charged Particles
 */
interface IChargedParticles {

  function setDefaultExecutionController(address executionController) external;
  function setCustomExecutionController(address nftContract, address executionController) external;
  function getExecutionController(address nftContract) external view returns (address executionController);

  function setDefaultAccountImplementation(address accountImplementation) external;
  function setCustomAccountImplementation(address nftContract, address accountImplementation) external;
  function getAccountImplementation(address nftContract) external view returns (address accountImplementation);

  /***********************************|
  |        Particle Mechanics         |
  |__________________________________*/

  function energizeParticle(
    address contractAddress,
    uint256 tokenId,
    address assetToken,
    uint256 assetAmount
  ) external returns (address account);

  function releaseParticle(
    address receiver,
    address contractAddress,
    uint256 tokenId,
    address assetToken
  ) external returns (uint256 amount);

  function releaseParticleAmount(
    address receiver,
    address contractAddress,
    uint256 tokenId,
    address assetToken,
    uint256 assetAmount
  ) external returns (uint256 amount);

  function covalentBond(
    address contractAddress,
    uint256 tokenId,
    address nftTokenAddress,
    uint256 nftTokenId,
    uint256 nftTokenAmount
  ) external returns (bool success);

  function breakCovalentBond(
    address receiver,
    address contractAddress,
    uint256 tokenId,
    address nftTokenAddress,
    uint256 nftTokenId,
    uint256 nftTokenAmount
  ) external returns (bool success);
}
