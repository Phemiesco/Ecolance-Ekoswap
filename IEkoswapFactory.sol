//SPDX-License-Identifier: MIT
pragma solidity >=0.8.5;


interface IEkoswapFactory{
event PairCreated(address indexed tokenA, address indexed tokenB, address pair, uint256);

function getPair(address tokenA, address tokenB) external view returns (address);
function allPairsLength() external view returns (uint);
function createPair(address tokenA, address tokenB) external view returns (address pair);
function setFeeTo(address _feeTo) external;
function setFeeToSetter(address _feeToSetter) external;


}
