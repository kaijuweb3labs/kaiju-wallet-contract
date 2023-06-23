// SPDX-License-Identifier: GPL-3.0
// author: kaiju3d.com

pragma solidity ^0.8.9;

contract Game2048 {
    mapping(string => string) public gameIDtoMoves;
    function verify2048(string memory gameId, string memory moves, uint256 FEScore, uint256 randomNumber) public returns(bytes memory){
        (randomNumber);
        gameIDtoMoves[gameId] = moves;
        uint256 contractScore = FEScore;
        bool isValid = true;
        return (abi.encode(gameId, isValid, contractScore));
    }
}