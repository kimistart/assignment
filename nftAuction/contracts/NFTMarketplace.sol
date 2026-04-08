// SPDX-License-Identifier: MIT

pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract NFTMarketplace is Initializable, UUPSUpgradeable, OwnableUpgradeable, ReentrancyGuard  {

    //拍卖结构体
    struct Auction {
        address seller;
        address nftContract;
        uint256 tokenId;
        uint256 startPrice;
        uint256 highestBid;
        address highestBidder;
        uint256 endTime;
        bool active;
    }

    //拍卖映射
    mapping(uint256 => Auction) public auctions;
    uint256 public auctionCounter;

    //待退款映射
    mapping(uint256 => mapping(address => uint256)) public pendingReturns;

    //出价对应的USD
    mapping(uint256 => mapping(address => uint256)) public bidUsdAmount;

    address public feeRecipient;

    uint256 public platformFee;

    event AuctionCreated(
        uint256 indexed auctionId,
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

    AggregatorV3Interface internal priceFeed;

    constructor() {
        _disableInitializers();
    }

    function initialize(address _feeRecipient) external initializer {

        platformFee = 250; //2.5%

        __Ownable_init(msg.sender);

        require(_feeRecipient != address(0), "Invalid fee recipient");
        feeRecipient = _feeRecipient;

        priceFeed = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function ethToUsd(uint256 ethAmount) public view returns (uint256) {
        ( ,int256 answer, , , ) = priceFeed.latestRoundData();
        require(answer > 0, "Invalid price");
        return (ethAmount * uint256(answer)) / 1e8;
    }

    function getHighestBidUsd(uint256 auctionId) external view returns (uint256) {
        Auction storage auction = auctions[auctionId];
        return ethToUsd(auction.highestBid);
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

        // 计算最低出价
        uint256 minBid;
        if(auction.highestBid == 0) {
            minBid = auction.startPrice;
        } else {
            minBid = auction.highestBid + (auction.highestBid * 5 / 100); //5% increment
        }

        require(msg.value >= minBid, "Bid too low");

        // 如果有之前的出价者，记录他们的待退款金额
        if(auction.highestBidder != address(0)) {
            pendingReturns[auctionId][auction.highestBidder] += auction.highestBid;
        }

        // 更新最高出价
        auction.highestBid = msg.value;
        auction.highestBidder = msg.sender;

        uint256 usdValue = ethToUsd(msg.value);
        bidUsdAmount[auctionId][msg.sender] = usdValue;

        emit BidPlaced(auctionId,msg.sender,msg.value);
    }

    function withdrawBid(uint256 auctionId) external {
        uint256 amount = pendingReturns[auctionId][msg.sender];
        require(amount > 0, "No pending return");

        pendingReturns[auctionId][msg.sender] = 0;

        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
    }

    function endAuction(uint256 auctionId) external nonReentrant {
        Auction storage auction = auctions[auctionId];

        require(auction.active, "Auction not active");
        require(block.timestamp >= auction.endTime, "Auction not ended");

        auction.active = false;

        if(auction.highestBidder != address(0)) {
            uint256 fee = (auction.highestBid * platformFee)/10000;

            (address royaltyReceiver,uint256 royaltyAmount) = _getRoyaltyInfo(
                auction.nftContract,
                auction.tokenId,
                auction.highestBid
            );

            uint256 sellerAmount = auction.highestBid - fee - royaltyAmount;

            IERC721(auction.nftContract).safeTransferFrom(
                auction.seller,
                auction.highestBidder,
                auction.tokenId
            );

            if(royaltyAmount > 0 && royaltyReceiver != address(0)) {
                (bool successRoyalty, ) = royaltyReceiver.call{value: royaltyAmount}("");
                require(successRoyalty, "Royalty transfer failed");
            }

            (bool successSeller, ) = auction.seller.call{value: sellerAmount}("");
            require(successSeller, "Transfer to seller failed");

            (bool successFee, ) = feeRecipient.call{value: fee}("");
            require(successFee, "Transfer fee failed");

            emit AuctionEnded(
                auctionId,
                auction.highestBidder,
                auction.highestBid
            );
        } else {
            emit AuctionEnded(auctionId,address(0),0);
        }
    }

    function getAuction(uint256 auctionId) external view returns (
        address seller,
        address nftContract,
        uint256 tokenId,
        uint256 startPrice,
        uint256 highestBid,
        address highestBidder,
        uint256 endTime,
        bool active
    ) {
        Auction memory auction = auctions[auctionId];
        return (
            auction.seller,
            auction.nftContract,
            auction.tokenId,
            auction.startPrice,
            auction.highestBid,
            auction.highestBidder,
            auction.endTime,
            auction.active
        );
    }
}