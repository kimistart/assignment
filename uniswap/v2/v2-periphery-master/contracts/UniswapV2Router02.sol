pragma solidity =0.6.6;

import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/lib/contracts/libraries/TransferHelper.sol';

import './interfaces/IUniswapV2Router02.sol';
import './libraries/UniswapV2Library.sol';
import './libraries/SafeMath.sol';
import './interfaces/IERC20.sol';
import './interfaces/IWETH.sol';

contract UniswapV2Router02 is IUniswapV2Router02 {
    using SafeMath for uint;

    // factory 合约地址，用于查找和创建交易对
    address public immutable override factory;
    // WETH 合约地址，ETH 需要先包装成 WETH 才能参与 ERC20 交易
    address public immutable override WETH;

    // 交易截止时间校验：超过 deadline 则 revert，防止交易长时间挂单后以不利价格成交
    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'UniswapV2Router: EXPIRED');
        _;
    }

    constructor(address _factory, address _WETH) public {
        factory = _factory;
        WETH = _WETH;
    }

    // 只接受来自 WETH 合约的 ETH，即 WETH.withdraw() 时的回款
    // 防止用户直接往 Router 转 ETH
    receive() external payable {
        assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }

    // **** ADD LIQUIDITY ****

    // 内部函数：计算实际应注入的两种 token 数量
    // 核心逻辑：按当前池子比例对齐，不能打破现有价格
    function _addLiquidity(
        address tokenA,        // 注入的第一种 token 地址
        address tokenB,        // 注入的第二种 token 地址
        uint amountADesired,   // 期望注入的 tokenA 最大数量
        uint amountBDesired,   // 期望注入的 tokenB 最大数量
        uint amountAMin,       // 实际注入 tokenA 的最小可接受数量（滑点保护）
        uint amountBMin        // 实际注入 tokenB 的最小可接受数量（滑点保护）
    ) internal virtual returns (uint amountA, uint amountB) {
        // 如果交易对不存在则先创建
        if (IUniswapV2Factory(factory).getPair(tokenA, tokenB) == address(0)) {
            IUniswapV2Factory(factory).createPair(tokenA, tokenB);
        }
        (uint reserveA, uint reserveB) = UniswapV2Library.getReserves(factory, tokenA, tokenB);
        if (reserveA == 0 && reserveB == 0) {
            // 全新池子，没有已有比例约束，直接按用户期望数量注入
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            // 按当前比例计算注入 amountADesired 时对应的最优 B 数量
            uint amountBOptimal = UniswapV2Library.quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                // B 的最优用量不超过期望值，优先固定 A，缩减 B
                require(amountBOptimal >= amountBMin, 'UniswapV2Router: INSUFFICIENT_B_AMOUNT');
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                // B 的最优用量超过期望值，说明 B 相对较贵，改为固定 B，缩减 A
                uint amountAOptimal = UniswapV2Library.quote(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                require(amountAOptimal >= amountAMin, 'UniswapV2Router: INSUFFICIENT_A_AMOUNT');
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }

    // 添加两种 ERC20 token 的流动性
    // 返回实际注入的两种 token 数量及获得的 LP token 数量
    function addLiquidity(
        address tokenA,        // 注入的第一种 token 地址
        address tokenB,        // 注入的第二种 token 地址
        uint amountADesired,   // 期望注入的 tokenA 最大数量
        uint amountBDesired,   // 期望注入的 tokenB 最大数量
        uint amountAMin,       // 实际注入 tokenA 的最小可接受数量（滑点保护）
        uint amountBMin,       // 实际注入 tokenB 的最小可接受数量（滑点保护）
        address to,            // LP token 的接收地址
        uint deadline          // 交易截止时间戳，超时则 revert
    ) external virtual override ensure(deadline) returns (uint amountA, uint amountB, uint liquidity) {
        // 计算按比例对齐后的实际注入量
        (amountA, amountB) = _addLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin);
        address pair = UniswapV2Library.pairFor(factory, tokenA, tokenB);
        // 将两种 token 从用户钱包转入 pair 合约
        TransferHelper.safeTransferFrom(tokenA, msg.sender, pair, amountA);
        TransferHelper.safeTransferFrom(tokenB, msg.sender, pair, amountB);
        // pair 合约 mint LP token 给 to 地址
        liquidity = IUniswapV2Pair(pair).mint(to);
    }

    // 添加 token + ETH 的流动性
    // msg.value 即为 amountETHDesired（ETH 随交易直接发送，无需单独参数）
    function addLiquidityETH(
        address token,           // 与 ETH 配对的 ERC20 token 地址
        uint amountTokenDesired, // 期望注入的 token 最大数量
        uint amountTokenMin,     // 实际注入 token 的最小可接受数量（滑点保护）
        uint amountETHMin,       // 实际注入 ETH 的最小可接受数量（滑点保护）
        address to,              // LP token 的接收地址
        uint deadline            // 交易截止时间戳，超时则 revert
    ) external virtual override payable ensure(deadline) returns (uint amountToken, uint amountETH, uint liquidity) {
        // msg.value 作为 ETH 的期望注入量传入，内部按比例对齐
        (amountToken, amountETH) = _addLiquidity(
            token,
            WETH,
            amountTokenDesired,
            msg.value,
            amountTokenMin,
            amountETHMin
        );
        address pair = UniswapV2Library.pairFor(factory, token, WETH);
        // 将 token 从用户钱包转入 pair
        TransferHelper.safeTransferFrom(token, msg.sender, pair, amountToken);
        // 将 ETH 包装成 WETH 后转入 pair
        IWETH(WETH).deposit{value: amountETH}();
        assert(IWETH(WETH).transfer(pair, amountETH));
        // mint LP token
        liquidity = IUniswapV2Pair(pair).mint(to);
        // 若用户发送的 ETH 多于实际使用量，退还多余部分
        if (msg.value > amountETH) TransferHelper.safeTransferETH(msg.sender, msg.value - amountETH);
    }

    // **** REMOVE LIQUIDITY ****

    // 撤除两种 ERC20 token 的流动性
    function removeLiquidity(
        address tokenA,    // 交易对中的第一种 token 地址
        address tokenB,    // 交易对中的第二种 token 地址
        uint liquidity,    // 要销毁的 LP token 数量
        uint amountAMin,   // 期望取回 tokenA 的最小数量（滑点保护）
        uint amountBMin,   // 期望取回 tokenB 的最小数量（滑点保护）
        address to,        // 取回的两种 token 的接收地址
        uint deadline      // 交易截止时间戳，超时则 revert
    ) public virtual override ensure(deadline) returns (uint amountA, uint amountB) {
        address pair = UniswapV2Library.pairFor(factory, tokenA, tokenB);
        // 将 LP token 从用户钱包转回 pair 合约（需要用户提前 approve 或使用 permit）
        IUniswapV2Pair(pair).transferFrom(msg.sender, pair, liquidity); // send liquidity to pair
        // pair 合约销毁 LP token，按比例返还两种 token 给 to 地址
        (uint amount0, uint amount1) = IUniswapV2Pair(pair).burn(to);
        // pair 内部按地址升序排列 token0/token1，需要还原为用户传入的 tokenA/tokenB 顺序
        (address token0,) = UniswapV2Library.sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
        // 滑点保护：返还数量不得低于用户设定的最小值
        require(amountA >= amountAMin, 'UniswapV2Router: INSUFFICIENT_A_AMOUNT');
        require(amountB >= amountBMin, 'UniswapV2Router: INSUFFICIENT_B_AMOUNT');
    }

    // 撤除 token + ETH 的流动性
    // 内部复用 removeLiquidity，再将 WETH 解包成 ETH 发给用户
    function removeLiquidityETH(
        address token,         // 与 ETH 配对的 ERC20 token 地址
        uint liquidity,        // 要销毁的 LP token 数量
        uint amountTokenMin,   // 期望取回 token 的最小数量（滑点保护）
        uint amountETHMin,     // 期望取回 ETH 的最小数量（滑点保护）
        address to,            // 取回的 token 和 ETH 的接收地址
        uint deadline          // 交易截止时间戳，超时则 revert
    ) public virtual override ensure(deadline) returns (uint amountToken, uint amountETH) {
        // to 先设为 address(this)，让 Router 先收到 WETH
        (amountToken, amountETH) = removeLiquidity(
            token,
            WETH,
            liquidity,
            amountTokenMin,
            amountETHMin,
            address(this),
            deadline
        );
        // 将 token 转给用户
        TransferHelper.safeTransfer(token, to, amountToken);
        // 将 WETH 解包成 ETH，再转给用户
        IWETH(WETH).withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);
    }

    // 使用链下签名（EIP-2612 permit）撤除流动性，无需单独发 approve 交易
    function removeLiquidityWithPermit(
        address tokenA,      // 交易对中的第一种 token 地址
        address tokenB,      // 交易对中的第二种 token 地址
        uint liquidity,      // 要销毁的 LP token 数量
        uint amountAMin,     // 期望取回 tokenA 的最小数量（滑点保护）
        uint amountBMin,     // 期望取回 tokenB 的最小数量（滑点保护）
        address to,          // 取回的两种 token 的接收地址
        uint deadline,       // 交易截止时间戳，超时则 revert（同时也是签名的有效期）
        bool approveMax,     // true 表示授权最大值（无限授权），false 表示仅授权本次 liquidity 数量
        uint8 v,             // ECDSA 签名的 v 分量
        bytes32 r,           // ECDSA 签名的 r 分量
        bytes32 s            // ECDSA 签名的 s 分量
    ) external virtual override returns (uint amountA, uint amountB) {
        address pair = UniswapV2Library.pairFor(factory, tokenA, tokenB);
        // approveMax=true 时授权最大值（无限授权），否则仅授权本次用量
        uint value = approveMax ? uint(-1) : liquidity;
        // 链上验证签名，写入 allowance，等价于 pair.approve(router, value)
        IUniswapV2Pair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        // allowance 已到位，直接撤流动性
        (amountA, amountB) = removeLiquidity(tokenA, tokenB, liquidity, amountAMin, amountBMin, to, deadline);
    }

    // 使用 permit 签名撤除 token + ETH 的流动性
    function removeLiquidityETHWithPermit(
        address token,       // 与 ETH 配对的 ERC20 token 地址
        uint liquidity,      // 要销毁的 LP token 数量
        uint amountTokenMin, // 期望取回 token 的最小数量（滑点保护）
        uint amountETHMin,   // 期望取回 ETH 的最小数量（滑点保护）
        address to,          // 取回的 token 和 ETH 的接收地址
        uint deadline,       // 交易截止时间戳，超时则 revert（同时也是签名的有效期）
        bool approveMax,     // true 表示授权最大值（无限授权），false 表示仅授权本次 liquidity 数量
        uint8 v,             // ECDSA 签名的 v 分量
        bytes32 r,           // ECDSA 签名的 r 分量
        bytes32 s            // ECDSA 签名的 s 分量
    ) external virtual override returns (uint amountToken, uint amountETH) {
        address pair = UniswapV2Library.pairFor(factory, token, WETH);
        uint value = approveMax ? uint(-1) : liquidity;
        // 链上验证签名，写入 allowance
        IUniswapV2Pair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountToken, amountETH) = removeLiquidityETH(token, liquidity, amountTokenMin, amountETHMin, to, deadline);
    }

    // **** REMOVE LIQUIDITY (supporting fee-on-transfer tokens) ****

    // 支持通缩 token（转账时自动扣费）的 ETH 撤流动性
    // 普通版本在 removeLiquidity 内部对 token 返还量有精确预期，通缩 token 会因实到量偏少而 revert
    // 此版本改为撤出后直接查余额，绕过精确预期校验
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,         // 与 ETH 配对的通缩 ERC20 token 地址
        uint liquidity,        // 要销毁的 LP token 数量
        uint amountTokenMin,   // 期望取回 token 的最小数量（滑点保护）
        uint amountETHMin,     // 期望取回 ETH 的最小数量（滑点保护）
        address to,            // 取回的 token 和 ETH 的接收地址
        uint deadline          // 交易截止时间戳，超时则 revert
    ) public virtual override ensure(deadline) returns (uint amountETH) {
        // token 撤回量忽略（通缩 token 实到量不可预知），只取 amountETH
        (, amountETH) = removeLiquidity(
            token,
            WETH,
            liquidity,
            amountTokenMin,
            amountETHMin,
            address(this),
            deadline
        );
        // 查询 Router 实际持有的 token 余额，全额转给用户（而非依赖返回值）
        TransferHelper.safeTransfer(token, to, IERC20(token).balanceOf(address(this)));
        IWETH(WETH).withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);
    }

    // 支持通缩 token 的 permit 版本撤流动性
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,       // 与 ETH 配对的通缩 ERC20 token 地址
        uint liquidity,      // 要销毁的 LP token 数量
        uint amountTokenMin, // 期望取回 token 的最小数量（滑点保护）
        uint amountETHMin,   // 期望取回 ETH 的最小数量（滑点保护）
        address to,          // 取回的 token 和 ETH 的接收地址
        uint deadline,       // 交易截止时间戳，超时则 revert（同时也是签名的有效期）
        bool approveMax,     // true 表示授权最大值（无限授权），false 表示仅授权本次 liquidity 数量
        uint8 v,             // ECDSA 签名的 v 分量
        bytes32 r,           // ECDSA 签名的 r 分量
        bytes32 s            // ECDSA 签名的 s 分量
    ) external virtual override returns (uint amountETH) {
        address pair = UniswapV2Library.pairFor(factory, token, WETH);
        uint value = approveMax ? uint(-1) : liquidity;
        IUniswapV2Pair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        amountETH = removeLiquidityETHSupportingFeeOnTransferTokens(
            token, liquidity, amountTokenMin, amountETHMin, to, deadline
        );
    }

    // **** SWAP ****
    // requires the initial amount to have already been sent to the first pair

    // 内部函数：按路径逐跳执行 swap
    // amounts 由外部提前算好，此函数只负责按数字执行转账和调用
    function _swap(
        uint[] memory amounts,   // 每一跳的金额数组，amounts[0] 为输入量，amounts[n] 为最终输出量
        address[] memory path,   // 交易路径，如 [USDC, WETH, DAI] 表示 USDC→WETH→DAI
        address _to              // 最终输出 token 的接收地址
    ) internal virtual {
        // path 示例: [USDC, WETH, DAI]，循环次数 = 跳数 = path.length - 1
        for (uint i; i < path.length - 1; i++) {
            // 本跳的输入和输出 token
            (address input, address output) = (path[i], path[i + 1]);
            // pair 内部按地址升序排列 token0/token1，需要判断 input 对应哪个槽位
            (address token0,) = UniswapV2Library.sortTokens(input, output);
            // 本跳应输出的数量（从预算数组取下一位）
            uint amountOut = amounts[i + 1];
            // pair.swap 需要分别指定 token0 和 token1 的输出量，未输出方向填 0
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
            // 多跳时输出直接打给下一个 pair，最后一跳打给最终接收地址，省去中间 transfer
            address to = i < path.length - 2 ? UniswapV2Library.pairFor(factory, output, path[i + 2]) : _to;
            IUniswapV2Pair(UniswapV2Library.pairFor(factory, input, output)).swap(
                amount0Out, amount1Out, to, new bytes(0)
            );
        }
    }

    // 精确输入换 token：指定确切的输入量，要求输出不低于 amountOutMin
    function swapExactTokensForTokens(
        uint amountIn,              // 确切的输入 token 数量
        uint amountOutMin,          // 期望收到的输出 token 最小数量（滑点保护）
        address[] calldata path,    // 交易路径，path[0] 为输入 token，path[最后] 为输出 token
        address to,                 // 输出 token 的接收地址
        uint deadline               // 交易截止时间戳，超时则 revert
    ) external virtual override ensure(deadline) returns (uint[] memory amounts) {
        // 按路径正向推算每一跳的输出量
        amounts = UniswapV2Library.getAmountsOut(factory, amountIn, path);
        // 滑点保护：最终输出不得低于用户设定的最小值
        require(amounts[amounts.length - 1] >= amountOutMin, 'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT');
        // 将输入 token 从用户钱包直接转入第一个 pair
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, to);
    }

    // 精确输出换 token：指定确切的输出量，要求输入不超过 amountInMax
    function swapTokensForExactTokens(
        uint amountOut,             // 确切期望收到的输出 token 数量
        uint amountInMax,           // 愿意支付的输入 token 最大数量（滑点保护）
        address[] calldata path,    // 交易路径，path[0] 为输入 token，path[最后] 为输出 token
        address to,                 // 输出 token 的接收地址
        uint deadline               // 交易截止时间戳，超时则 revert
    ) external virtual override ensure(deadline) returns (uint[] memory amounts) {
        // 按路径反向推算需要投入的数量
        amounts = UniswapV2Library.getAmountsIn(factory, amountOut, path);
        // 滑点保护：实际需要投入不得超过用户设定的最大值
        require(amounts[0] <= amountInMax, 'UniswapV2Router: EXCESSIVE_INPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, to);
    }

    // 精确 ETH 换 token：msg.value 为确切输入的 ETH 量，要求输出不低于 amountOutMin
    function swapExactETHForTokens(
        uint amountOutMin,          // 期望收到的输出 token 最小数量（滑点保护）
        address[] calldata path,    // 交易路径，path[0] 必须是 WETH，path[最后] 为目标 token
        address to,                 // 输出 token 的接收地址
        uint deadline               // 交易截止时间戳，超时则 revert
    )
        external
        virtual
        override
        payable
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        // 路径第一个必须是 WETH
        require(path[0] == WETH, 'UniswapV2Router: INVALID_PATH');
        amounts = UniswapV2Library.getAmountsOut(factory, msg.value, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT');
        // 将 ETH 包装成 WETH 并转入第一个 pair
        IWETH(WETH).deposit{value: amounts[0]}();
        assert(IWETH(WETH).transfer(UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]));
        _swap(amounts, path, to);
    }

    // token 换精确 ETH：指定确切的 ETH 输出量，要求输入 token 不超过 amountInMax
    function swapTokensForExactETH(
        uint amountOut,             // 确切期望收到的 ETH 数量
        uint amountInMax,           // 愿意支付的输入 token 最大数量（滑点保护）
        address[] calldata path,    // 交易路径，path[0] 为输入 token，path[最后] 必须是 WETH
        address to,                 // ETH 的接收地址
        uint deadline               // 交易截止时间戳，超时则 revert
    )
        external
        virtual
        override
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        // 路径最后一个必须是 WETH
        require(path[path.length - 1] == WETH, 'UniswapV2Router: INVALID_PATH');
        amounts = UniswapV2Library.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= amountInMax, 'UniswapV2Router: EXCESSIVE_INPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]
        );
        // swap 输出先到 Router，再由 Router 解包 WETH 并转 ETH 给用户
        _swap(amounts, path, address(this));
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }

    // 精确 token 换 ETH：指定确切的输入 token 量，要求 ETH 输出不低于 amountOutMin
    function swapExactTokensForETH(
        uint amountIn,              // 确切的输入 token 数量
        uint amountOutMin,          // 期望收到的 ETH 最小数量（滑点保护）
        address[] calldata path,    // 交易路径，path[0] 为输入 token，path[最后] 必须是 WETH
        address to,                 // ETH 的接收地址
        uint deadline               // 交易截止时间戳，超时则 revert
    )
        external
        virtual
        override
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[path.length - 1] == WETH, 'UniswapV2Router: INVALID_PATH');
        amounts = UniswapV2Library.getAmountsOut(factory, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, address(this));
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }

    // ETH 换精确 token：指定确切的 token 输出量，多余的 ETH 退还
    function swapETHForExactTokens(
        uint amountOut,             // 确切期望收到的输出 token 数量
        address[] calldata path,    // 交易路径，path[0] 必须是 WETH，path[最后] 为目标 token
        address to,                 // 输出 token 的接收地址
        uint deadline               // 交易截止时间戳，超时则 revert
    )
        external
        virtual
        override
        payable
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[0] == WETH, 'UniswapV2Router: INVALID_PATH');
        // 反向推算需要的 ETH 数量
        amounts = UniswapV2Library.getAmountsIn(factory, amountOut, path);
        // 用户发送的 ETH 必须足够
        require(amounts[0] <= msg.value, 'UniswapV2Router: EXCESSIVE_INPUT_AMOUNT');
        IWETH(WETH).deposit{value: amounts[0]}();
        assert(IWETH(WETH).transfer(UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]));
        _swap(amounts, path, to);
        // 退还多余的 ETH
        if (msg.value > amounts[0]) TransferHelper.safeTransferETH(msg.sender, msg.value - amounts[0]);
    }

    // **** SWAP (supporting fee-on-transfer tokens) ****
    // requires the initial amount to have already been sent to the first pair

    // 支持通缩 token 的内部 swap
    // 与 _swap 的区别：不依赖预算数组，而是每跳实时查余额算输出，适配转账扣费导致到账量不确定的情况
    function _swapSupportingFeeOnTransferTokens(
        address[] memory path,  // 交易路径
        address _to             // 最终输出 token 的接收地址
    ) internal virtual {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = UniswapV2Library.sortTokens(input, output);
            IUniswapV2Pair pair = IUniswapV2Pair(UniswapV2Library.pairFor(factory, input, output));
            uint amountInput;
            uint amountOutput;
            { // 用块作用域避免栈变量过多导致 stack too deep 编译错误
            (uint reserve0, uint reserve1,) = pair.getReserves();
            (uint reserveInput, uint reserveOutput) = input == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
            // 实际到账量 = pair 当前余额 - 记录的储备量（差值即为本次实际转入的量，已扣除通缩费）
            amountInput = IERC20(input).balanceOf(address(pair)).sub(reserveInput);
            // 根据实际到账量计算输出
            amountOutput = UniswapV2Library.getAmountOut(amountInput, reserveInput, reserveOutput);
            }
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOutput) : (amountOutput, uint(0));
            address to = i < path.length - 2 ? UniswapV2Library.pairFor(factory, output, path[i + 2]) : _to;
            pair.swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }

    // 支持通缩 token 的精确输入 token 换 token
    // 无法预知实际输出量，改为用余额差校验最终到账
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,              // 确切的输入 token 数量
        uint amountOutMin,          // 期望收到的输出 token 最小数量（滑点保护，用余额差校验）
        address[] calldata path,    // 交易路径，path[0] 为输入 token，path[最后] 为输出 token
        address to,                 // 输出 token 的接收地址
        uint deadline               // 交易截止时间戳，超时则 revert
    ) external virtual override ensure(deadline) {
        // 先转入输入 token（后续每跳查余额差，需要先把 token 打进去）
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, UniswapV2Library.pairFor(factory, path[0], path[1]), amountIn
        );
        // 记录 swap 前目标 token 的余额，用于最后校验实际到账量
        uint balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(path, to);
        // 实际到账量 = swap 后余额 - swap 前余额，不得低于 amountOutMin
        require(
            IERC20(path[path.length - 1]).balanceOf(to).sub(balanceBefore) >= amountOutMin,
            'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT'
        );
    }

    // 支持通缩 token 的精确 ETH 换 token
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,          // 期望收到的输出 token 最小数量（滑点保护，用余额差校验）
        address[] calldata path,    // 交易路径，path[0] 必须是 WETH，path[最后] 为目标 token
        address to,                 // 输出 token 的接收地址
        uint deadline               // 交易截止时间戳，超时则 revert
    )
        external
        virtual
        override
        payable
        ensure(deadline)
    {
        require(path[0] == WETH, 'UniswapV2Router: INVALID_PATH');
        uint amountIn = msg.value;
        // 将 ETH 包装成 WETH 并转入第一个 pair
        IWETH(WETH).deposit{value: amountIn}();
        assert(IWETH(WETH).transfer(UniswapV2Library.pairFor(factory, path[0], path[1]), amountIn));
        uint balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(path, to);
        require(
            IERC20(path[path.length - 1]).balanceOf(to).sub(balanceBefore) >= amountOutMin,
            'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT'
        );
    }

    // 支持通缩 token 的精确 token 换 ETH
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,              // 确切的输入 token 数量
        uint amountOutMin,          // 期望收到的 ETH 最小数量（滑点保护）
        address[] calldata path,    // 交易路径，path[0] 为输入 token，path[最后] 必须是 WETH
        address to,                 // ETH 的接收地址
        uint deadline               // 交易截止时间戳，超时则 revert
    )
        external
        virtual
        override
        ensure(deadline)
    {
        require(path[path.length - 1] == WETH, 'UniswapV2Router: INVALID_PATH');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, UniswapV2Library.pairFor(factory, path[0], path[1]), amountIn
        );
        // swap 输出先到 Router
        _swapSupportingFeeOnTransferTokens(path, address(this));
        // 查询 Router 实际收到的 WETH 余额（通缩 token 导致到账不确定，用余额而非返回值）
        uint amountOut = IERC20(WETH).balanceOf(address(this));
        require(amountOut >= amountOutMin, 'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT');
        IWETH(WETH).withdraw(amountOut);
        TransferHelper.safeTransferETH(to, amountOut);
    }

    // **** LIBRARY FUNCTIONS ****
    // 以下为对 UniswapV2Library 的透传封装，方便外部合约直接通过 Router 查询报价

    // 按储备量比例计算等价数量（不含手续费，用于添加流动性时的比例对齐）
    function quote(
        uint amountA,    // 已知的 tokenA 数量
        uint reserveA,   // 池子中 tokenA 的当前储备量
        uint reserveB    // 池子中 tokenB 的当前储备量
    ) public pure virtual override returns (uint amountB) {
        return UniswapV2Library.quote(amountA, reserveA, reserveB);
    }

    // 给定输入量，计算扣除 0.3% 手续费后的输出量
    function getAmountOut(
        uint amountIn,    // 输入 token 的数量
        uint reserveIn,   // 池子中输入 token 的当前储备量
        uint reserveOut   // 池子中输出 token 的当前储备量
    )
        public
        pure
        virtual
        override
        returns (uint amountOut)
    {
        return UniswapV2Library.getAmountOut(amountIn, reserveIn, reserveOut);
    }

    // 给定期望输出量，计算需要投入的输入量（含手续费）
    function getAmountIn(
        uint amountOut,   // 期望获得的输出 token 数量
        uint reserveIn,   // 池子中输入 token 的当前储备量
        uint reserveOut   // 池子中输出 token 的当前储备量
    )
        public
        pure
        virtual
        override
        returns (uint amountIn)
    {
        return UniswapV2Library.getAmountIn(amountOut, reserveIn, reserveOut);
    }

    // 按路径正向推算每一跳的输出量（用于 swapExact 系列）
    function getAmountsOut(
        uint amountIn,          // 输入 token 的起始数量
        address[] memory path   // 交易路径，返回数组长度与 path 相同
    )
        public
        view
        virtual
        override
        returns (uint[] memory amounts)
    {
        return UniswapV2Library.getAmountsOut(factory, amountIn, path);
    }

    // 按路径反向推算每一跳的输入量（用于 swapForExact 系列）
    function getAmountsIn(
        uint amountOut,         // 期望最终获得的输出 token 数量
        address[] memory path   // 交易路径，返回数组长度与 path 相同
    )
        public
        view
        virtual
        override
        returns (uint[] memory amounts)
    {
        return UniswapV2Library.getAmountsIn(factory, amountOut, path);
    }
}
