//SPDX-License-Identifier: MIT
pragma solidity >=0.8.5;

import"./Maths.sol";
import"./IERC20.sol";
import"./UQ112x112.sol";
import"./EkoswapERC20.sol";
import"./EkoswapFactory.sol";

    
    error TransferFailed();
    error InvalidAddress();
    error BalanceOverflow();
    error AlreadyInitialized(); 
    error InsufficientLiquidity();
    error InvalidConstantProduct();
    error InsufficientInputAmount();
    error InsufficientLiquidityBurned();
    error InsufficientLiquidityProvided();


contract EkoswapPair is EkoswapERC20 {

    using UQ112x112 for uint224;


    uint256 constant MinLiquidity = 1000;


    address public factory;
    address public token0;
    address public token1;
   

    uint112 private reserve0;
    uint112 private reserve1;
    uint32 private blockTimestampLast;

    uint256 public price0CummulativesLast;
    uint256 public price1CummulativesLast;
    uint ConstProd;                            // product of the reserves after most recent liquidity event

    bool private Reentrancy;

    modifier nonReentrant() {

        require(!Reentrancy);
        Reentrancy = true;
    
        _;

        Reentrancy = false;

    }

    event Sync(uint256 reserve0, uint256 reserve1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1);
    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Swap(address indexed sender, uint amount0In, uint amount1In, uint amount0Out, uint amount1Out, address indexed to );
    

    constructor () public {
        factory = msg.sender;
    }

    function initialize(address _token0, address _token1) external {
        if(msg.sender != factory && token0 != address(0) || token1 != address(0)) revert AlreadyInitialized();
        token0 = _token0;
        token1 = _token1;
    }


    function _safeTransfer(address token, address to, uint256 value) private {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSignature("transfer(address,uint256)", to, value));
        if (!success || (data.length != 0 && !abi.decode(data, (bool)))) revert TransferFailed();
    }

    //function that mint the liquidity token to the pool 
    function mint(address to) external nonReentrant returns (uint256 liquidity) {
        (uint112 _reserve0, uint112 _reserve1,) = getReserves();
        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));

        uint256 amount0 = balance0 - _reserve0;
        uint256 amount1 = balance1 - _reserve1;
        uint _totalSupply = totalSupply; 

        if (totalSupply == 0) {
            liquidity = Math.sqrt(amount0 * amount1) - MinLiquidity; 
            _mint(address(0), MinLiquidity);

        } else {
            liquidity = Math.min((amount0 * _totalSupply) / _reserve0, (amount1 * _totalSupply) / _reserve1);
        }
        if (liquidity <= 0) revert InsufficientLiquidityProvided();
        _mint(msg.sender, liquidity); 

        _update(balance0, balance1, reserve0, reserve1);
        emit Mint(to, amount0, amount1);

        _update(balance0, balance1, _reserve0, _reserve1);
        ConstProd = uint(reserve0 * reserve1); // reserve0 and reserve1 are up-to-date
    }

    function burn(address to) external nonReentrant returns (uint Amount0, uint Amount1){
        (uint112 _reserve0, uint112 _reserve1,) = getReserves();
    
        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));
        uint256 liquidity = balanceOf[address(this)];


        uint _totalSupply = totalSupply;
        
        uint256 amount0 = (liquidity * balance0) / _totalSupply;
        uint256 amount1 = (liquidity * balance1) / _totalSupply;

        if (amount0 <= 0 || amount1 <= 0) revert InsufficientLiquidityBurned();

        _burn(address(this), liquidity);

        _safeTransfer(token0, to, amount0);
        _safeTransfer(token1, to, amount1);

        balance0 = IERC20(token0).balanceOf(address(this));
        balance1 = IERC20(token1).balanceOf(address(this));
        _update(balance0, balance1, reserve0, reserve1);

       _update(balance0, balance1, _reserve0, _reserve1);
        ConstProd = uint(reserve0 * reserve1); 
        emit Burn(msg.sender, amount0, amount1);
    }

    function swap(uint256 amount0Out, uint256 amount1Out, address to) external nonReentrant{
            (uint112 _reserve0, uint112 _reserve1, ) = getReserves();
        if (amount0Out > _reserve0 || amount1Out > _reserve1) revert InsufficientLiquidity();

        uint256 balance0;
        uint256 balance1;
        { // scope for _token{0,1}, avoids stack too deep errors
        address _token0 = token0;
        address _token1 = token1;

        if (to == _token0 && to == _token1) revert InvalidAddress();
        balance0 = IERC20(_token0).balanceOf(address(this));
        balance1 = IERC20(_token1).balanceOf(address(this));
        }
        uint256 amount0In = balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0;
        uint256 amount1In = balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0;
        if (amount0In == 0 && amount1In == 0) revert InsufficientInputAmount();

        { // scope for reserve{0,1}Adjusted, avoids stack too deep errors
        uint256 balance0Adjusted = (balance0 * 1000) - (amount0In * 3);
        uint256 balance1Adjusted = (balance1 * 1000) - (amount1In * 3);
        if ((balance0Adjusted * balance1Adjusted) < uint(_reserve0) * (_reserve1) * (1000**2)) revert InvalidConstantProduct();
        }

        if (amount0Out > 0) _safeTransfer(token0, to, amount0Out);
        if (amount1Out > 0) _safeTransfer(token1, to, amount1Out);
         _update(balance0, balance1, _reserve0, _reserve1);
         
    emit Swap(msg.sender, amount0In, amount0Out, amount1In, amount1Out, to);
    }

    function getReserves() public view returns (uint112 _reserve0, uint112 _reserve1, uint32  _blockTimestampLast) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }

    function _update( uint256 balance0, uint256 balance1, uint112 _reserve0, uint112 _reserve1) private{
         if (balance0 > type(uint112).max || balance1 > type(uint112).max) revert BalanceOverflow();
    unchecked {uint32 timeElapsed = uint32(block.timestamp) - blockTimestampLast;

    if (timeElapsed > 0 && _reserve0 > 0 && _reserve1 > 0) {
        price0CummulativesLast += uint256(UQ112x112.encode(_reserve0).uqdiv(_reserve0)) * timeElapsed;
        price1CummulativesLast += uint256(UQ112x112.encode(_reserve1).uqdiv(_reserve1)) * timeElapsed;
        }
    }
    reserve0 = uint112(balance0);
    reserve1 = uint112(balance1);
    blockTimestampLast = uint32(block.timestamp);
    emit Sync(reserve0, reserve1);
    }

    function sync() external nonReentrant { 
        _update(IERC20(token0).balanceOf(address(this)), IERC20(token1).balanceOf(address(this)), reserve0, reserve1);

        emit Sync(reserve0, reserve1);
    }
}
