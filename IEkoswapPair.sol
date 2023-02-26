//SPDX-License-Identifier: MIT
pragma solidity >=0.8.5;


interface IEkoswapPair{

    event burn(address indexed sender, uint256 amountA, uint256 amountB);
    event mint(address indexed sender, uint256 amountA, uint256 amountB);


    event Sync(uint256 reserveA, uint256 reserveB);
    function initialize(address, address) external;
    function _safeTransfer(address, address, uint256 value) external;
    function swap(uint256 amount0Out, uint256 amount1Out, address to) external;
}
