// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "./PingPong.sol";

contract PingPongGameEndTest is Test {
    PingPong pong;
    address owner = address(this);
    address alice = address(0xA1);
    address bob = address(0xB2);
    address carol = address(0xC3);
    uint256 constant STAKE = 1 ether;

    function setUp() public {
        pong = new PingPong();
        vm.deal(alice, 10 ether);
        vm.deal(bob, 10 ether);
    }

    function testEndGameChangesStatusToEnded() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        vm.prank(bob);
        pong.joinGame{value: STAKE}(1);
        
        pong.endGame(1, alice);
        
        assertEq(pong.getGameStatus(1), 3);
    }

    function testEndGamePayoutToWinner() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        vm.prank(bob);
        pong.joinGame{value: STAKE}(1);
        
        uint256 balBefore = alice.balance;
        pong.endGame(1, alice);
        
        uint256 expectedPayout = (STAKE * 2 * 95) / 100;
        assertEq(alice.balance, balBefore + expectedPayout);
    }

    function testEndGameCollectsDevFees() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        vm.prank(bob);
        pong.joinGame{value: STAKE}(1);
        
        pong.endGame(1, alice);
        
        uint256 expectedFee = (STAKE * 2 * 5) / 100;
        assertEq(pong.getDevFees(), expectedFee);
    }

    function testEndGameZeroesEscrow() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        vm.pank(bob);
        pong.joinGame{value: STAKE}(1);
        
        pong.endGame(1, alice);
        
        assertEq(pong.getGameEscrow(1), 0);
    }

    function testEndGameWithBobAsWinner() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        vm.prank(bob);
        pong.joinGame{value: STAKE}(1);
        
        uint256 balBefore = bob.balance;
        pong.endGame(1, bob);
        
        uint256 expectedPayout = (STAKE * 2 * 95) / 100;
        assertEq(bob.balance, balBefore + expectedPayout);
    }

    function testEndGameInvalidWinnerFails() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        vm.prank(bob);
        pong.joinGame{value: STAKE}(1);
        
        vm.expectRevert(PingPong.InvalidWinner.selector);
        pong.endGame(1, carol);
    }

    function testEndGameNonOwnerFails() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        vm.prank(bob);
        pong.joinGame{value: STAKE}(1);
        
        vm.prank(bob);
        vm.expectRevert();
        pong.endGame(1, bob);
    }

    function testEndGameWithoutPlayer2Fails() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        vm.expectRevert(PingPong.Player2NotJoined.selector);
        pong.endGame(1, alice);
    }

    function testEndGameWrongStatusFails() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        vm.expectRevert(PingPong.InvalidStatus.selector);
        pong.endGame(1, alice);
    }

    function testEndGameMultipleTimesSecondFails() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        vm.prank(bob);
        pong.joinGame{value: STAKE}(1);
        
        pong.endGame(1, alice);
        
        vm.expectRevert(PingPong.InvalidStatus.selector);
        pong.endGame(1, alice);
    }
}
