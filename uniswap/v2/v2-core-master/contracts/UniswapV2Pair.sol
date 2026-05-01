pragma solidity =0.5.16; // 指定Solidity编译器版本，必须精确使用0.5.16

// 导入IUniswapV2Pair接口，定义交易对合约的标准函数
import './interfaces/IUniswapV2Pair.sol';
// 导入UniswapV2ERC20基础合约，实现ERC20代币功能
import './UniswapV2ERC20.sol';
// 导入Math库，提供平方根等数学函数
import './libraries/Math.sol';
// 导入UQ112x112库，用于定点数编码（112.112位）
import './libraries/UQ112x112.sol';
// 导入IERC20接口，用于与标准ERC20代币交互
import './interfaces/IERC20.sol';
// 导入IUniswapV2Factory接口，用于查询工厂合约信息
import './interfaces/IUniswapV2Factory.sol';
// 导入IUniswapV2Callee接口，用于闪电贷回调
import './interfaces/IUniswapV2Callee.sol';

// 声明交易对合约，继承自IUniswapV2Pair接口和UniswapV2ERC20合约
contract UniswapV2Pair is IUniswapV2Pair, UniswapV2ERC20 {
    // 对uint类型使用SafeMath库，确保算术安全
    using SafeMath  for uint;
    // 对uint224类型使用UQ112x112库（实际主要用于uint224编码）
    using UQ112x112 for uint224;

    // 最小流动性数值，永久锁定在零地址以防止通胀攻击
    uint public constant MINIMUM_LIQUIDITY = 10**3;
    // transfer函数的函数选择器：keccak256("transfer(address,uint256)")的前4字节
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

    // 工厂合约地址，用于获取手续费接收地址等信息
    address public factory;
    // 交易对中的第一种代币地址（经过排序，小于第二种）
    address public token0;
    // 交易对中的第二种代币地址（经过排序，大于第一种）
    address public token1;

    // 代币0的储备量（112位无符号整数，节省存储槽）
    uint112 private reserve0;
    // 代币1的储备量（112位无符号整数）
    uint112 private reserve1;
    // 最后一个区块的时间戳（32位），与reserve0/reserve1共同占用一个存储槽
    uint32  private blockTimestampLast;

    // 代币0的价格累积值（用于时间加权平均价格）
    uint public price0CumulativeLast;
    // 代币1的价格累积值（用于时间加权平均价格）
    uint public price1CumulativeLast;
    // 最后一次流动性事件后的k值（reserve0 * reserve1）
    uint public kLast;

    // 重入锁标志，1表示未锁定，0表示已锁定
    uint private unlocked = 1;
    // 修饰器：防止重入攻击，在执行函数期间锁定合约
    modifier lock() {
        require(unlocked == 1, 'UniswapV2: LOCKED'); // 要求未锁定
        unlocked = 0; // 锁定
        _; // 执行函数体
        unlocked = 1; // 解锁
    }

    // 公开视图函数：返回当前储备量（reserve0, reserve1）和最后更新时间戳
    function getReserves() public view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) {
        _reserve0 = reserve0; // 赋值reserve0
        _reserve1 = reserve1; // 赋值reserve1
        _blockTimestampLast = blockTimestampLast; // 赋值时间戳
    }

    // 私有函数：安全的代币转账（使用低级别call并验证返回结果）
    function _safeTransfer(address token, address to, uint value) private {
        // 调用代币的transfer函数，编码函数选择器和参数
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        // 要求调用成功，并且返回数据要么为空要么可解码为true
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'UniswapV2: TRANSFER_FAILED');
    }

    // 铸造事件：当添加流动性时触发
    event Mint(address indexed sender, uint amount0, uint amount1);
    // 销毁事件：当移除流动性时触发
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    // 兑换事件：当执行swap时触发
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    // 同步事件：当储备量更新时触发
    event Sync(uint112 reserve0, uint112 reserve1);

    // 构造函数：部署时由工厂合约调用，记录工厂地址
    constructor() public {
        factory = msg.sender; // 工厂地址为部署者（工厂合约）
    }

    // 初始化函数：在工厂使用create2创建合约后调用一次，设置两个代币地址
    function initialize(address _token0, address _token1) external {
        require(msg.sender == factory, 'UniswapV2: FORBIDDEN'); // 仅工厂可调用
        token0 = _token0; // 设置token0
        token1 = _token1; // 设置token1
    }

    // 内部函数：更新储备量，并累积价格（每个区块首次调用时更新累积器）
    function _update(uint balance0, uint balance1, uint112 _reserve0, uint112 _reserve1) private {
        // 要求balance0和balance1不超过112位最大值（防止溢出）
        require(balance0 <= uint112(-1) && balance1 <= uint112(-1), 'UniswapV2: OVERFLOW');
        // 获取当前区块时间戳的低32位（取模2^32）
        uint32 blockTimestamp = uint32(block.timestamp % 2**32);
        // 计算距离上次更新的时间差（允许溢出，因为只需要差值）
        uint32 timeElapsed = blockTimestamp - blockTimestampLast;
        // 如果时间差大于0且两个储备量均非零，则更新价格累积器
        if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
            // 价格 = reserve1 / reserve0，使用UQ112x112格式，乘以时间差并累加
            price0CumulativeLast += uint(UQ112x112.encode(_reserve1).uqdiv(_reserve0)) * timeElapsed;
            // 反向价格累加
            price1CumulativeLast += uint(UQ112x112.encode(_reserve0).uqdiv(_reserve1)) * timeElapsed;
        }
        // 更新储备量为当前余额
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        // 更新最后区块时间戳
        blockTimestampLast = blockTimestamp;
        // 触发Sync事件
        emit Sync(reserve0, reserve1);
    }

    // 内部函数：收取协议手续费（如果启用）
    function _mintFee(uint112 _reserve0, uint112 _reserve1) private returns (bool feeOn) {
        // 从工厂获取手续费接收地址
        address feeTo = IUniswapV2Factory(factory).feeTo();
        // 手续费是否开启：feeTo不为零地址
        feeOn = feeTo != address(0);
        // 保存kLast到内存（节省gas）
        uint _kLast = kLast;
        if (feeOn) { // 如果开启手续费
            if (_kLast != 0) { // 且上一次kLast非零
                // 计算当前sqrt(k)
                uint rootK = Math.sqrt(uint(_reserve0).mul(_reserve1));
                // 计算上一次sqrt(k)
                uint rootKLast = Math.sqrt(_kLast);
                if (rootK > rootKLast) { // 如果k增长了
                    // 计算增发的流动性：totalSupply * (rootK - rootKLast) / (rootK * 5 + rootKLast)
                    uint numerator = totalSupply.mul(rootK.sub(rootKLast));
                    uint denominator = rootK.mul(5).add(rootKLast);
                    uint liquidity = numerator / denominator;
                    if (liquidity > 0) _mint(feeTo, liquidity); // 铸造给feeTo地址
                }
            }
        } else if (_kLast != 0) { // 如果手续费关闭但kLast非零，则重置kLast
            kLast = 0;
        }
    }

    // 添加流动性：外部调用，需要重入锁
    function mint(address to) external lock returns (uint liquidity) {
        // 获取当前储备量（节省gas）
        (uint112 _reserve0, uint112 _reserve1,) = getReserves();
        // 合约中token0的当前余额
        uint balance0 = IERC20(token0).balanceOf(address(this));
        // 合约中token1的当前余额
        uint balance1 = IERC20(token1).balanceOf(address(this));
        // 存入的token0数量 = 当前余额 - 储备量
        uint amount0 = balance0.sub(_reserve0);
        // 存入的token1数量 = 当前余额 - 储备量
        uint amount1 = balance1.sub(_reserve1);

        // 收取手续费（可能铸造新流动性给feeTo）
        bool feeOn = _mintFee(_reserve0, _reserve1);
        // 保存总供应量（因为_mintFee可能改变totalSupply）
        uint _totalSupply = totalSupply;
        if (_totalSupply == 0) { // 首次添加流动性
            // 流动性 = sqrt(amount0 * amount1) - MINIMUM_LIQUIDITY
            liquidity = Math.sqrt(amount0.mul(amount1)).sub(MINIMUM_LIQUIDITY);
            // 将MINIMUM_LIQUIDITY永久锁在零地址
            _mint(address(0), MINIMUM_LIQUIDITY);
        } else {
            // 非首次：流动性 = min(amount0 * totalSupply / reserve0, amount1 * totalSupply / reserve1)
            liquidity = Math.min(amount0.mul(_totalSupply) / _reserve0, amount1.mul(_totalSupply) / _reserve1);
        }
        // 要求铸造的流动性大于0
        require(liquidity > 0, 'UniswapV2: INSUFFICIENT_LIQUIDITY_MINTED');
        // 铸造流动性给to地址
        _mint(to, liquidity);

        // 更新储备量为当前余额
        _update(balance0, balance1, _reserve0, _reserve1);
        // 如果手续费开启，更新kLast为reserve0 * reserve1
        if (feeOn) kLast = uint(reserve0).mul(reserve1);
        // 触发Mint事件
        emit Mint(msg.sender, amount0, amount1);
    }

    // 移除流动性：外部调用，需要重入锁，返回获得的代币数量
    function burn(address to) external lock returns (uint amount0, uint amount1) {
        // 获取当前储备量
        (uint112 _reserve0, uint112 _reserve1,) = getReserves();
        // 缓存token0地址（节省gas）
        address _token0 = token0;
        // 缓存token1地址
        address _token1 = token1;
        // 合约中token0的余额
        uint balance0 = IERC20(_token0).balanceOf(address(this));
        // 合约中token1的余额
        uint balance1 = IERC20(_token1).balanceOf(address(this));
        // 当前合约持有的流动性代币数量（即要销毁的LP代币数量）
        uint liquidity = balanceOf[address(this)];

        // 收取手续费
        bool feeOn = _mintFee(_reserve0, _reserve1);
        // 保存总供应量
        uint _totalSupply = totalSupply;
        // 计算可获得的token0数量 = liquidity * balance0 / totalSupply
        amount0 = liquidity.mul(balance0) / _totalSupply;
        // 计算可获得的token1数量 = liquidity * balance1 / totalSupply
        amount1 = liquidity.mul(balance1) / _totalSupply;
        // 要求两种数量均大于0
        require(amount0 > 0 && amount1 > 0, 'UniswapV2: INSUFFICIENT_LIQUIDITY_BURNED');
        // 销毁本合约持有的流动性代币
        _burn(address(this), liquidity);
        // 安全转移token0给to
        _safeTransfer(_token0, to, amount0);
        // 安全转移token1给to
        _safeTransfer(_token1, to, amount1);
        // 更新token0余额（因为转账后余额变化）
        balance0 = IERC20(_token0).balanceOf(address(this));
        // 更新token1余额
        balance1 = IERC20(_token1).balanceOf(address(this));

        // 更新储备量
        _update(balance0, balance1, _reserve0, _reserve1);
        // 如果手续费开启，更新kLast
        if (feeOn) kLast = uint(reserve0).mul(reserve1);
        // 触发Burn事件
        emit Burn(msg.sender, amount0, amount1, to);
    }

    // 兑换：外部调用，实现代币交换
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external lock {
        // 要求至少有一个输出数量大于0
        require(amount0Out > 0 || amount1Out > 0, 'UniswapV2: INSUFFICIENT_OUTPUT_AMOUNT');
        // 获取当前储备量
        (uint112 _reserve0, uint112 _reserve1,) = getReserves();
        // 要求输出数量不超过当前储备量
        require(amount0Out < _reserve0 && amount1Out < _reserve1, 'UniswapV2: INSUFFICIENT_LIQUIDITY');

        uint balance0;
        uint balance1;
        { // 作用域，避免堆栈过深
            address _token0 = token0; // 缓存token0
            address _token1 = token1; // 缓存token1
            // 要求to地址不等于任一token地址（防止错误路由）
            require(to != _token0 && to != _token1, 'UniswapV2: INVALID_TO');
            // 如果输出token0大于0，则转移给to
            if (amount0Out > 0) _safeTransfer(_token0, to, amount0Out);
            // 如果输出token1大于0，则转移给to
            if (amount1Out > 0) _safeTransfer(_token1, to, amount1Out);
            // 如果回调数据非空，则调用接收者的uniswapV2Call回调（闪电贷）
            if (data.length > 0) IUniswapV2Callee(to).uniswapV2Call(msg.sender, amount0Out, amount1Out, data);
            // 获取转账后的余额
            balance0 = IERC20(_token0).balanceOf(address(this));
            balance1 = IERC20(_token1).balanceOf(address(this));
        }
        // 计算实际输入的token0数量 = 当前余额 - (原储备量 - 输出数量)
        uint amount0In = balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0;
        // 计算实际输入的token1数量
        uint amount1In = balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0;
        // 要求至少有一种输入数量大于0
        require(amount0In > 0 || amount1In > 0, 'UniswapV2: INSUFFICIENT_INPUT_AMOUNT');
        { // 作用域，避免堆栈过深
            // 调整后的余额：减去0.3%手续费（实际乘1000减3*输入量）
            uint balance0Adjusted = balance0.mul(1000).sub(amount0In.mul(3));
            uint balance1Adjusted = balance1.mul(1000).sub(amount1In.mul(3));
            // 要求调整后的k值 >= 原k值 * 1000^2（恒定乘积公式）
            require(balance0Adjusted.mul(balance1Adjusted) >= uint(_reserve0).mul(_reserve1).mul(1000**2), 'UniswapV2: K');
        }

        // 更新储备量
        _update(balance0, balance1, _reserve0, _reserve1);
        // 触发Swap事件
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }

    // 强制将合约中超出储备量的代币转移到to（用于回收误差或意外转账）
    function skim(address to) external lock {
        address _token0 = token0; // 缓存token0
        address _token1 = token1; // 缓存token1
        // 转移token0的超额部分：当前余额 - reserve0
        _safeTransfer(_token0, to, IERC20(_token0).balanceOf(address(this)).sub(reserve0));
        // 转移token1的超额部分
        _safeTransfer(_token1, to, IERC20(_token1).balanceOf(address(this)).sub(reserve1));
    }

    // 强制将储备量同步为当前余额（如果出现偏差则纠正）
    function sync() external lock {
        // 使用当前两个代币的余额更新储备量
        _update(IERC20(token0).balanceOf(address(this)), IERC20(token1).balanceOf(address(this)), reserve0, reserve1);
    }
}