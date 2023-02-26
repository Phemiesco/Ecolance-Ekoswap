//SPDX-License-Identifier: MIT
pragma solidity >=0.8.5;



import"./IEkoswapFactory.sol";
import"./EkoswapFactory.sol";
import"./EkoswapLibrary.sol";
import"./IEkoswapPair.sol";
import"./EkoswapERC20.sol";
import"./IERC20.sol";


contract EkoswapRouter {
    error InsufficientAAmount();
    error InsufficientBAmount();
    error SafeTransferFailed();
    error InsufficientAmount();
    error InsufficientOutputAmount();
    error InsufficientLiquidity();
    error TransferFailed();

    
    IEkoswapFactory factory;

    constructor(address factoryAddress) {
        factory = IEkoswapFactory(factoryAddress);
    }


    function TransferFrom(address token, address from, address to, uint256 value) private {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSignature("transfer(address,uint256)",from, to, value));
        if (!success || (data.length != 0 && !abi.decode(data, (bool))))
            revert TransferFailed();
    }
    
    function addLiquidity(

        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to
        ) internal virtual returns (uint256 amountA, uint256 amountB, uint256 liquidity){

       if (IEkoswapFactory(factory).getPair(tokenA, tokenB) == address(0)) {
            factory.createPair(tokenA, tokenB);
        }

    
        (amountA, amountB) = _calculateLiquidity(
        tokenA,
        tokenB,
        amountADesired,
        amountBDesired,
        amountAMin,
        amountBMin
        );
        address pairAddress = EkoswapLibrary.pairFor(address(factory), tokenA, tokenB);
        
        TransferFrom(tokenA, msg.sender, pairAddress, amountA);
        TransferFrom(tokenB, msg.sender, pairAddress, amountB);
        liquidity = EkoswapPair(pairAddress).mint(to);
    }

    function _calculateLiquidity(    
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin
        ) internal returns (uint256 amountA, uint256 amountB) {
            (uint256 reserveA, uint256 reserveB) = EkoswapLibrary.getReserves(address(factory), tokenA,tokenB);
            if (reserveA == 0 && reserveB == 0) {
                (amountA, amountB) = (amountADesired, amountBDesired);
                }else {
                    uint256 amountBOptimal = EkoswapLibrary.quote(amountADesired,reserveA,reserveB);
                    if (amountBOptimal <= amountBDesired) {
                    if (amountBOptimal <= amountBMin) revert InsufficientBAmount();
                    (amountA, amountB) = (amountADesired, amountBOptimal);
                    } 
                    else {
                        uint256 amountAOptimal = EkoswapLibrary.quote(amountBDesired, reserveB, reserveA );
                        assert(amountAOptimal <= amountADesired);
                        if (amountAOptimal <= amountAMin) revert InsufficientAAmount();
                        (amountA, amountB) = (amountAOptimal, amountBDesired);
                    }
                }
    }

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to
        ) public returns (uint256 amountA, uint256 amountB) {address pair = EkoswapLibrary.pairFor(
            address(factory), tokenA, tokenB);
            EkoswapPair(pair).transferFrom(msg.sender, pair, liquidity);
            (amountA, amountB) = EkoswapPair(pair).burn(to);

            if (amountA < amountAMin) revert InsufficientAAmount();
            if (amountB < amountBMin) revert InsufficientBAmount();
    }

    
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
        ) public pure returns (uint256) {
            if (amountIn == 0) revert InsufficientAmount();
            if (reserveIn == 0 || reserveOut == 0) revert InsufficientLiquidity();

            uint256 amountInWithFee = amountIn * 997;
            uint256 numerator = amountInWithFee * reserveOut;
            uint256 denominator = (reserveIn * 1000) + amountInWithFee;
            return numerator / denominator;
    }

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to
        ) public returns (uint256[] memory amounts) {
            amounts = EkoswapLibrary.getAmountsOut(
                address(factory), amountIn, path);
                if (amounts[amounts.length - 1] < amountOutMin) revert InsufficientOutputAmount();

                TransferFrom( path[0], msg.sender,
                EkoswapLibrary.pairFor(address(factory), path[0], path[1]), amounts[0]);
                _swap(amounts, path, to);

    }

    function _swap(uint256[] memory amounts, address[] memory path, address to_ ) internal {
        for (uint256 i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0, ) = EkoswapLibrary.sortTokens(input, output);

            uint256 amountOut = amounts[i + 1];
            (uint256 amount0Out, uint256 amount1Out) = input == token0? (uint256(0), amountOut): (amountOut, uint256(0));

            address to = i < path.length - 2 ? EkoswapLibrary.pairFor(
            address(factory), output, path[i + 2]): to_;
            IEkoswapPair(EkoswapLibrary.pairFor(address(factory), input, output)).swap(amount0Out, amount1Out, to);
        }
    }
}
