import hre from "hardhat";
import { expect } from "chai";
import { ethers } from "hardhat";
const { upgrades } = hre


//测试组
describe("NFTMarketplace", function() {

    //公共变量
    let marketplace:any;
    let nft:any;
    let owner:any, seller:any, bidder1:any,bidder2:any;

    //测试前部署
    beforeEach(async function() {
        [owner,seller,bidder1,bidder2] = await ethers.getSigners();

        //部署预言机等本地环境价格合约
        const MockPrice = await ethers.getContractFactory("MockAggregatorV3");
        const mockPrice = await MockPrice.deploy(2000e8);

        //部署市场
        const Marketplace = await ethers.getContractFactory("NFTMarketplace");
        marketplace =await upgrades.deployProxy(Marketplace,[owner.address,mockPrice.address],{
            initializer:"initialize",
        });

        //部署NFT
        const NFT = await ethers.getContractFactory("ZZNFTWithRoyalty");
        nft = await NFT.deploy(owner.address,100);
    });

    //平台费2.5%
    it("Deployment: platform fee is 2.5%", async function(){
        expect(await marketplace.platformFee()).to.equal(250);
    });

    //创建拍卖
    it("Auction: create successfully", async function(){
        await nft.connect(seller).mint("uri",{value: ethers.utils.parseEther("0.01")});
        await nft.connect(seller).setApprovalForAll(marketplace.address,true);

        await marketplace.connect(seller).createAuction(
            nft.address,1,ethers.utils.parseEther("0.1"),2
        );

        const auc = await marketplace.getAuction(1);
        expect(auc.active).to.be.true;
    });

    //出价成功
    it("Bid:normal bid success", async function(){
        await nft.connect(seller).mint("uri",{value:ethers.utils.parseEther("0.01")});
        await nft.connect(seller).setApprovalForAll(marketplace.address,true);
        await marketplace.connect(seller).createAuction(nft.address,1,ethers.utils.parseEther("0.1"),2);

        await marketplace.connect(bidder1).placeBid(1,{value:ethers.utils.parseEther("0.12")});
        const auc = await marketplace.getAuction(1);
        expect(auc.highestBidder).to.equal(bidder1.address);
    });

    //出价太低
    it("Bid:bid too low reverted", async function(){
        await nft.connect(seller).mint("uri",{value:ethers.utils.parseEther("0.01")});
        await nft.connect(seller).setApprovalForAll(marketplace.address,true);
        await marketplace.connect(seller).createAuction(nft.address,1,ethers.utils.parseEther("0.1"),2);

        await expect(marketplace.connect(bidder1).placeBid(1,{value:ethers.utils.parseEther("0.05")}))
            .to.be.revertedWith("Bid too low");
    });

    //结束拍卖
    it("Auction end: transfer NFT to winner",async function(){
        await nft.connect(seller).mint("uri",{value:ethers.utils.parseEther("0.01")});
        await nft.connect(seller).setApprovalForAll(marketplace.address,true);
        await marketplace.connect(seller).createAuction(nft.address,1,ethers.utils.parseEther("0.1"),2);
        await marketplace.connect(bidder1).placeBid(1,{value:ethers.utils.parseEther("0.12")});

        await ethers.provider.send("evm_increaseTime",[3600 * 3]);
        await ethers.provider.send("evm_mine",[]);

        await marketplace.endAuction(1);
        expect(await nft.ownerOf(1)).to.equal(bidder1.address);
        expect(await nft.getRoyaltyBps()).to.be.gt(0);
        // 拍卖金额 0.12 ETH，版税 1% → 金额一定大于0
        expect(ethers.utils.parseEther("0.12").mul(await nft.getRoyaltyBps()).div(10000)).to.be.gt(0);
    });

    //退款
    it("withdraw: get refund back",async function(){
        await nft.connect(seller).mint("uri",{value:ethers.utils.parseEther("0.01")});
        await nft.connect(seller).setApprovalForAll(marketplace.address,true);
        await marketplace.connect(seller).createAuction(nft.address,1,ethers.utils.parseEther("0.1"),2);

        await marketplace.connect(bidder1).placeBid(1,{value:ethers.utils.parseEther("0.12")});
        await marketplace.connect(bidder2).placeBid(1,{value:ethers.utils.parseEther("0.13")});

        await marketplace.connect(bidder1).withdrawBid(1);
        expect(await marketplace.pendingReturns(1,bidder1.address)).to.equal(0);
    });

    //USD价格
    it("Utils:ethToUsd works", async function(){
        await nft.connect(seller).mint("uri",{value:ethers.utils.parseEther("0.01")});
        await nft.connect(seller).setApprovalForAll(marketplace.address,true);
        await marketplace.connect(seller).createAuction(nft.address,1,ethers.utils.parseEther("0.1"),2);
        await marketplace.connect(bidder1).placeBid(1,{value:ethers.utils.parseEther("0.1")});

        const usd = await marketplace.bidUsdAmount(1,bidder1.address);
        expect(usd).to.gt(0);
    });
});