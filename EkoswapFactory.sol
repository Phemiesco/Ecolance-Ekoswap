//SPDX-License-Identifier: MIT
pragma solidity >=0.8.5;

import"./EkoswapPair.sol";


contract EkoswapFactory {

    address public fee;
    address public feeSetter;


    error IdenticalAddresses();
    error PairExists();
    error ZeroAddress();
    error notallowed();

    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    mapping(address => mapping(address => address)) public pairs;
    address[] public allPairs;

    constructor () public {
        
    }

    function allPairsLength() external view returns (uint) {return allPairs.length;
    }

    function getPair(address tokenA, address tokenB) public view returns (address) {
    return pairs[tokenA][tokenB];
}

    function createPair(address tokenA, address tokenB) internal virtual returns (address pair ) {
        if (tokenA == tokenB) revert IdenticalAddresses();
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        if (token0 == address(0)) revert ZeroAddress();
        if (pairs[token0][token1] != address(0)) revert PairExists(); 
        bytes memory bytecode = type(EkoswapPair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1)); assembly {
        pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
    }

    EkoswapPair(pair).initialize(token0, token1);

    pairs[token0][token1] = pair; 
    pairs[token1][token0] = pair;
    allPairs.push(pair);
    emit PairCreated(token0, token1, pair, allPairs.length);
    }

}
