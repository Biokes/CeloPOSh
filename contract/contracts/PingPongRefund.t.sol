// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "./PingPong.sol";

contract PingPongRefundTest is Test {
    PingPong pong;
    address alice = address(0xA1);
    address bob = address(0xB2);
    uint256 constant STAKE = 1 ether;

    function setUp() public {
        pong = new PingPong();
        vm.deal(alice, 10 ether);
        vm.deal(bob, 10 ether);
    }

    function testRequestRefundSuccessful() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        uint256 balBefore = alice.balance;
        
        vm.prank(alice);
        pong.requestRefund(1);
        
        assertEq(alice.balance, balBefore + STAKE);
    }

    function testRequestRefundStatusCancelled() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        vm.prank(alice);
        pong.requestRefund(1);
        
        assertEq(pong.getGameStatus(1), 4);
    }

    function testRequestRefundZeroesEscrow() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        vm.prank(alice);
        pong.requestRefund(1);
        
        assertEq(pong.getGameEscrow(1), 0);
    }

    function testRequestRefundUnauthorizedFails() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        vm.prank(bob);
        vm.expectRevert(PingPong.Unauthorized.selector);
        pong.requestRefund(1);
    }

    function testRequestRefundWrongStatusFails() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        vm.prank(bob);
        pong.joinGame{value: STAKE}(1);
        
        vm.prank(alice);
        vm.expectRevert(PingPong.InvalidStatus.selector);
        pong.requestRefund(1);
    }

    function testRequestRefundWhenPausedFails() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        pong.togglePause();
        
        vm.prank(alice);
        vm.expectRevert(PingPong.GameplayPaused.selector);
        pong.requestRefund(1);
    }

    function testRequestRefundNonExistentGameFails() public {
        vm.prank(alice);
        vm.expectRevert(PingPong.GameNotFound.selector);
        pong.requestRefund(999);
    }

    function testRequestRefundMultipleTimesFails() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        vm.prank(alice);
        pong.requestRefund(1);
        
        vm.prank(alice);
        vm.expectRevert(PingPong.InvalidStatus.selector);
        pong.requestRefund(1);
    }

    function testRequestRefundWithDifferentStake() public {
        vm.prank(alice);
        pong.createGame{value: 2 ether}();
        
        uint256 balBefore = alice.balance;
        
        vm.prank(alice);
        pong.requestRefund(1);
        
        assertEq(alice.balance, balBefore + 2 ether);
    }

    function testRequestRefundFromDifferentPlayers() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        vm.prank(bob);
        pong.createGame{value: STAKE}();
        
        uint256 aliceBalBefore = alice.balance;
        uint256 bobBalBefore = bob.balance;
        
        vm.prank(alice);
        pong.requestRefund(1);
        
        vm.prank(bob);
        pong.requestRefund(2);
        
        assertEq(alice.balance, aliceBalBefore + STAKE);
        assertEq(bob.balance, bobBalBefore + STAKE);
    }
}
