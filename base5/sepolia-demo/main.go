package main

import(
    "context"
    "fmt"
    "log"
    "time"

    "sepolia-demo/counter"
    "github.com/ethereum/go-ethereum/ethclient"
    "github.com/ethereum/go-ethereum/crypto"
    "github.com/ethereum/go-ethereum/accounts/abi/bind"
)

func main() {

//     contractHex := flag.String("contract","","Counter.sol")
//     flag.Parse()

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
        log.Fatal("连接链失败")
    }
    defer client.Close()


//     contractAddr := common.HexToAddress(*contractHex)

    chainID,err := client.ChainID(context.Background())
    if err != nil {
        log.Fatal("获取 chainID 失败:", err)
    }

    privateKey,err := crypto.HexToECDSA(key)
    if err != nil {
        log.Fatal("私钥解析失败：",err)
    }

    auth,err := bind.NewKeyedTransactorWithChainID(privateKey,chainID)
    if err != nil {
        log.Fatal("创建授权失败：", err)
    }

    //合约部署
    auth.GasLimit = uint64(3000000)
    _,deployTx,deployedInstance,err := counter.DeployCounter(auth,client)
    if err != nil {
        log.Fatal("部署合约失败",err)
    }

    //等待部署上链
    receipt,err := bind.WaitMined(context.Background(),client,deployTx)
    if err != nil {
        log.Fatal("等待部署失败:",err)
    }
    log.Println("部署成功！合约地址：",receipt.ContractAddress.Hex())

    //调用getnumber
    count,err := deployedInstance.GetNumber(&bind.CallOpts{})
    if err != nil {
        log.Fatalf("failed to unpack output: %v",err)
    }

    fmt.Printf("Contact: %s\n",receipt.ContractAddress.Hex())
    fmt.Printf("当前计数：%s\n",count.String())

    //准备发送交易
    auth.GasLimit = 300000
    gasPrice,err := client.SuggestGasPrice(context.Background())
    if err != nil {
        log.Fatal("获取建议 gas price 失败:", err)
    }
    auth.GasPrice = gasPrice

    //调用increment
    incTx,err := deployedInstance.Increment(auth)
    if err != nil {
        log.Fatal("调用increment 失败：",err)
    }
    fmt.Printf("increment交易哈希:%s\n",incTx.Hash().Hex())

    //等待交易确认(上链)
    receipt,err = bind.WaitMined(context.Background(),client,incTx)
    if err != nil {
        log.Fatal("等待确认失败:",err)
    }
    fmt.Printf("交易确认于区块:%d\n",receipt.BlockNumber.Uint64())

    //再次计数
    newCount,err := deployedInstance.GetNumber(&bind.CallOpts{})
    if err != nil {
        log.Fatalf("再次读取失败：",err)
    }
    fmt.Printf("调用后计数: %s\n", newCount.String())
}

/**
zhaojingyi@DESKTOP-OHF4HJ2 MINGW64 /d/goProject/meta_node/sepolia-demo (master)
$ go run main.go
2026/04/16 11:53:40 部署成功！合约地址： 0x6a21dDD9Ac2d29E5f450eD12568704b0D925Ae8F
Contact: 0x6a21dDD9Ac2d29E5f450eD12568704b0D925Ae8F
当前计数：0
increment交易哈希:0xfee7f8dc89b68c42f126ffe79ea332d8f182aab97e64d1bda4de80eecf3e4d5b
交易确认于区块:10668968
调用后计数: 1
*/