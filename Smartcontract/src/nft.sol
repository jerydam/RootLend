// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../lib/openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract RootNft is ERC721URIStorage, Ownable {
    uint256 private _tokenIdCounter;

    constructor(address _owner) ERC721("SoulBoundToken", "SBT") Ownable(_owner) {}



    function safeMint(address to, string memory tokenURI) public onlyOwner {
        uint256 tokenId = _tokenIdCounter;
        _tokenIdCounter++;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, tokenURI);
    }

    function burn(uint256 tokenId) external {
        require(ownerOf(tokenId) == msg.sender, "Only the owner of the token can burn it.");
        _burn(tokenId);
    }

    function _update(address to, uint256 tokenId, address auth)
        internal
        override
        returns (address)
    {
        address from = _ownerOf(tokenId);
        if (from != address(0) && to != address(0)) {
            revert("Soulbound: Transfer failed");
        }

        return super._update(to, tokenId, auth);
    }
}














 ERC20 Deployed at: 0x326e042259c7cf517Ca303f6Cbe732d33331645E
  Treasury Deployed at: 0x32C4F29AC9b7ed3fC9B202224c8419d2DCC45B06
  Staking Contract at: 0x0633B9766f4e393eF5f2bdE3986DE0E03D9eC42B
  NFT Contract at: 0x67a89C43AEAdd8cE5233E31b83814e588De62F8B
  Swapper Contract at: 0xC84a23b8C65d3d7a4c793bb846258123456b7777
  P2P Lending Contract at: 0x360ff881B79ac2798feF24f03E1FC29a799B57FA
  DAO Contract at: 0xEE54E8Ede4767F1b4e8B4978E8c526493f117303
