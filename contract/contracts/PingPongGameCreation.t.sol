// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "./PingPong.sol";

contract PingPongGameCreationTest is Test {
    PingPong pong;
    address alice = address(0xA1);
    address bob = address(0xB2);
    uint256 constant STAKE = 1 ether;

    function setUp() public {
        pong = new PingPong();
        vm.deal(alice, 10 ether);
        vm.deal(bob, 10 ether);
    }

    function testCreateGameEmitsEvent() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
    }

    function testCreateGameIncrementsCounter() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        assertEq(pong.getTotalGames(), 1);
    }

    function testCreateGameSetsPlayer1() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        PingPong.GameSession memory game = pong.getGame(1);
        assertEq(game.player1, alice);
    }

    function testCreateGameSetsWaitingStatus() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        assertEq(pong.getGameStatus(1), 1);
    }

    function testCreateGameEscrowBalanceCorrect() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        assertEq(pong.getGameEscrow(1), STAKE);
    }

    function testCreateGameMarksAsExists() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        assertTrue(pong.isGameExists(1));
    }

    function testCreateGameTracksPlayerHistory() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        uint64[] memory games = pong.getPlayerGames(alice);
        assertEq(games.length, 1);
        assertEq(games[0], 1);
    }

    function testCreateGameZeroValueFails() public {
        vm.prank(alice);
        vm.expectRevert(PingPong.InvalidAmount.selector);
        pong.createGame{value: 0}();
    }

    function testCreateGameWhenPausedFails() public {
        pong.togglePause();
        vm.prank(alice);
        vm.expectRevert(PingPong.GameplayPaused.selector);
        pong.createGame{value: STAKE}();
    }

    function testCreateMultipleGamesSuccessfully() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        vm.prank(bob);
        pong.createGame{value: STAKE}();
        
        assertEq(pong.getTotalGames(), 2);
        assertTrue(pong.isGameExists(1));
        assertTrue(pong.isGameExists(2));
    }

    function testCreateGameWithDifferentStakes() public {
        vm.prank(alice);
        pong.createGame{value: 2 ether}();
        
        PingPong.GameSession memory game = pong.getGame(1);
        assertEq(game.stakeAmount, 2 ether);
    }
}
