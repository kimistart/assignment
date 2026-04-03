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
        uint256 tokenId,
        uint256 salePrice
    ) internal view returns (address receiver,uint256 royaltyAmount) {
        if(IERC165(nftContract).supportsInterface(type(IERC2981).interfaceId)) {
            (receiver,royaltyAmount) = IERC2981(nftContract).royaltyInfo(
                tokenId,salePrice
            );
        }
    }

    //支付足够的ETH，剩余部分返还
    function buyNFT(uint256 listingId) exteranl payable nonReentrant {
        Listing storage listing = listings[listingId];

        require(listing.active, "Listing not active");
        require(msg.value >= listing.price, "Insufficient payment");
        require(msg.sender != listing.seller,"Cannot buy your own NFT");

        listing.active = false;

        uint256 fee = (listing.price * platformFee)/10000;

        //版税
        (address royaltyReceiver,uint256 royaltyAmount) = _getRoyaltyInfo(
            listing.nftContract,listing.tokenId,listing.price
        );

        //卖家收益
        uint256 sellerAmount = listing.price - fee - royaltyAmount;

        //转移NFT
        IERC721(listing.nftContract).safeTransferFrom(
            listing.seller,
            msg.sender,
            listing.tokenId
        );

        //分配
        if(royaltyAmount >0 && royaltyReceiver != address(0)) {
            (bool successRoyalty,) = royaltyReceiver.call{value:royaltyAmount}("");
            require(successRoyalty, "Royalty transfer failed");
        }

        (bool successSeller, ) = listing.seller.call{value:sellerAmount}("");
        require(successSeller, "Transter to seller failed");

        (bool successFee, ) = feeRecipient.call{value:fee}("");
        require(successFee, "Transfer fee failed");

        if(msg.value > listing.price) {
            (bool successRefund, ) = msg.sender.call{
                    value:msg.value - listing.price
            }("");
            require(successRefund, "Transfer refund failed");
        }

        emit NFTSold(listingId,msg.sender,listing.seller,listing.price);
    }

    function createAuction(
        address nftContract,
        uint256 tokenId,
        uint256 startPrice,
        uint256 durationHours
    ) external returns (uint256) {
        require(startPrice >0, "Start price must be greater than 0");
        require(durationHours > 1, "Duration must be at least 1 hour");
        require(nftContract != address(0), "Invalid NFT contract");

        IERC721 nft = IERC721(nftContract);

        require(nft.ownerOf(tokenId) == msg.sender, "Not the owner");

        require(
            nft.getApproved(tokenId) == address(this) ||
            nft.isApprovedForAll(msg.sender,address(this)),
            "Marketplace not approved"
        );

        auctionCounter++;
        auctions[auctionCounter] = Auction({
            seller:msg.sender,
            nftContract: nftContract,
            tokenId: tokenId,
            startPrice: startPrice,
            highestBid: 0,
            highestBidder: address(0),
            endTime: block.timestamp + (durationHours * 1 hours),
            active: true
        });

        emit AuctionCreated(
            auctionCounter,
            msg.sender,
            nftContract,
            tokenId,
            startPrice,
            auctions[auctionCounter].endTime
        );

        return auctionCounter;
    }

    function placeBid(uint256 auctionId) external payable {
        Auction storage auction = auctions[auctionId];

        require(auction.active, "Auction not active");
        require(block.timestamp < auction.endTime, "Auction ended");
        require(msg.sender != auction.seller, "Seller cannot bid");

        uint256 minBid;
        if(auction.highestBid == 0) {
            minBid = auction.startPrice;
        } else {
            minBid = auction.highestBid + (auction.highestBid * 5 / 100); //5% increment
        }

        require(msg.value >= minBid, "Bid too low");

        if(auction.highestBidder != address(0)) {
            pendingReturns[auctionId][auction.highestBidder] += auction.highestBid;
        }

        auction.highestBid = msg.value;
        auction.highestBidder = msg.sender;

        emit BidPlaced(auctionId,msg.sender,msg.value);
    }
















}