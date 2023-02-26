//SPDX-License-Identifier: MIT
pragma solidity >=0.8.5;

import"./IEkoswapPair.sol";
import"./IEkoswapFactory.sol";
import"./EkoswapPair.sol";
import"./EkoswapFactory.sol";



library EkoswapLibrary {
    error InsufficientAmount();
    error InsufficientLiquidity();
    error IdenticalAddresses();
    error ZeroAddress();


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
}
