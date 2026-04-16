package main

import(
    "context"
    "log"
    "os"
    "fmt"
    "math/big"
    "github.com/joho/godotenv"
    "github.com/ethereum/go-ethereum/ethclient"
    "time"
    "github.com/ethereum/go-ethereum/core/types"
    "github.com/ethereum/go-ethereum/common"
    "github.com/ethereum/go-ethereum/crypto"
)

func main() {

//     PrintConsole()

    SendTx()
}

func SendTx() {

//     rpcURL := os.Getenv("SEPOLIA_RPC_URL")
//     key := os.Getenv("PRIVATE_KEY")
//     toAddr := common.HexToAddress(toAddrHex)

    rpcURL := "http://127.0.0.1:8545"
    key := "ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
    toAddr := common.HexToAddress("0x70997970C51812dc3A010C7d01b50e0d17dc79C8")

    amountEth := 0.5 // 转 0.5 ETH 测试

    if rpcURL == "" {
        log.Fatal("SEPOLIA_RPC_URL 未设置")
    }


    if key == "" {
        log.Fatal("PRIVATE_KEY 未设置")
    }

    ctx,cancel := context.WithTimeout(context.Background(),30*time.Second)
    defer cancel()

    client,err := ethclient.DialContext(ctx,rpcURL)
    if err != nil {
        log.Fatal("sepolia连接失败")
    }
    defer client.Close()

    privatekey,err := crypto.HexToECDSA(key)
    if err != nil {
        log.Fatal("私钥解析失败:",err)
    }

    //获取发送方地址
    fromAddress := crypto.PubkeyToAddress(privatekey.PublicKey)
    fmt.Println("发送方地址：",fromAddress.Hex())

    //获取链上必要参数(nonce、gasPrice、chainID)
    //链ID
    chainID,err := client.ChainID(ctx)
    if err != nil {
    	log.Fatalf("failed to get chain id: %v", err)
    }

    //nonce
    nonce,err := client.PendingNonceAt(ctx,fromAddress)
    if err != nil {
        log.Fatalf("failed to get nonce: %v", err)
    }

    //gas小费，EIP-1559动态费用
    gasTipCap,err := client.SuggestGasTipCap(ctx)
    if err != nil {
        log.Fatalf("failed to get gas tip cap: %v", err)
    }

    //base fee
    header,err := client.HeaderByNumber(ctx,nil)
    if err != nil {
        log.Fatalf("failed to get header: %v", err)
    }

    baseFee := header.BaseFee
    if baseFee == nil {
        //如果不支持EIP-1559,使用传统gas price
        gasPrice,err := client.SuggestGasPrice(ctx)
        if err != nil {
            log.Fatalf("failed to get gas price: %v", err)
        }
        baseFee = gasPrice
    }

    //gasfee上限 feecap = basefee *2 + tipcap
    gasFeeCap := new(big.Int).Add(
        new(big.Int).Mul(baseFee,big.NewInt(2)),gasTipCap,
    )

    //估算gaslimit(普通转账固定为21000)
    gasLimit := uint64(21000)
    //转换ETH金额为wei
    amountWei := new(big.Float).Mul(
        big.NewFloat(amountEth),
        big.NewFloat(1e18),
    )
    valueWei,_ := amountWei.Int(nil)

    //检查余额是否足够
    balance,err := client.BalanceAt(ctx,fromAddress,nil)
    if err != nil {
        log.Fatalf("failed to get balance: %v", err)
    }

    //计算总费用：value + gasFeeCap * gaslimit
    totalCost := new(big.Int).Add(
        valueWei,
        new(big.Int).Mul(gasFeeCap,big.NewInt(int64(gasLimit))),
    )

    if balance.Cmp(totalCost) < 0 {
        log.Fatalf("insufficient balance: have %s wei, need %s wei", balance.String(), totalCost.String())
    }

    // 构造交易（EIP-1559 动态费用交易）
    txData := &types.DynamicFeeTx{
        ChainID:   chainID,
        Nonce:     nonce,
        GasTipCap: gasTipCap,
        GasFeeCap: gasFeeCap,
        Gas:       gasLimit,
        To:        &toAddr,
        Data:      nil,
        Value:     valueWei,
    }
    tx := types.NewTx(txData)

    //签名交易
    signer := types.NewLondonSigner(chainID)
    signedTx,err := types.SignTx(tx,signer,privatekey)
    if err != nil {
        log.Fatalf("failed to sign transaction: %v", err)
    }

    //发送交易
    if err := client.SendTransaction(ctx,signedTx); err != nil {
        log.Fatalf("failed to send transaction: %v", err)
    }

    //交易信息
    fmt.Println("=== Transaction Sent ===")
    fmt.Printf("From       : %s\n", fromAddress.Hex())
    fmt.Printf("To         : %s\n", toAddr.Hex())
    fmt.Printf("Value      : %s ETH (%s Wei)\n",fmt.Sprintf("%.6f", amountEth), valueWei.String())
    fmt.Printf("Gas Limit  : %d\n", gasLimit)
    fmt.Printf("Gas Tip Cap: %s Wei\n", gasTipCap.String())
    fmt.Printf("Gas Fee Cap: %s Wei\n", gasFeeCap.String())
    fmt.Printf("Nonce      : %d\n", nonce)
    fmt.Printf("Tx Hash    : %s\n", signedTx.Hash().Hex())
    fmt.Println("\nTransaction is pending. Use --tx flag to query status:")
    fmt.Printf("  go run main.go --tx %s\n", signedTx.Hash().Hex())
}

func PrintConsole() {

    err := godotenv.Load()
    if err != nil {
        log.Println("未找到.env文件")
    }

    rpcURL := os.Getenv("SEPOLIA_RPC_URL")
    if rpcURL == "" {
        log.Fatal("SEPOLIA_RPC_URL 未设置")
    }

    client,err := ethclient.Dial(rpcURL)
    if err != nil {
        log.Fatal("连接节点失败")
    }
    defer client.Close()
    fmt.Println("sepolia连接成功")

    blockNum := big.NewInt(123456)
    block,err := client.BlockByNumber(context.Background(),blockNum)
    if err != nil {
        log.Fatal("查询区块链失败")
    }

    //输出到控制台
    fmt.Println("\n========== 区块信息 ==========")
    fmt.Printf("区块号: %d\n", block.Number().Uint64())
    fmt.Printf("区块哈希: %s\n",block.Hash().Hex())
    fmt.Printf("父区块哈希: %s\n",block.ParentHash().Hex())
    dateTime := time.Unix(int64(block.Time()), 0).Format("2006-01-02 15:04:05")
    fmt.Printf("出块时间: %s\n", dateTime)
    fmt.Printf("交易数量: %d\n",len(block.Transactions()))
    fmt.Printf("旷工地址: %s\n",block.Coinbase().Hex())
}