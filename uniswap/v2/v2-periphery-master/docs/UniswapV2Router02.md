# UniswapV2Router02 接口文档

## 概述
   uniswapv2 外围接口

## 合约信息
  - 合约地址
  - 继承关系

## 状态变量
  （只列 public 的，外部可读的）
  factory: factory合约地址
  WETH: WETH合约地址

## 方法（按功能分组）
  
### 添加流动性

**函数签名**
#### addLiquidity 投入两种ERC20token的流动性，获得LP token。
```javascript
function addLiquidity(
    address tokenA,  //tokenA币种地址
    address tokenB,  //tokenB币种地址
    uint amountADesired,   //期望投入的tokenA的数量
    uint amountBDesired,   //期望投入的tokenB的数量
    uint amountAMin,   //期望投入的tokenA的最少数量
    uint amountBMin,   //期望投入的tokenB的最少数量
    address to,        //LP token 的接收地址
    uint deadline      //交易截止时间
) external returns (
    uint amountA,  //实际投入的tokenA的数量
    uint amountB,  //实际投入的tokenB的数量
    uint liquidity //LP token的数量
    )
```

### 移除流动性
### 交换
### 查询