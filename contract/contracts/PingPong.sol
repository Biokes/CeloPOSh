// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

contract PingPong{

    mapping (address => Game[]) games;

    enum GameStatus{
        DEFAULT,
        ACTIVE,
        ENDED,
        CANCELLED,
        PAID,
        PENDING
    }
    

    struct Game{
        GameStatus status;
        uint price;
        address creator;
    }
    
    function createNewGame(uint _price) external {
        Game memory game = Game({
            status: GameStatus.PENDING,
            price: _price,
            creator: msg.sender
        });
        games[msg.sender].push(game);
    }

    function getUserGames(address user) external returns(Game[]) {
        return games[user];
    }
    
}