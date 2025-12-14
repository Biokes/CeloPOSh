// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "./PingPong.sol";

contract PingPongGameJoinTest is Test {
    PingPong pong;
    address alice = address(0xA1);
    address bob = address(0xB2);
    address carol = address(0xC3);
    uint256 constant STAKE = 1 ether;

    function setUp() public {
        pong = new PingPong();
        vm.deal(alice, 10 ether);
        vm.deal(bob, 10 ether);
        vm.deal(carol, 10 ether);
    }

    function testJoinGameChangesStatus() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        vm.prank(bob);
        pong.joinGame{value: STAKE}(1);
        
        assertEq(pong.getGameStatus(1), 2);
    }

    function testJoinGameDoublesEscrow() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        vm.prank(bob);
        pong.joinGame{value: STAKE}(1);
        
        assertEq(pong.getGameEscrow(1), STAKE * 2);
    }

    function testJoinGameSetsPlayer2() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        vm.prank(bob);
        pong.joinGame{value: STAKE}(1);
        
        PingPong.GameSession memory game = pong.getGame(1);
        assertEq(game.player2, bob);
    }

    function testJoinGameAddsToPlayerHistory() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        vm.prank(bob);
        pong.joinGame{value: STAKE}(1);
        
        uint64[] memory games = pong.getPlayerGames(bob);
        assertEq(games.length, 1);
    }

    function testJoinGameWrongAmountFails() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        vm.prank(bob);
        vm.expectRevert(PingPong.InvalidAmount.selector);
        pong.joinGame{value: 0.5 ether}(1);
    }

    function testJoinOwnGameFails() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        vm.prank(alice);
        vm.expectRevert(PingPong.CannotJoinOwnGame.selector);
        pong.joinGame{value: STAKE}(1);
    }

    function testJoinNonExistentGameFails() public {
        vm.prank(bob);
        vm.expectRevert(PingPong.GameNotFound.selector);
        pong.joinGame{value: STAKE}(999);
    }

    function testJoinWhenPausedFails() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        pong.togglePause();
        
        vm.prank(bob);
        vm.expectRevert(PingPong.GameplayPaused.selector);
        pong.joinGame{value: STAKE}(1);
    }

    function testCannotJoinActiveGameTwice() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        vm.prank(bob);
        pong.joinGame{value: STAKE}(1);
        
        vm.prank(carol);
        vm.expectRevert(PingPong.Player2SlotNotEmpty.selector);
        pong.joinGame{value: STAKE}(1);
    }

    function testJoinWithMoreThanRequiredFails() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        vm.prank(bob);
        vm.expectRevert(PingPong.InvalidAmount.selector);
        pong.joinGame{value: 2 ether}(1);
    }
}
