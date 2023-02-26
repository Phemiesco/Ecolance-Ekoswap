//SPDX-License-Identifier: MIT
pragma solidity >=0.8.5;

import"./IEkoswapPair.sol";
import"./IEkoswapFactory.sol";
import"./EkoswapPair.sol";
import"./EkoswapFactory.sol";



library EkoswapLibrary {
    error InsufficientAmount();
    error InsufficientLiquidity();
    error InsufficientOutputAmount();
    error InsufficientInputAmount();
    error IdenticalAddresses();
    error ZeroAddress();
    error InvalidPath();


    function sortTokens(address tokenA, address tokenB) internal pure returns(address token0, address token1){
        if(tokenA == tokenB) revert IdenticalAddresses();
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        if (token0 == address(0)) revert ZeroAddress();

    }

    function getReserves(address factoryAddress, address tokenA, address tokenB) public view returns (uint256 reserveA, uint256 reserveB) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1, ) = EkoswapPair(pairFor(factoryAddress, token0, token1)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1): (reserve1, reserve0);
    }

    function pairFor(address factoryAddress, address tokenA, address tokenB) internal view returns (address pairAddress) {
        EkoswapFactory(factoryAddress).pairs(address(tokenA), address(tokenB));
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pairAddress = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            factoryAddress,
                            keccak256(abi.encodePacked(token0, token1)),
                            keccak256(type(EkoswapPair).creationCode)
                        )
                    )
                )
            )
        );
    }

    function quote(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) public pure returns (uint256 amountOut) {
        if (amountIn == 0) revert InsufficientAmount();
        if (reserveIn == 0 || reserveOut == 0) revert InsufficientLiquidity();

    return (amountIn * reserveOut) / reserveIn;
    }

     // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        if (amountIn < 0) revert InsufficientInputAmount();
        if (reserveIn < 0 && reserveOut < 0) revert InsufficientLiquidity();
        uint amountInWithFee = (amountIn * 997);
        uint numerator = (amountInWithFee * reserveOut);
        uint denominator = (reserveIn * 1000) + (amountInWithFee);
        amountOut = numerator / denominator;
    }
     // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        if(amountOut < 0) revert InsufficientOutputAmount();
        if(reserveIn < 0 && reserveOut < 0) revert InsufficientLiquidity();
        uint numerator = (reserveIn * amountOut *1000);
        uint denominator = (reserveOut - (amountOut * 997));
        amountIn = (numerator / denominator) + (1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        if(path.length < 2) revert InvalidPath();
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}
