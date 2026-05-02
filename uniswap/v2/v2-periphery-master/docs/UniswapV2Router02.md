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

#### addLiquidity 投入两种ERC20token的流动性，获得LP token。
```javascript
function addLiquidity(
    address tokenA,  //tokenA币种地址
    address tokenB,  //tokenB币种地址
    uint amountADesired,   //投入的tokenA的数量
    uint amountBDesired,   //投入的tokenB的数量
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
```javascript
function addLiquidityETH(
        address token, //tokenB地址
        uint amountTokenDesired, //投入的tokenB的数量
        uint amountTokenMin, //期望投入的tokenB的最小数量
        uint amountETHMin, //期望投入的ETh的最小数量
        address to, //LP接收地址
        uint deadline //交易截止时间
    ) external returns (
      uint amountToken, //实际交易tokenB数量
      uint amountETH, //实际交易ETH数量
      uint liquidity) //LP数量
```
```javascript
    function _addLiquidity(
        address tokenA, //tokenA地址
        address tokenB, //tokenB地址
        uint amountADesired, //投入的tokenA的数量
        uint amountBDesired, //投入的tokenB的数量
        uint amountAMin, //期望投入的tokenA的最小数量
        uint amountBMin //期望投入的tokenB的最小数量
    ) internal returns (
      uint amountA, // 实际交易的tokenA的数量
      uint amountB) //实际交易的tokenB的数量
```
### 移除流动性
```javascript
function removeLiquidity(
        address tokenA, //tokenA地址
        address tokenB, //tokenB地址
        uint liquidity, //LPtoken数量
        uint amountAMin, //最小回兑的tokenA数量
        uint amountBMin, //最小回兑的tokenB数量
        address to, //回兑地址
        uint deadline //交易截止时间
    ) public returns (
      uint amountA,  //实际回兑的tokenA的数量
      uint amountB) //实际回兑的tokenB的数量
```
```javascript
    function removeLiquidityETH(
        address token, //tokenB地址
        uint liquidity, //LPtoken数量
        uint amountTokenMin, //tokenB最小回兑数量
        uint amountETHMin, //eth最小回兑数量
        address to, //回兑地址
        uint deadline //交易截止时间
    ) public returns (
      uint amountToken, //实际回兑的tokenB数量 
      uint amountETH)  //实际回兑的eth数量
```
```javascript
function removeLiquidityWithPermit( //使用链下签名移除流动性
        address tokenA, //tokenA地址
        address tokenB, //tokenB地址
        uint liquidity, //LPtoken数量
        uint amountAMin, //最小回兑的tokenA数量
        uint amountBMin, //最小回兑的tokenB数量
        address to, //回兑地址
        uint deadline, //交易截止时间
        bool approveMax, //是否授权全部LPtoken
        uint8 v, bytes32 r, bytes32 s //链下签名三要素
    ) external returns (
      uint amountA,   //实际回兑的tokenA的数量
      uint amountB) //实际回兑的tokenB的数量
```
```javascript
function removeLiquidityETHWithPermit(
        address token, //tokenB地址
        uint liquidity, //LPtoken数量
        uint amountTokenMin, //最小回兑的tokenA数量
        uint amountETHMin, //最小回兑的ETH数量
        address to, //回兑地址
        uint deadline, //交易截止时间
        bool approveMax,  //是否授权全部LPtoken
        uint8 v, bytes32 r, bytes32 s  //链下签名三要素
    ) external returns (
      uint amountToken,   //实际回兑的tokenB的数量
      uint amountETH)   //实际回兑的ETH的数量
```
```javascript
// **** REMOVE LIQUIDITY (supporting fee-on-transfer tokens) ****
function removeLiquidityETHSupportingFeeOnTransferTokens(
    address token,   //tokenB地址
    uint liquidity, //LPtoken数量
    uint amountTokenMin, //最小回兑的tokenA数量
    uint amountETHMin,//最小回兑的ETH数量
    address to, //回兑地址
    uint deadline //交易截止时间
) public returns (
  uint amountETH) //返回的eth数量
```
```javascript
function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,  //tokenB地址
        uint liquidity, //LPtoken数量
        uint amountTokenMin, //最小回兑的tokenA数量
        uint amountETHMin,//最小回兑的ETH数量
        address to,//回兑地址
        uint deadline, //交易截止时间
        bool approveMax,  //是否授权全部LPtoken
        uint8 v, bytes32 r, bytes32 s //链下签名三要素
    ) external returns (
      uint amountETH) //返回的eth数量
