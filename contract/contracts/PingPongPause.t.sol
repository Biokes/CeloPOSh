// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "./PingPong.sol";

contract PingPongPauseTest is Test {
    PingPong pong;
    address alice = address(0xA1);
    address bob = address(0xB2);
    uint256 constant STAKE = 1 ether;

    function setUp() public {
        pong = new PingPong();
        vm.deal(alice, 10 ether);
        vm.deal(bob, 10 ether);
    }

    function testTogglePausePausesGameplay() public {
        assertFalse(pong.isVaultPaused());
        pong.togglePause();
        assertTrue(pong.isVaultPaused());
    }

    function testTogglePauseUnpausesGameplay() public {
        pong.togglePause();
        assertTrue(pong.isVaultPaused());
        pong.togglePause();
        assertFalse(pong.isVaultPaused());
    }

    function testPauseBlocksGameCreation() public {
        pong.togglePause();
        
        vm.prank(alice);
        vm.expectRevert(PingPong.GameplayPaused.selector);
        pong.createGame{value: STAKE}();
    }

    function testPauseBlocksGameJoin() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        pong.togglePause();
        
        vm.prank(bob);
        vm.expectRevert(PingPong.GameplayPaused.selector);
        pong.joinGame{value: STAKE}(1);
    }

    function testPauseBlocksRefund() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        pong.togglePause();
        
        vm.prank(alice);
        vm.expectRevert(PingPong.GameplayPaused.selector);
        pong.requestRefund(1);
    }

    function testPauseBlocksTimeoutRefund() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        vm.warp(block.timestamp + 8 days);
        
        pong.togglePause();
        
        vm.prank(alice);
        vm.expectRevert(PingPong.GameplayPaused.selector);
        pong.claimTimeoutRefund(1);
    }

    function testPauseBlocksUsePowerup() public {
        pong.grantPowerup(alice, 1);
        
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        vm.prank(bob);
        pong.joinGame{value: STAKE}(1);
        
        pong.togglePause();
        
        vm.prank(alice);
        vm.expectRevert(PingPong.GameplayPaused.selector);
        pong.usePowerup(1, 1);
    }

    function testUnpauseAllowsGameCreation() public {
        pong.togglePause();
        pong.togglePause();
        
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        assertEq(pong.getTotalGames(), 1);
    }

    function testMultipleTogglesCycle() public {
        assertFalse(pong.isVaultPaused());
        
        pong.togglePause();
        assertTrue(pong.isVaultPaused());
        
        pong.togglePause();
        assertFalse(pong.isVaultPaused());
        
        pong.togglePause();
        assertTrue(pong.isVaultPaused());
    }

    function testPauseAllowsGameQueries() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        pong.togglePause();
        
        assertEq(pong.getTotalGames(), 1);
        assertEq(pong.getGameStatus(1), 1);
    }

    function testPauseAllowsOwnerFunctions() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        vm.prank(bob);
        pong.joinGame{value: STAKE}(1);
        
        pong.togglePause();
        
        pong.endGame(1, alice);
        
        assertEq(pong.getGameStatus(1), 3);
    }
}
