// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "forge-std/src/interfaces/IERC721.sol";

interface IERC2981 is IERC165 {
    function royaltyInfo(
        uint256 tokenId,
        uint256 salePrice
    ) external view returns (address receiver,uint256 royaltyAmount);
}

contract NFTMarketplace is ReentrancyGuard {

    //挂单结构体
    struct Listing {
        address seller;
        address nftContract;
        uint256 tokenId;
        uint256 price;
        bool active;
    }

    //拍卖结构体
    struct Auction {
        address seller;
        address nftContract;
        uint256 tokenId;
        uint256 startPrice;
        uint256 highestBid;
        uint256 highestBidder;
        uint256 endTime;
        bool active;
    }

    // 挂单映射
    mapping(uint256 => Listing) public listings;
    uint256 public listingCounter;

    //拍卖映射
    mapping(uint256 => Auction) public auctions;
    uint256 public auctionCounter;

    //待退款映射
    mapping(uint256 => mapping(address => uint256)) public pendingReturns;

    uint256 public platformFee = 250; //2.5%

    address public feeRecipient;

    event NFTListed(
        uint256 indexed listingId,
        address indexed seller,
        address indexed nftContract,
        uint256 tokenId,
        uint256 price
    );

    event NFTDelisted(
        uint256 indexed listingId
    );

    event priceUpdated(
        uint256 indexed listingId,
        uint256 newPrice
    );

    event NFTSold(
        uint256 indexed listingId,
        address indexed buyer,
        address indexed seller,
        uint256 price
    );

    event AuctionCreated(
        uint256 indexed actionId,
        address indexed seller,
        address indexed nftContract,
        uint256 tokenId,
        uint256 startPrice,
        uint256 endTime
    );

    //出价事件
    event BidPlaced(
        uint256 indexed auctionId,
        address indexed bidder,
        uint256 amount
    );

    event AuctionEnded(
        uint256 indexed auctionId,
        address indexed winner,
        uint256 finalPrice
    );

    constructor(address _feeRecipient) {
        require(_feeRecipient != address(0), "Invalid fee recipient");
        feeRecipient = _feeRecipient;
    }

    function listNFT(
        address nftContract,
        uint256 tokenId,
        uint256 price
    ) external returns (uint256) {
        require(price >0, "Price must be greater than 0");
        require(nftContract != address(0), "Invalid NFT contract");

        IERC721 nft = IERC721(nftContract);

        require(nft.ownerOf(tokenId) == msg.sender, "Not the Owner");
        require(
            nft.getApproved(tokenId) == address(this) ||
            nft.isApprovedForAll(msg.sender,address(this)),
            "Marketplace not approved"
        );

        listingCounter++;
        listings[listinCounter] = Listing({
            seller:msg.sender,
            nftContract: nftContract,
            tokenId: tokenId,
            price: price,
            active: true
        });

        emit NFTListed(
            listingCounter,
            msg.sender,
            nftContract,
            tokenId,
            price
        );

        return listingCounter;
    }

    function delistNFT(uint256 listingId) external {
        Listing storage listing = listings[listingId];

        require(listing.active, "Listing not active");
        require(listing.seller == msg.sender, "Not the seller");

        listing.active = false;

        emit NFTDelisted(listingId);
    }

    function updatePrice(uint256 listingId,uint256 newPrice) external {
        require(newPrice >0, "Price must be greater than 0");

        Listing storage listing = listings[listingId];
        require(listing.active, "Listing not active");
        require(listing.seller == msg.sender, "Not the seller");

        listing.price = newPrice;

        emit PriceUpdated(listingId,newPrice);
    }

    function _getRoyaltyInfo(
        address nftContract,
    ){}

    //支付足够的ETH，剩余部分返还
    function buyNFT(uint256 listingId) exteranl payable nonReentrant {
        Listing storage listing = listings[listingId];

        require(listing.active, "Listing not active");
        require(msg.value >= listing.price, "Insufficient payment");
        require(msg.sender != listing.seller,"Cannot buy your own NFT");

        listing.active = false;

        uint256 fee = (listing.price * platformFee)/10000;

        //版税

    }
















}