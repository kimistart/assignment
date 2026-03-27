// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ZZNFT is ERC721, ERC721URIStorage, Ownable {

    uint256 private _tokenIdCounter;
    uint256 public constant MAX_SUPPLY = 100;
    uint256 public mintPrice = 0.01 ether;

    event NFTMinted(
        address indexed minter,
        uint256 indexed tokenId,
        string uri
    );

    constructor() ERC721("ZZNFT", "ZZ") Ownable(msg.sender) {}

    function mintNFT(){}
}