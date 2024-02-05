// SPDX-License-Identifier: MIT
// Written by: Rob Secord (https://twitter.com/robsecord)
// Co-founder @ Charged Particles - Visit: https://charged.fi
// Co-founder @ Taggr             - Visit: https://taggr.io

pragma solidity ^0.8.13;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {ERC721, ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {ISmartAccountController} from "../interfaces/ISmartAccountController.sol";
import {IDynamicTraits} from "../interfaces/IDynamicTraits.sol";

/**
 * @dev todo...
 */
contract BufficornZK is ISmartAccountController, IDynamicTraits, Ownable, ERC721Enumerable {
  using Strings for uint256;

  // Base portion of the Token Metadata URI (format: base-uri/tokenId/traitsMap)
  string internal _tokenUriBase;

  // TokenId => Traits BitMap
  mapping (uint256 => uint256) internal _traitBits;

  // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // Initialization

  constructor(string memory name, string memory symbol)
    ERC721(name, symbol) Ownable() {}


  // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // Minting Logic

  // For minting container-NFTs that have no initial traits
  function mint(uint256 tokenId) external virtual {
    _mint(tokenId, 0);
  }

  // For minting child-NFTs that have initial fixed traits
  function mintWithTraits(uint256 tokenId, uint256 traits) external virtual {
    _mint(tokenId, traits);
  }


  // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // Customizable Traits Logic

  function getTraits(uint256 tokenId) external view override returns (uint256) {
    return _traitBits[tokenId];
  }

  function hasTrait(uint256 tokenId, uint256 trait) external view override returns (bool) {
    uint256 bit = _traitBits[tokenId] & (1 << trait);
    return bit > 0;
  }

  function traitCount(uint256 tokenId) external view override returns (uint256 totalTraits) {
    uint256 map = _traitBits[tokenId];
    // Brian Kerninghan bit-counting method = O(log(n))
    while (map != 0) {
      map &= (map - 1);
      totalTraits += 1;
    }
  }

  function _addTraits(uint256 tokenId, uint256 traits) internal returns (uint256) {
    _traitBits[tokenId] |= traits;
    return _traitBits[tokenId];
  }

  function _removeTraits(uint256 tokenId, uint256 traits) internal returns (uint256) {
    uint256 mask = traits ^ (2 ** 256 - 1); // negate to find the traits to keep
    _traitBits[tokenId] &= mask;
    return _traitBits[tokenId];
  }


  // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // Standard NFT Logic

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    _requireMinted(tokenId);
    string memory baseURI = _baseURI();
    return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), "/", _traitBits[tokenId].toString())) : "";
  }

  function setBaseURI(string memory newBase) external onlyOwner {
    _tokenUriBase = newBase;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _tokenUriBase;
  }


  // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // SmartAccount Controller Logic

  function onExecute(
    address,
    uint256,
    bytes calldata,
    uint8
  )
    external
    virtual
    override
    returns (string memory revertReason)
  {
    return ""; // success
  }

  function onUpdateToken(
    bool isReceiving,
    uint256, // this chain
    address, // this contract
    uint256 tokenId,
    address receivedAssetToken,
    uint256 receivedAssetAmount
  )
    external
    virtual
    override
  {
    // no-op
  }

  function onUpdateNFT(
    bool isReceiving,
    uint256, // this chain
    address, // this contract
    uint256 tokenId,
    address receivedTokenContract,
    uint256 receivedTokenId,
    uint256
  )
    external
    virtual
    override
  {
    if (IERC165(receivedTokenContract).supportsInterface(type(IDynamicTraits).interfaceId)) {
      uint256 newTraits = IDynamicTraits(receivedTokenContract).getTraits(receivedTokenId);
      if (isReceiving) {
        _addTraits(tokenId, newTraits);
      } else {
        _removeTraits(tokenId, newTraits);
      }
    }
  }

  function onUpdateNFTBatch(
    bool isReceiving,
    uint256, // this chain
    address, // this contract
    uint256 tokenId,
    address receivedTokenContract,
    uint256[] calldata receivedTokenIds,
    uint256[] calldata
  )
    external
    virtual
    override
  {
    uint256 i;
    uint256 t;
    uint256 n = receivedTokenIds.length;
    if (IERC165(receivedTokenContract).supportsInterface(type(IDynamicTraits).interfaceId)) {
      for (; i < n; i++) {
        t = IDynamicTraits(receivedTokenContract).getTraits(receivedTokenIds[i]);
        if (isReceiving) {
          _addTraits(tokenId, t);
        } else {
          _removeTraits(tokenId, t);
        }
      }
    }
  }


  // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // Custom Interfaces

  /// @dev Returns true if a given interfaceId is supported by this account. This method can be
  /// extended by an override.
  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(IERC165, ERC721Enumerable)
    returns (bool)
  {
    return
      interfaceId == type(ISmartAccountController).interfaceId ||
      interfaceId == type(IDynamicTraits).interfaceId ||
      super.supportsInterface(interfaceId);
  }


  // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // Internal Functions

  function _mint(uint256 tokenId, uint256 traits) internal {
    // Note: Do NOT set traits when bridging a Bufficorn-NFT.
    //       The "traits" param is ONLY used for minting Trait-NFTs
    //       which can be minted from this contract, or another contract.
    //       When bridging a Bufficorn, this contract will retain the last-known
    //       state for a Bufficorns nested traits on zkSync.
    if (traits > 0) {
      _traitBits[tokenId] = traits;
    }
    _safeMint(_msgSender(), tokenId);
  }
}
