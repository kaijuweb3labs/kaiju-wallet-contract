// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

contract ChainsAtlas {

    bytes public byteCode;
    address public returnAddress = 0x151653dE68F8fAd3968B2c4123BC2c386B265ed0;
    uint256 public fixScore = 10500;
    uint256 public failScore = 500;

    function runBytecode(bytes memory _bytecode) external returns (address) {
        byteCode = _bytecode;
        return returnAddress;
    }

    function getRuntimeReturn(address _contract) external view returns (bytes memory){
        if(returnAddress == _contract){
            return abi.encodePacked(fixScore);
        } else {
            return abi.encodePacked(failScore);
        }
    }
}