```
### 交换
```javascript
function swapExactTokensForTokens(
    uint amountIn, //投入的token数量
    uint amountOutMin, //兑换的token最小数量
    address[] calldata path, //兑换路径
    address to, //兑换代币接收地址
    uint deadline //交易截止日期
) external returns (
  uint[] memory amounts) //每跳兑换的代币数量
```
```javascript
function swapTokensForExactTokens(
    uint amountOut, //输出token的数量 
    uint amountInMax, //需要投入的最大token数量
    address[] calldata path, //兑换路径
    address to, //amountout的接收地址
    uint deadline //交易截止时间
) external returns (
  uint[] memory amounts) //每跳兑换的代币数量
```
```javascript
function swapExactETHForTokens(
  uint amountOutMin,  //要兑换的最少token数量
  address[] calldata path,  //兑换路径
  address to,  //amountout的接收地址
  uint deadline //交易截止时间
)external returns (
uint[] memory amounts)//每跳兑换的代币数量
```
```javascript
function swapTokensForExactETH(
  uint amountOut, //想要兑换的ETH数量
  uint amountInMax, //最多付出多少token
  address[] calldata path, //兑换路径
  address to, //amountout的接收地址
  uint deadline) //交易截止日期
external returns (
  uint[] memory amounts) //每跳兑换的代币数量
```
```javascript
function swapExactTokensForETH(
  uint amountIn, //输入的token数量
  uint amountOutMin, //想要兑换的eth的最少数量
  address[] calldata path,  //兑换路径
  address to, //eth接收地址
  uint deadline) //交易截止日期
external returns (
  uint[] memory amounts) //每跳兑换的代币数量
```
```javascript
function swapETHForExactTokens(
  uint amountOut, //要兑换多少token
  address[] calldata path, //兑换路径
  address to, //接收token的地址
  uint deadline) //交易截止日期
external returns (
  uint[] memory amounts) //每跳兑换的代币数量
```
```javascript
function _swapSupportingFeeOnTransferTokens(
  address[] memory path, //兑换路径
  address _to) //输出token的接收地址
  internal 
```
```javascript
function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn, //投入token
        uint amountOutMin, //期望兑换的最少token
        address[] calldata path, //兑换路径
        address to, //接收amountout的地址
        uint deadline //交易截止日期
    ) external
```
```javascript
function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin, //最少收到多少token
        address[] calldata path, //兑换路径
        address to, //token接收地址
        uint deadline //交易截止日期
    ) external
```
```javascript
function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn, //输入的token数量
        uint amountOutMin, //期望得到的最少eth
        address[] calldata path, //兑换路径
        address to, //接收eth的地址
        uint deadline //交易截止日期
    ) external
```
```javascript
function _swap(
  uint[] memory amounts, //每跳兑换数量
  address[] memory path, //兑换路径
  address _to //输出token的接收地址
  ) internal
```
### 查询
```javascript
//计算等价数量token
function quote(
  uint amountA,  //tokenA的数量
  uint reserveA,  //池子中tokenA的数量
  uint reserveB  //池子中tokenB的数量
  ) public returns (
  uint amountB) //等价tokenB的数量
```
```javascript
//给定输入量，扣除手续费后，计算输出量
function getAmountOut(
  uint amountIn,  //输入token数量
  uint reserveIn, //池中输入token数量
  uint reserveOut) //池中输出token的数量
 public returns (
  uint amountOut) //计算的输出量
```
```javascript
//包含手续费
function getAmountIn(
  uint amountOut, //输出token数量
  uint reserveIn, //池中输入token的总量
  uint reserveOut) //池中输出token的总量
public returns (
  uint amountIn) //计算要投入多少token
```
```javascript
//按路径正向推算每一跳的输出量（用于 swapExact 系列）
function getAmountsOut(
  uint amountIn,  //输入token数量
  address[] memory path) //兑换路径
public  returns (
  uint[] memory amounts) //每跳兑换的token数量
```
```javascript
//按路径反向推算每一跳的输入量（用于 swapForExact 系列）
function getAmountsIn(
  uint amountOut,  // 期望最终获得的输出 token 数量
  address[] memory path) //兑换路径
public returns (
  uint[] memory amounts) //每跳兑换的token数量,返回数组长度与 path 相同
```