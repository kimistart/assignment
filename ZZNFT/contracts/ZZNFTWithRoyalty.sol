// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ZZNFTWithRoyalty is ERC721, ERC721URIStorage, Ownable,IERC2981,ERC165 {

    uint256 private _tokenIdCounter;
    uint256 public constant MAX_SUPPLY = 100;
    uint256 public mintPrice = 0.01 ether;

    address private _royaltyReceiver;

    uint96 private _royaltyBps = 1000;  //10%

    event NFTMinted(
        address indexed minter,
        uint256 indexed tokenId,
        string uri
    );

    constructor(
        address royaltyReceiver,
        uint96 royaltyBps
    ) ERC721("ZZNFTWithRoyalty", "NFR") Ownable(msg.sender) {
        require(royaltyReceiver != address(0), "Invalid royalty receiver");
        require(royaltyBps <1000, "Royalty too high"); //最大10%

        _royaltyReceiver = royaltyReceiver;
        _royaltyBps = royalBps;
    }

    function mint(string memory uri) public payable returns(uint256){
        require(_tokenIdCounter < MAX_SUPPLY, "Max supply reached");
        require(msg.value >= mintPrice,"Insufficient payment");

        _tokenIdCounter++;
        uint256 newTokenId = _tokenIdCounter;

        _safeMint(msg.sender,newTokenId)
        _setTokenURI(newTokenId,uri);

        emit NFTMinted(msg.sender,newTokenId,uri);

        return newTokenId;
    }

    function royaltyInfo(
        uint256 /* tokenId */,
        uint256 salePrice
    ) external view override returns (
        address receiver,
        uint256 royaltyAmount
    ) {
        receiver = _royaltyReceiver;
        royaltyAmount = (salePrice * _royaltyBps)/1000
    }

    function setRoyaltyInfo(address receiver, uint96 bps) exteranl onlyOwner {
        require(receiver != address(0), "Invalid receiver");
        require(bps<1000, "Royalty too high");

        _royaltyReceiver = receiver;
        _royaltyBps = bps;
    }

    function royaltyReceiver() external view returns (address) {
        return _royaltyReceiver;
    }

    function royaltyBps() external view returns (uint96) {
        return _royaltyBps;
    }

    function tokenURI(uint256 tokenId) public view override(ERC721,ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721,ERC721URIStorage,IERC165) returns (bool){
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
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