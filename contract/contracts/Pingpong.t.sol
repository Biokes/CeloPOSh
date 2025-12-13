// // SPDX-License-Identifier: UNLICENSED
// pragma solidity ^0.8.28;

// import {Test} from "forge-std/Test.sol";
// import {PingPong} from "./PingPong.sol";
// import {console} from "forge-std/console.sol";

// contract PingpongTest is Test{
//     PingPong pong;
//     address deployer = address(1);
//     function setUp() public {
//         pong = new PingPong();
//     }

//     function testGameCanBeCreated() public{
//         // address user = address(2);
//         // vm.startPrank(user);
//         pong.createNewGame(0);
//         assert(pong.getUserGames(user).length==1);
//     }
//     function testOtherPlayersCanJoinGame(){
//         address player1 = address(2);
//         address player2 = address(3);
//         vm.prank(player1);
//         pong.createNewGame(0);
//         vm.prank(player2);

//     }
// }