// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "./PingPong.sol";

contract PingPongTest is Test {
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
        vm.deal(carol, 10 ether);
    }

    // ============ DEPLOYMENT TESTS ============
    
    function testInitialStateSetup() public {
        assertEq(pong.getTotalGames(), 0);
    }

    function testInitialDevFeeVault() public {
        assertEq(pong.getDevFees(), 0);
    }

    function testInitialPausedState() public {
        assertFalse(pong.isVaultPaused());
    }

    // ============ CREATE GAME TESTS ============

    function testCreateGameWithValidStake() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        assertEq(pong.getTotalGames(), 1);
    }

    function testCreateGameStatusIsWaiting() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        assertEq(pong.getGameStatus(1), 1);
    }

    function testCreateGameEscrowHasStake() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        assertEq(pong.getGameEscrow(1), STAKE);
    }

    function testCreateGameZeroValueReverts() public {
        vm.prank(alice);
        vm.expectRevert(PingPong.InvalidAmount.selector);
        pong.createGame{value: 0}();
    }

    function testCreateGameWhenPausedReverts() public {
        pong.togglePause();
        vm.prank(alice);
        vm.expectRevert(PingPong.GameplayPaused.selector);
        pong.createGame{value: STAKE}();
    }

    function testCreateGameIncrementsGameCounter() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        vm.prank(bob);
        pong.createGame{value: STAKE}();
        
        assertEq(pong.getTotalGames(), 2);
    }

    // ============ JOIN GAME TESTS ============

    function testJoinGameWithCorrectStake() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();

        vm.prank(bob);
        pong.joinGame{value: STAKE}(1);

        assertEq(pong.getGameStatus(1), 2);
    }

    function testJoinGameEscrowDoubles() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();

        vm.prank(bob);
        pong.joinGame{value: STAKE}(1);

        assertEq(pong.getGameEscrow(1), STAKE * 2);
    }

    function testJoinGameWithWrongStakeReverts() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();

        vm.prank(bob);
        vm.expectRevert(PingPong.InvalidAmount.selector);
        pong.joinGame{value: 0.5 ether}(1);
    }

    function testCannotJoinOwnGameReverts() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();

        vm.prank(alice);
        vm.expectRevert(PingPong.CannotJoinOwnGame.selector);
        pong.joinGame{value: STAKE}(1);
    }

    function testJoinNonExistentGameReverts() public {
        vm.prank(bob);
        vm.expectRevert(PingPong.GameNotFound.selector);
        pong.joinGame{value: STAKE}(999);
    }

    function testJoinGameWhenPausedReverts() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        pong.togglePause();

        vm.prank(bob);
        vm.expectRevert(PingPong.GameplayPaused.selector);
        pong.joinGame{value: STAKE}(1);
    }

    // ============ END GAME TESTS ============

    function testEndGameWithAliceWinner() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();

        vm.prank(bob);
        pong.joinGame{value: STAKE}(1);

        pong.endGame(1, alice);

        assertEq(pong.getGameStatus(1), 3);
    }

    function testEndGameWithBobWinner() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();

        vm.prank(bob);
        pong.joinGame{value: STAKE}(1);

        pong.endGame(1, bob);

        assertEq(pong.getGameStatus(1), 3);
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

    function testEndGameWithInvalidWinnerReverts() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();

        vm.prank(bob);
        pong.joinGame{value: STAKE}(1);

        vm.expectRevert(PingPong.InvalidWinner.selector);
        pong.endGame(1, carol);
    }

    function testEndGameNonOwnerReverts() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();

        vm.prank(bob);
        pong.joinGame{value: STAKE}(1);

        vm.prank(bob);
        vm.expectRevert();
        pong.endGame(1, bob);
    }

    // ============ REFUND TESTS ============

    function testRequestRefundSuccessful() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();

        uint256 balanceBefore = alice.balance;

        vm.prank(alice);
        pong.requestRefund(1);

        assertEq(alice.balance, balanceBefore + STAKE);
    }

    function testRequestRefundChangesStatusToCancelled() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();

        vm.prank(alice);
        pong.requestRefund(1);

        assertEq(pong.getGameStatus(1), 4);
    }

    function testRequestRefundUnauthorizedReverts() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();

        vm.prank(bob);
        vm.expectRevert(PingPong.Unauthorized.selector);
        pong.requestRefund(1);
    }

    function testRequestRefundWhenPausedReverts() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        pong.togglePause();

        vm.prank(alice);
        vm.expectRevert(PingPong.GameplayPaused.selector);
        pong.requestRefund(1);
    }

    // ============ TIMEOUT REFUND TESTS ============

    function testClaimTimeoutRefundWaitingGame() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();

        vm.warp(block.timestamp + 8 days);

        uint256 balanceBefore = alice.balance;
        vm.prank(alice);
        pong.claimTimeoutRefund(1);

        assertEq(alice.balance, balanceBefore + STAKE);
    }

    function testClaimTimeoutRefundActiveGameSplitsFunds() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        vm.prank(bob);
        pong.joinGame{value: STAKE}(1);

        vm.warp(block.timestamp + 8 days);

        uint256 aliceBalBefore = alice.balance;
        uint256 bobBalBefore = bob.balance;

        vm.prank(alice);
        pong.claimTimeoutRefund(1);

        assertEq(alice.balance, aliceBalBefore + STAKE);
        assertEq(bob.balance, bobBalBefore + STAKE);
    }

    function testTimeoutRefundBeforeTimeoutReverts() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();

        vm.prank(alice);
        vm.expectRevert(PingPong.GameExpired.selector);
        pong.claimTimeoutRefund(1);
    }

    function testTimeoutRefundUnauthorizedReverts() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();

        vm.warp(block.timestamp + 8 days);

        vm.prank(carol);
        vm.expectRevert(PingPong.Unauthorized.selector);
        pong.claimTimeoutRefund(1);
    }

    // ============ POWERUP TESTS ============

    function testGrantPowerupPadStretch() public {
        pong.grantPowerup(alice, 1);
        assertEq(pong.getPowerupCount(alice, 1), 1);
    }

    function testGrantPowerupMultiball() public {
        pong.grantPowerup(alice, 2);
        assertEq(pong.getPowerupCount(alice, 2), 1);
    }

    function testGrantPowerupShield() public {
        pong.grantPowerup(alice, 3);
        assertEq(pong.getPowerupCount(alice, 3), 1);
    }

    function testGrantPowerupMultipleTimes() public {
        pong.grantPowerup(alice, 1);
        pong.grantPowerup(alice, 1);
        pong.grantPowerup(alice, 1);
        assertEq(pong.getPowerupCount(alice, 1), 3);
    }

    function testGetAllPowerupsReturnsAll() public {
        pong.grantPowerup(alice, 1);
        pong.grantPowerup(alice, 2);
        pong.grantPowerup(alice, 3);

        (uint64 pad, uint64 multi, uint64 shield) = pong.getAllPowerups(alice);
        assertEq(pad, 1);
        assertEq(multi, 1);
        assertEq(shield, 1);
    }

    function testUsePowerupDecrementsCount() public {
        pong.grantPowerup(alice, 1);

        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        vm.prank(bob);
        pong.joinGame{value: STAKE}(1);

        vm.prank(alice);
        pong.usePowerup(1, 1);

        assertEq(pong.getPowerupCount(alice, 1), 0);
    }

    function testUsePowerupWithoutInventoryReverts() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        vm.prank(bob);
        pong.joinGame{value: STAKE}(1);

        vm.prank(alice);
        vm.expectRevert(PingPong.InsufficientPowerups.selector);
        pong.usePowerup(1, 1);
    }

    function testUsePowerupNonParticipantReverts() public {
        pong.grantPowerup(alice, 1);

        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        vm.prank(bob);
        pong.joinGame{value: STAKE}(1);

        vm.prank(carol);
        vm.expectRevert(PingPong.NotGameParticipant.selector);
        pong.usePowerup(1, 1);
    }

    // ============ PAUSE FUNCTIONALITY TESTS ============

    function testTogglePausePausesGameplay() public {
        pong.togglePause();
        assertTrue(pong.isVaultPaused());
    }

    function testTogglePauseUnpausesGameplay() public {
        pong.togglePause();
        pong.togglePause();
        assertFalse(pong.isVaultPaused());
    }

    function testPauseBlocksGameCreation() public {
        pong.togglePause();

        vm.prank(alice);
        vm.expectRevert(PingPong.GameplayPaused.selector);
        pong.createGame{value: STAKE}();
    }

    // ============ DEV FEES TESTS ============

    function testWithdrawDevFeesSuccessful() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();

        vm.prank(bob);
        pong.joinGame{value: STAKE}(1);

        pong.endGame(1, alice);

        uint256 balanceBefore = owner.balance;
        pong.withdrawDevFees();

        assertGt(owner.balance, balanceBefore);
    }

    function testWithdrawDevFeesZeroesVault() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();

        vm.prank(bob);
        pong.joinGame{value: STAKE}(1);

        pong.endGame(1, alice);

        pong.withdrawDevFees();

        assertEq(pong.getDevFees(), 0);
    }

    function testWithdrawDevFeesNonOwnerReverts() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();

        vm.prank(bob);
        pong.joinGame{value: STAKE}(1);

        pong.endGame(1, alice);

        vm.prank(alice);
        vm.expectRevert();
        pong.withdrawDevFees();
    }

    // ============ GAME QUERY TESTS ============

    function testGetGameReturnsGameData() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();

        PingPong.GameSession memory game = pong.getGame(1);
        assertEq(game.player1, alice);
        assertEq(game.stakeAmount, STAKE);
    }

    function testGetPlayerGamesReturnsHistory() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();

        vm.prank(alice);
        pong.createGame{value: STAKE}();

        uint64[] memory games = pong.getPlayerGames(alice);
        assertEq(games.length, 2);
    }

    function testGetPlayerGameCountReturnsCorrectCount() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();

        vm.prank(alice);
        pong.createGame{value: STAKE}();

        assertEq(pong.getPlayerGameCount(alice), 2);
    }

    function testIsGameExistsReturnsTrueForValid() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();

        assertTrue(pong.isGameExists(1));
    }

    function testIsGameExistsReturnsFalseForInvalid() public {
        assertFalse(pong.isGameExists(999));
    }
}