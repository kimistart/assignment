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

    function mint(string memory uri) public payable returns(uint256){
    require(_tokenIdCounter < MAX_SUPPLY, "Max supply reached");

    require(msg.value >= mintPrice,"Insufficient payment");

    _tokenIdCounter++;
    uint256 newTokenId = _tokenIdCounter;

    _safeMint(msg.sender,newTokenId);

    _setTokenURI(newTokenId,uri);

    emit NFTMinted(msg.sender,newTokenId,uri);

    return newTokenId;
    }

    function tokenURI(uint256 tokenId) public view override(ERC721,ERC721URIStorage) returns (string memory) {
    return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721,ERC721URIStorage) returns (bool){
    return super.supportsInterface(interfaceId);
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIdCounter;
    }

    function withdraw() public onlyOwner {
    unit256 balance = address(this).balance;
    require(balance>0,"No balance to withdraw");
    payable(owner()).transfer(balance);
    }

    function setMintPrice(uint256 newPrice) public onlyOwner {
    mintPrice = newPrice;
    }
}