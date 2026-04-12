# NFT 拍卖市场大作业项目文档

## 🎯 项目概述
本项目基于 Hardhat + TypeScript 框架，开发了一个完整的 NFT 拍卖市场，完全满足课程大作业的全部要求：
- 实现符合 ERC721 标准的 NFT 合约（支持铸造、版税）
- 实现 NFT 拍卖核心功能（创建拍卖、出价、结束拍卖）
- 集成 Chainlink Price Feed 预言机，实现 ETH/USD 价格换算
- 采用 UUPS 代理模式实现合约安全升级
- 完整的单元测试、部署脚本与项目文档

---

## 🛠️ 技术栈
| 技术/工具 | 版本/说明                               |
| :--- |:------------------------------------|
| 开发框架 | Hardhat (TypeScript 版)              |
| 合约语言 | Solidity ^0.8.28                    |
| NFT 标准 | ERC721 (带版税 ERC2981)                |
| 升级模式 | OpenZeppelin UUPS 代理升级              |
| 预言机 | Chainlink Price Feeds (Sepolia 测试网) |
| 测试框架 | Chai + Hardhat Test                 |
| 部署工具 | Hardhat Ignition                    |

---

## 📁 项目结构
```
nftAuction/
├── contracts/
│   ├── mock/
│   │   └── MockAggregatorV3.sol
│   ├── NFTMarketplace.sol
│   └── ZZNFTWithRoyalty.sol
├── coverage/
│   └── index.html
├── scripts/
│   ├── deploy.ts
│   └── send-op-tx.ts
├── test/
│   └── NFTMarketplace.ts
├── hardhat.config.ts
├── package.json
└── README.md
```

---

## ✨ 核心功能实现
### 1. NFT 合约（ZZNFTWithRoyalty.sol）
- 完全符合 ERC721 标准，支持 NFT 铸造、转移、授权
- 集成 ERC2981 版税标准，支持创作者二次销售分成
- 与拍卖合约深度集成，支持上架拍卖的权限校验

### 2. 拍卖市场合约（NFTMarketplace.sol）
- **创建拍卖**：NFT 持有者可上架 NFT，设置起拍价、拍卖时长
- **出价功能**：支持 ETH 原生代币出价，自动校验出价有效性
- **价格换算**：集成 Chainlink 预言机，实时获取 ETH/USD 价格，将出价金额转换为美元展示
- **结束拍卖**：拍卖到期后，自动将 NFT 转移给最高出价者，资金（扣除版税）转给卖家
- **UUPS 升级**：采用 OpenZeppelin UUPS 代理模式，支持合约无缝升级，不改变合约地址

### 3. Chainlink 预言机集成
- 本地测试使用 `MockAggregatorV3` 模拟价格
- Sepolia 测试网使用 Chainlink 官方 ETH/USD 价格喂价合约
- 实现价格获取、精度转换、美元金额计算，方便用户比价

### 4. 合约升级（UUPS 模式）
- 仅管理员权限可执行升级操作
- 升级后合约状态、地址完全保留，用户无感知
- 兼容 OpenZeppelin 安全升级标准，避免安全漏洞

---

## 🧪 测试说明
### 测试覆盖范围
- ✅ NFT 铸造、授权、转移功能
- ✅ 拍卖创建、出价、结束全流程
- ✅ Chainlink 价格获取与换算
- ✅ UUPS 合约升级功能
- ✅ 异常场景测试（过期拍卖、重复出价、权限错误等）

### 测试执行命令
```bash

# 编译合约
npx hardhat compile

# 运行所有测试
npx hardhat test

# 生成测试覆盖率报告
npx hardhat coverage

# 部署到 Sepolia 测试网
npx hardhat run scripts/deploy.ts --network sepolia

合约名称	合约地址
ZZNFTWithRoyalty (NFT 合约)	0x8D306BCEdE21fc3180497d2865FC0e0DDc26558e
NFTMarketplace (市场代理合约)	0x84fDFF513e2aEd3aCb33fAb44c441BCEa87D97f2
NFTMarketplace (市场实现合约)	0xf2aef9904B67617E82EfC49962660fbAc4C46a1c