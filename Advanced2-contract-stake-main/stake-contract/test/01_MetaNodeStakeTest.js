const { ethers, deployments, upgrades, parseEther } = require("hardhat")
const { expect } = require("chai")

describe("stake test", async function () {
    let admin, user1, user2, user3
    let erc20Contract, stakeProxyContract

    const metaNodePerBlock = 100n
    const blockHight = 10000
    // const provider = new ethers.JsonRpcProvider("http://127.0.0.1:8545/")
    const provider = ethers.provider
    // 解除质押的锁定区块数
    const unstakeLockedBlocks = 10
    const zeroAddress = "0x0000000000000000000000000000000000000000"

    it("deploy", async function () {
        // 部署 ERC20 合约
        [a0, admin, user1, user2, user3] = await ethers.getSigners()
        const erc20 = await ethers.getContractFactory("MetaNodeToken")
        erc20Contract = await erc20.connect(admin).deploy()
        await erc20Contract.waitForDeployment()
        const erc20ddress = await erc20Contract.getAddress()
        console.log("erc20ddress::", erc20ddress)
        expect(erc20ddress).to.length.gt(0)

        // 当前区块高度
        const blockNumber = await provider.getBlockNumber()
        console.log("当前区块高度::", blockNumber)
        // 部署 MetaNodeStake
        const metaNodeStake = await ethers.getContractFactory("MetaNodeStake")
        stakeProxyContract = await upgrades.deployProxy(metaNodeStake.connect(admin), [erc20ddress, blockNumber, blockNumber + blockHight, metaNodePerBlock], { kind: "uups" })
        await stakeProxyContract.waitForDeployment()
        const metaNodeStakeAddress = await stakeProxyContract.getAddress()
        console.log("metaNodeStakeContract::", metaNodeStakeAddress)
        expect(metaNodeStakeAddress).to.length.gt(0)
        // 部署后新增 eth 质押池
        await stakeProxyContract.connect(admin).addPool(zeroAddress, 5, 1E15, unstakeLockedBlocks, false)
        const poolLength = await stakeProxyContract.poolLength()
        expect(poolLength).to.length.gt(0)
    })

    it("getMultiplier", async () => {
        // 当前区块高度
        const fromBlock = await stakeProxyContract.startBlock()
        const toBlock = fromBlock + 10n
        const mul = await stakeProxyContract.getMultiplier(fromBlock, toBlock)
        expect(mul).to.eq(metaNodePerBlock * (toBlock - fromBlock))
    })

    it("setMetaNodePerBlock",async () => {
        await stakeProxyContract.connect(admin).setMetaNodePerBlock(101n)
    })

    it("setMetaNode", async () => {
        const erc20 = await ethers.getContractFactory("MetaNodeToken")
        erc20Contract = await erc20.connect(admin).deploy()
        await erc20Contract.waitForDeployment()
        const erc20ddress = await erc20Contract.getAddress()

        await stakeProxyContract.connect(admin).setMetaNode(erc20ddress)
        const newERC20 = await stakeProxyContract.MetaNode()
        expect(newERC20).to.eq(erc20ddress)
    })

    it("pauseWithdraw", async () => {
        await stakeProxyContract.connect(admin).pauseWithdraw()
        const res = await stakeProxyContract.withdrawPaused()
        expect(res).to.true
    })

    it("unpauseWithdraw", async () => {
        await stakeProxyContract.connect(admin).unpauseWithdraw()
        const res = await stakeProxyContract.withdrawPaused()
        expect(res).to.false
    })

    it("pauseClaim", async () => {
        await stakeProxyContract.connect(admin).pauseClaim()
        const res = await stakeProxyContract.claimPaused()
        expect(res).to.true
    })

    it("unpauseClaim", async () => {
        await stakeProxyContract.connect(admin).unpauseClaim()
        const res = await stakeProxyContract.claimPaused()
        expect(res).to.false
    })

    it("setStartBlock", async () => {
        // 当前区块高度
        const blockNumber = await provider.getBlockNumber()
        const startBlock = blockNumber
        await stakeProxyContract.connect(admin).setStartBlock(startBlock)
        const res = await stakeProxyContract.startBlock()
        expect(res).to.eq(startBlock)
    })

    it("setEndBlock", async () => {
        const startBlock = await stakeProxyContract.startBlock()
        const endBlock = startBlock + 100n

        const errEndBlock = startBlock - 1n
        await expect(stakeProxyContract.connect(admin).setEndBlock(errEndBlock)
        ).to.to.revertedWith("start block must be smaller than end block")

        await stakeProxyContract.connect(admin).setEndBlock(endBlock)
        const res = await stakeProxyContract.endBlock()
        expect(res).to.eq(endBlock)
    })

    it("addPool", async () => {

        const endBlock = await stakeProxyContract.endBlock()
        errStartBlock = endBlock+1n
        await expect(stakeProxyContract.connect(admin).setStartBlock(errStartBlock)
        ).to.be.revertedWith("start block must be smaller than end block")

        const tokenAddress = await erc20Contract.getAddress()
        // 质押池的权重，影响奖励分配
        const poolWeight = 10
        // 最小质押金额 
        const minDepositAmount = BigInt(1E18)
        const withUpdate = false

        await expect(stakeProxyContract.connect(admin).addPool(
            tokenAddress, poolWeight, minDepositAmount, 0, withUpdate)
        ).to.be.revertedWith("invalid withdraw locked blocks")

        await stakeProxyContract.connect(admin).addPool(tokenAddress, poolWeight, minDepositAmount, unstakeLockedBlocks, withUpdate)
        const poolLength = await stakeProxyContract.poolLength()
        expect(poolLength).to.length.gt(1)
    })

    it("updatePool", async () => {
        await stakeProxyContract.connect(admin).updatePool(0, 1E15, 10)
        await stakeProxyContract.connect(admin).setPoolWeight(0, 20, true)

        await expect(stakeProxyContract.connect(admin).setPoolWeight(0, 0, true)
        ).to.be.revertedWith("invalid pool weight")
    })

    it("deposit", async () => {

        await expect(stakeProxyContract.connect(user1).depositETH({ value: ethers.parseEther("0.000001") })
        ).to.be.revertedWith("deposit amount is too small")

        // user1 deposit 10ETH, user2 deposit 20ETH
        await provider.send("evm_setAutomine", [false])

        await stakeProxyContract.connect(user1).depositETH({ value: ethers.parseEther("10") })
        await stakeProxyContract.connect(user2).depositETH({ value: ethers.parseEther("20") })

        await provider.send("evm_mine", [])
        await provider.send("evm_setAutomine", [true])

        await provider.send("evm_mine", [])
        const blockNumber1 = await provider.getBlockNumber()
        console.log("还剩余奖励(当前区块)：",blockNumber1)
        const lastPending = await stakeProxyContract.connect(user2).pendingMetaNodeByBlockNumber(0,user2.address,blockNumber1)
        console.log("还剩余奖励：",lastPending)


        // user3 deposit 200USD
        await erc20Contract.connect(admin).transfer(user3.address, ethers.parseEther("1000"))
        const proxyAddress = await stakeProxyContract.getAddress()
        await erc20Contract.connect(user3).approve(proxyAddress, ethers.parseEther("400"))

        await expect(stakeProxyContract.connect(user3).deposit(1,ethers.parseEther("0.1"))
        ).to.be.revertedWith("deposit amount is too small")
        await expect(stakeProxyContract.connect(user3).deposit(0,ethers.parseEther("0.1"))
        ).to.be.revertedWith("deposit not support ETH staking")

        await stakeProxyContract.connect(user3).deposit(1, ethers.parseEther("200"))

        const user1Stake = await stakeProxyContract.stakingBalance(0, user1.address)
        const user2Stake = await stakeProxyContract.stakingBalance(0, user2.address)
        const user3Stake = await stakeProxyContract.stakingBalance(1, user3.address)
        expect(user1Stake).to.eq(BigInt(10E18))
        expect(user2Stake).to.eq(BigInt(20E18))
        expect(user3Stake).to.eq(BigInt(200E18))

        await stakeProxyContract.connect(user1).depositETH({ value: ethers.parseEther("10") })
        await stakeProxyContract.connect(user2).depositETH({ value: ethers.parseEther("20") })

        await stakeProxyContract.connect(user3).deposit(1, ethers.parseEther("200"))

        await provider.send("evm_mine", [])
        const blockNumber = await provider.getBlockNumber()
        const pending = await stakeProxyContract.connect(user3).pendingMetaNodeByBlockNumber(1,user3.address,blockNumber)
        console.log("用户可领取奖励：", pending);


        const user1StakeAgain = await stakeProxyContract.stakingBalance(0, user1.address)
        const user2StakeAgain = await stakeProxyContract.stakingBalance(0, user2.address)
        const user3StakeAgain = await stakeProxyContract.stakingBalance(1, user3.address)
        expect(user1StakeAgain).to.eq(BigInt(20E18))
        expect(user2StakeAgain).to.eq(BigInt(40E18))
        expect(user3StakeAgain).to.eq(BigInt(400E18))

    })

    it("unstake", async () => {

        await expect(stakeProxyContract.connect(user1).unstake(0,ethers.parseEther("100"))).to.be.revertedWith("Not enough staking token balance")

        await stakeProxyContract.connect(user1).unstake(0, ethers.parseEther("2"))
        await stakeProxyContract.connect(user2).unstake(0, ethers.parseEther("2"))
        await stakeProxyContract.connect(user3).unstake(1, ethers.parseEther("10"))

        console.log("第一次解质押后的区块高度：",await provider.getBlockNumber())
        // 跳过锁定区块提现
        for (let i = 0; i < 2; i++) {
            await provider.send("evm_mine", []);
        }
        console.log("第一次挖矿2次后的区块高度：",await provider.getBlockNumber())

        await stakeProxyContract.connect(user1).unstake(0, ethers.parseEther("2"))
        await stakeProxyContract.connect(user2).unstake(0, ethers.parseEther("2"))
        await stakeProxyContract.connect(user3).unstake(1, ethers.parseEther("10"))

        console.log("第二次解质押后的区块高度：",await provider.getBlockNumber())
        // 跳过锁定区块提现
        for (let i = 0; i < 2; i++) {
            await provider.send("evm_mine", []);
        }
        console.log("第二次挖矿2次后的区块高度：",await provider.getBlockNumber())

        await stakeProxyContract.connect(user1).unstake(0, ethers.parseEther("2"))
        await stakeProxyContract.connect(user2).unstake(0, ethers.parseEther("2"))
        await stakeProxyContract.connect(user3).unstake(1, ethers.parseEther("10"))

        const [requestAmount, pendingWithdrawAmount] = await stakeProxyContract.connect(user3).withdrawAmount(1, user3.address)
        console.log("总请求金额:", requestAmount)
        console.log("可提取金额:", pendingWithdrawAmount)

        console.log("第三次解质押后的区块高度：",await provider.getBlockNumber())
        // 跳过锁定区块提现
        for (let i = 0; i < 2; i++) {
            await provider.send("evm_mine", []);
        }
        console.log("第三次挖矿2次后的区块高度：",await provider.getBlockNumber())

        const user1Stake = await stakeProxyContract.stakingBalance(0, user1.address)
        const user2Stake = await stakeProxyContract.stakingBalance(0, user2.address)
        const user3Stake = await stakeProxyContract.stakingBalance(1, user3.address)
        expect(user1Stake).to.eq(BigInt(14E18))
        expect(user2Stake).to.eq(BigInt(34E18))
        expect(user3Stake).to.eq(BigInt(370E18))

        await stakeProxyContract.massUpdatePools()
    })

    it("pendingMetaNode", async () =>  {
        const user1PendNFT = await stakeProxyContract.pendingMetaNode(0, user1.address)
        const user2PendNFT = await stakeProxyContract.pendingMetaNode(0, user2.address)
        const user3PendNFT = await stakeProxyContract.pendingMetaNode(1, user3.address)
        // expect(user1PendNFT).to.eq(BigInt(460))
        // expect(user2PendNFT).to.eq(BigInt(976))
        // expect(user3PendNFT).to.eq(BigInt(0))
        // console.log("user1.pendingMetaNode:",user1PendNFT)
        // console.log("user2.pendingMetaNode:",user2PendNFT)
        // console.log("user3.pendingMetaNode:",user3PendNFT)
    })

    it("withdraw", async () => {
        console.log(user1.address)

        const user1BalanceBefore = await provider.getBalance(user1.address)
        const user2BalanceBefore = await provider.getBalance(user2.address)
        const user3BalanceBefore = await erc20Contract.balanceOf(user3.address)
        // console.log("user1BalanceBefore::", user1BalanceBefore)
        // console.log("user2BalanceBefore::", user2BalanceBefore)
        // console.log("user3BalanceBefore::", user3BalanceBefore)

        // 跳过锁定区块提现 
        // for (let i = 0; i < unstakeLockedBlocks; i++) {
        //     await provider.send("evm_mine", []);
        // }

        await stakeProxyContract.connect(user1).withdraw(0)
        await stakeProxyContract.connect(user2).withdraw(0)
        await stakeProxyContract.connect(user3).withdraw(1)

        const user1Balance = await provider.getBalance(user1.address)
        const user2Balance = await provider.getBalance(user2.address)
        const user3Balance = await erc20Contract.balanceOf(user3.address)
        console.log("user1Balance::", user1Balance)

        // 跳过 8 个区块 eth转账生效
        // for (let i = 0; i < 8; i++) {
        //     await provider.send("evm_mine", []);
        // }
        const user1BalanceAfter = await provider.getBalance(user1.address)
        const user2BalanceAfter = await provider.getBalance(user2.address)
        const user3BalanceAfter = await erc20Contract.balanceOf(user3.address)
        console.log("user1BalanceAfter::", user1BalanceAfter)


        // eth 余额比较,有 gas, 不完全等于
        expect(user1BalanceAfter - user1BalanceBefore).to.lt(BigInt(4E18)).gt(BigInt(1.9E18))
        expect(user2BalanceAfter - user2BalanceBefore).to.lt(BigInt(4E18)).gt(BigInt(1.9E18))
        expect(user3BalanceAfter - user3BalanceBefore).to.eq(BigInt(20E18))
    })

    it("claim", async () => {
        console.log(user1.address)

        const user1BalanceOfBefore = await provider.getBalance(user1.address)
        console.log(user1BalanceOfBefore)

        await stakeProxyContract.connect(user1).claim(0)
        await stakeProxyContract.connect(user2).claim(0)
        await stakeProxyContract.connect(user3).claim(1)

        const user1BalanceOfAfter = await erc20Contract.balanceOf(user1.address)
        console.log(user1BalanceOfAfter)

    })
})

