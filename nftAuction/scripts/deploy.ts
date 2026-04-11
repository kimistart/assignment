import { ethers, upgrades } from "hardhat";

async function main() {
    console.log("🚀 开始部署 NFT 拍卖市场到 Sepolia 测试网...");

    // ==========================================
    // 1. 部署 NFT 合约 (ZZNFTWithRoyalty.sol)
    // ==========================================
    console.log("\n📦 部署 ZZNFTWithRoyalty...");
    const ZZNFT = await ethers.getContractFactory("ZZNFTWithRoyalty");
    const nft = await ZZNFT.deploy();
    await nft.deployed();
    console.log("✅ ZZNFTWithRoyalty 部署成功，地址：", nft.address);

    // ==========================================
    // 2. 部署 UUPS 代理模式的拍卖市场合约 (NFTMarketplace.sol)
    // ==========================================
    console.log("\n📦 部署 NFTMarketplace (UUPS代理)...");
    const Auction = await ethers.getContractFactory("NFTMarketplace");

    // Sepolia测试网 Chainlink ETH/USD 喂价地址（固定，直接用）
    const ETH_USD_PRICE_FEED = "0x694AA1769357215DE4FAC081bf1f309aDC325306";

    // 部署代理合约，传入NFT地址和Chainlink喂价地址
    const auction = await upgrades.deployProxy(Auction, [nft.address, ETH_USD_PRICE_FEED], {
        kind: "uups", // 明确指定UUPS代理模式
    });
    await auction.deployed();

    console.log("✅ NFTMarketplace 代理地址：", auction.address);
    // 获取并打印逻辑合约（实现合约）地址，用于后续验证
    const implAddress = await upgrades.erc1967.getImplementationAddress(auction.address);
    console.log("✅ NFTMarketplace 实现合约地址：", implAddress);

    console.log("\n🎉 部署完成！");
    console.log("📋 部署地址汇总（请保存好，作业要提交）：");
    console.log("   1. NFT合约地址：", nft.address);
    console.log("   2. 拍卖代理合约地址：", auction.address);
    console.log("   3. 拍卖实现合约地址：", implAddress);
}

// 执行部署函数
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });