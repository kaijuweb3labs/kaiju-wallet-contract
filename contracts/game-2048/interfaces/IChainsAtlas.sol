// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

interface IChainsAtlas {
    function runBytecode(bytes memory bytecode) external returns (address);
    function getRuntimeReturn(address _contract) external view returns (bytes memory);
}