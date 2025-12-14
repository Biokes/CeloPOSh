// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "./PingPong.sol";

contract PingPongTimeoutRefundTest is Test {
    PingPong pong;
    address alice = address(0xA1);
    address bob = address(0xB2);
    address carol = address(0xC3);
    uint256 constant STAKE = 1 ether;
    uint256 constant TIMEOUT = 7 days;

    function setUp() public {
        pong = new PingPong();
        vm.deal(alice, 10 ether);
        vm.deal(bob, 10 ether);
        vm.deal(carol, 10 ether);
    }

    function testTimeoutRefundWaitingGame() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        vm.warp(block.timestamp + TIMEOUT + 1);
        
        uint256 balBefore = alice.balance;
        
        vm.prank(alice);
        pong.claimTimeoutRefund(1);
        
        assertEq(alice.balance, balBefore + STAKE);
    }

    function testTimeoutRefundActiveGameSplitsFunds() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        vm.prank(bob);
        pong.joinGame{value: STAKE}(1);
        
        vm.warp(block.timestamp + TIMEOUT + 1);
        
        uint256 aliceBalBefore = alice.balance;
        uint256 bobBalBefore = bob.balance;
        
        vm.prank(alice);
        pong.claimTimeoutRefund(1);
        
        assertEq(alice.balance, aliceBalBefore + STAKE);
        assertEq(bob.balance, bobBalBefore + STAKE);
    }

    function testTimeoutRefundBeforeTimeoutFails() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        vm.prank(alice);
        vm.expectRevert(PingPong.GameExpired.selector);
        pong.claimTimeoutRefund(1);
    }

    function testTimeoutRefundUnauthorizedFails() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        vm.warp(block.timestamp + TIMEOUT + 1);
        
        vm.prank(carol);
        vm.expectRevert(PingPong.Unauthorized.selector);
        pong.claimTimeoutRefund(1);
    }

    function testTimeoutRefundNonExistentGameFails() public {
        vm.warp(block.timestamp + TIMEOUT + 1);
        
        vm.prank(alice);
        vm.expectRevert(PingPong.GameNotFound.selector);
        pong.claimTimeoutRefund(999);
    }

    function testTimeoutRefundActiveGamePlayer2CanClaim() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        vm.prank(bob);
        pong.joinGame{value: STAKE}(1);
        
        vm.warp(block.timestamp + TIMEOUT + 1);
        
        uint256 bobBalBefore = bob.balance;
        
        vm.prank(bob);
        pong.claimTimeoutRefund(1);
        
        assertEq(bob.balance, bobBalBefore + STAKE);
    }

    function testTimeoutRefundCancelledStatusBeforeClaim() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        vm.warp(block.timestamp + TIMEOUT + 1);
        
        vm.prank(alice);
        pong.claimTimeoutRefund(1);
        
        assertEq(pong.getGameStatus(1), 4);
    }

    function testTimeoutRefundMultipleGamesDifferentPlayers() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        vm.prank(bob);
        pong.createGame{value: STAKE}();
        
        vm.warp(block.timestamp + TIMEOUT + 1);
        
        uint256 aliceBalBefore = alice.balance;
        uint256 bobBalBefore = bob.balance;
        
        vm.prank(alice);
        pong.claimTimeoutRefund(1);
        
        vm.prank(bob);
        pong.claimTimeoutRefund(2);
        
        assertEq(alice.balance, aliceBalBefore + STAKE);
        assertEq(bob.balance, bobBalBefore + STAKE);
    }

    function testTimeoutRefundWithDifferentStakes() public {
        vm.prank(alice);
        pong.createGame{value: 2 ether}();
        
        vm.warp(block.timestamp + TIMEOUT + 1);
        
        uint256 balBefore = alice.balance;
        
        vm.prank(alice);
        pong.claimTimeoutRefund(1);
        
        assertEq(alice.balance, balBefore + 2 ether);
    }

    function testTimeoutRefundOnEndedGameFails() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        vm.prank(bob);
        pong.joinGame{value: STAKE}(1);
        
        pong.endGame(1, alice);
        
        vm.warp(block.timestamp + TIMEOUT + 1);
        
        vm.prank(alice);
        vm.expectRevert(PingPong.InvalidStatus.selector);
        pong.claimTimeoutRefund(1);
    }
}
