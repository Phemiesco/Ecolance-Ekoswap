//SPDX-License-Identifier: MIT
pragma solidity >=0.8.5;

interface IMaths {

    function min(uint x, uint y) external pure returns (uint z);
    
    function sqrt(uint y) external pure returns (uint z);
}
