// SPDX-License-Identifier: GPL-3.0
// author: kaiju3d.com

pragma solidity ^0.8.9;

import "./DateTime.sol";
import "./interfaces/IKaiju2048GameNFT.sol";
import "./interfaces/IChainsAtlas.sol";

contract KaijuGameFactory {
    DateTime dateTime;
    IKaiju2048GameNFT kaiju2048GameNFT;
    address public owner;
    uint256 private seed;
    address byteCodeExecutorAddress;
    bool isValid = false;
    uint constant public SINGAPORE_TIME_DIFF = 28800;

    struct gameObject {
        address player;
        string gameId;
        uint256 score;
        uint timestamp;
    }

    mapping(address => uint256) public playerPersonalBest;
    mapping(bytes => bytes) public leaderBoardByDate;
    mapping(string => uint256) public gameIdToRandom;

    event GetRandomNumber(string indexed _gameId, uint256 _randomNumber);
    event Verify2048Game(string indexed _gameId, bool _isValid, uint256 _FEScore, uint256 _contractScore);

    constructor(address _dateTimeContract, address _byteCodeExecutorAddress, address _gameNFTContract) {
        owner = msg.sender;
        dateTime = DateTime(_dateTimeContract);
        kaiju2048GameNFT = IKaiju2048GameNFT(_gameNFTContract);
        byteCodeExecutorAddress = _byteCodeExecutorAddress;
        seed = block.timestamp;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Only the contract owner can call this function.");
        _;
    }

    function setGameContractAddress(address _byteCodeExecutorAddress) public onlyOwner {
        byteCodeExecutorAddress = _byteCodeExecutorAddress;
    }

    function getRandomNumber(string memory gameId) public returns(uint256){
        seed = uint256(keccak256(abi.encodePacked(seed, blockhash(block.number - 1))));
        uint256 randomNumber = seed % 1000000;
        gameIdToRandom[gameId] = randomNumber;
        emit GetRandomNumber(gameId, randomNumber);
        return randomNumber;
    }

    function verify2048game(string memory _gameId,uint256 _FEScore,bytes memory _gameData, string memory _cid) public returns(string memory, bool){
        
        IChainsAtlas executor = IChainsAtlas(byteCodeExecutorAddress);
        address newContractAddress = executor.runBytecode(_gameData);
        bytes memory userScore = executor.getRuntimeReturn(newContractAddress);
        address player = msg.sender;
        uint256 contractScore = uint256(bytes32(userScore));
        uint timestamp = block.timestamp + SINGAPORE_TIME_DIFF;
        gameObject memory game = gameObject(player, _gameId, _FEScore, timestamp); // change after Finalized executor (_FEScore ==> contractScore)
        bool isGameValid = false;

        if(_FEScore==contractScore){
            isGameValid = true;
            addToLeaderBoard(game, timestamp);
            kaiju2048GameNFT.safeMint(player, _cid);        
        }

        delete gameIdToRandom[_gameId];
        emit Verify2048Game(_gameId, isGameValid, _FEScore, contractScore);
        return (_gameId,isGameValid);
    }

    function addToLeaderBoard(gameObject memory game, uint currentTimestamp) public {
        if (playerPersonalBest[game.player] < game.score){
            playerPersonalBest[game.player] = game.score;
        }
        (uint16 todayYear, uint8 todayMonth, uint8 todayDate) = getYearMonthDate(currentTimestamp);
        bytes memory date = abi.encode(todayYear,todayMonth,todayDate);
        bytes memory lb = leaderBoardByDate[date];
        gameObject[] memory board;
        if (lb.length > 0){
            gameObject[] memory board_ = abi.decode(lb,(gameObject[]));
            board = new gameObject[](board_.length);
            for (uint256 i = 0; i < board_.length; i++) {
                board[i] = board_[i];
            }
        } else {
            board = new gameObject[](0);
        }
        uint n = board.length;
        if (n < 10){
            gameObject[] memory newBoard = new gameObject[](n + 1);
            for (uint256 i = 0; i < n; i++) {
                newBoard[i] = board[i];
            }
            newBoard[n] = game;
            board = newBoard;
        } else if (board[0].score < game.score){
            board[0] = game;
        }
        board = sortArray(board);
        setDailyLeaderBoard(todayYear,todayMonth,todayDate,board);
    }

    function getYearMonthDate(uint _timestamp) public view returns(uint16, uint8, uint8){
        uint16 year = dateTime.getYear(_timestamp);
        uint8 month = dateTime.getMonth(_timestamp);
        uint8 date = dateTime.getDay(_timestamp);
        return (year, month, date);
    }

    function sortArray(gameObject[] memory array) internal pure returns(gameObject[] memory){
        uint n = array.length;
        for (uint256 i = 0; i < n - 1; i++) {
            for (uint256 j = 0; j < n - i - 1; j++) {
                if (array[j].score > array[j + 1].score) {
                    gameObject memory temp = array[j];
                    array[j] = array[j + 1];
                    array[j + 1] = temp;
                }
            }
        }
        return array;
    }

    function getDailyWinner() public view returns (gameObject memory){
        gameObject[] memory lb = getLeaderBoard();
        uint n = lb.length;
        gameObject memory winner = lb[n-1];
        return winner;
    }

    function getLeaderBoard() public view returns (gameObject[] memory){
        uint timestamp = block.timestamp + SINGAPORE_TIME_DIFF;
        (uint16 todayYear, uint8 todayMonth, uint8 todayDate) = getYearMonthDate(timestamp);
        gameObject[] memory lb = getLeaderBoardByDate(todayYear, todayMonth, todayDate);
        return lb;
    }

    function getPersonalBest(address player) public view returns(uint){
        return playerPersonalBest[player];
    }

    function setDailyLeaderBoard(uint16 year, uint8 month, uint8 day, gameObject[] memory values) internal {
        bytes memory date = abi.encode(year,month,day);
        bytes memory lb = abi.encode(values);
        leaderBoardByDate[date] = lb;
    }

    function getLeaderBoardByDate(uint16 year, uint8 month, uint8 day) public view returns (gameObject[] memory){
        bytes memory date = abi.encode(year,month,day);
        bytes memory lb = leaderBoardByDate[date];
        require(lb.length > 0, "Leaderboard not found for the specified date");
        gameObject[] memory board = abi.decode(lb,(gameObject[]));
        return board;
    }
}