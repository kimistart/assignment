pragma solidity =0.5.16; // 指定Solidity编译器版本，必须精确使用0.5.16

// 导入IUniswapV2Factory接口，定义工厂合约的标准函数
import './interfaces/IUniswapV2Factory.sol';
// 导入UniswapV2Pair合约，用于创建新交易对实例
import './UniswapV2Pair.sol';

// 声明工厂合约，实现IUniswapV2Factory接口
contract UniswapV2Factory is IUniswapV2Factory {
    // 手续费接收地址（例如协议费收取方）
    address public feeTo;
    // 有权修改feeTo和feeToSetter的地址
    address public feeToSetter;

    // 双重映射：token0 -> token1 -> pair地址，用于查询给定代币对是否存在
    mapping(address => mapping(address => address)) public getPair;
    // 存储所有已创建交易对地址的数组
    address[] public allPairs;

    // 交易对创建事件，记录两个代币地址和交易对地址以及当前交易对总数
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    // 构造函数，部署时设置feeToSetter地址
    constructor(address _feeToSetter) public {
        feeToSetter = _feeToSetter; // 初始化feeToSetter为传入地址
    }

    // 外部视图函数：返回已创建交易对的总数
    function allPairsLength() external view returns (uint) {
        return allPairs.length; // 直接返回allPairs数组长度
    }

    // 外部函数：创建新的交易对，tokenA和tokenB为两种代币地址（顺序无关）
    function createPair(address tokenA, address tokenB) external returns (address pair) {
        // 要求两个代币地址不相同
        require(tokenA != tokenB, 'UniswapV2: IDENTICAL_ADDRESSES');
        // 对代币地址排序，确保token0 < token1，方便统一存储
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        // 要求排序后的token0不为零地址
        require(token0 != address(0), 'UniswapV2: ZERO_ADDRESS');
        // 要求该交易对尚未创建（getPair默认零地址）
        require(getPair[token0][token1] == address(0), 'UniswapV2: PAIR_EXISTS'); // 单一检查足够
        // 获取UniswapV2Pair合约的创建字节码（不含构造函数参数）
        bytes memory bytecode = type(UniswapV2Pair).creationCode;
        // 计算用于create2的盐值，基于排序后的两个代币地址
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        // 使用内联汇编调用create2创建新合约
        assembly {
            // create2(值, 内存起始位置, 代码长度, 盐值) -> 新合约地址
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        // 调用新创建的交易对合约的initialize函数，设置token0和token1
        IUniswapV2Pair(pair).initialize(token0, token1);
        // 在正向映射中记录交易对地址
        getPair[token0][token1] = pair;
        // 在反向映射中也记录（方便通过(token1,token0)查询）
        getPair[token1][token0] = pair;
        // 将新交易对地址添加到allPairs数组
        allPairs.push(pair);
        // 触发PairCreated事件，传递两个代币地址、交易对地址和当前总数
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    // 外部函数：设置手续费接收地址，仅feeToSetter可调用
    function setFeeTo(address _feeTo) external {
        require(msg.sender == feeToSetter, 'UniswapV2: FORBIDDEN'); // 权限检查
        feeTo = _feeTo; // 更新feeTo地址
    }

    // 外部函数：设置新的feeToSetter地址，仅当前feeToSetter可调用
    function setFeeToSetter(address _feeToSetter) external {
        require(msg.sender == feeToSetter, 'UniswapV2: FORBIDDEN'); // 权限检查
        feeToSetter = _feeToSetter; // 更新feeToSetter地址
    }
}