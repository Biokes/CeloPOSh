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
    uint256 constant TIMEOUT = 7 days;

    function setUp() public {
        pong = new PingPong();
        vm.deal(alice, 100 ether);
        vm.deal(bob, 100 ether);
        vm.deal(carol, 100 ether);
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

    // ============ ADDITIONAL DEPLOYMENT TESTS ============

    function testDeploymentSuccessful() public {
        assertNotEq(address(pong), address(0));
    }

    function testOwnershipAssignedCorrectly() public {
        assertEq(pong.owner(), owner);
    }

    function testInitialGamesCountIsZero() public {
        assertEq(pong.getTotalGames(), 0);
    }

    function testInitialFeesAreZero() public {
        assertEq(pong.getDevFees(), 0);
    }

    function testVaultNotPausedOnDeploy() public {
        assertFalse(pong.isVaultPaused());
    }

    // ============ ADDITIONAL CREATE GAME TESTS ============

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

    // ============ ADDITIONAL JOIN GAME TESTS ============

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

    // ============ ADDITIONAL END GAME TESTS ============

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

    function testEndGameZeroesEscrow() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        vm.prank(bob);
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

    // ============ ADDITIONAL REFUND TESTS ============

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

    // ============ ADDITIONAL TIMEOUT REFUND TESTS ============

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

    // ============ ADDITIONAL POWERUP TESTS ============

    function testGrantPowerupInvalidTypeFails() public {
        vm.expectRevert(PingPong.InvalidPowerupType.selector);
        pong.grantPowerup(alice, 4);
    }

    function testGrantPowerupNullAddressFails() public {
        vm.expectRevert(PingPong.InvalidAmount.selector);
        pong.grantPowerup(address(0), 1);
    }

    function testGrantMultiplePowerupTypes() public {
        pong.grantPowerup(alice, 1);
        pong.grantPowerup(alice, 2);
        pong.grantPowerup(alice, 3);
        
        assertEq(pong.getPowerupCount(alice, 1), 1);
        assertEq(pong.getPowerupCount(alice, 2), 1);
        assertEq(pong.getPowerupCount(alice, 3), 1);
    }

    function testGetAllPowerupsReturnsCorrectCounts() public {
        pong.grantPowerup(alice, 1);
        pong.grantPowerup(alice, 2);
        pong.grantPowerup(alice, 3);
        
        (uint64 pad, uint64 multi, uint64 shield) = pong.getAllPowerups(alice);
        assertEq(pad, 1);
        assertEq(multi, 1);
        assertEq(shield, 1);
    }

    function testGetAllPowerupsZeroForNeverGranted() public {
        (uint64 pad, uint64 multi, uint64 shield) = pong.getAllPowerups(bob);
        assertEq(pad, 0);
        assertEq(multi, 0);
        assertEq(shield, 0);
    }

    function testUsePowerupInvalidTypeFails() public {
        pong.grantPowerup(alice, 1);
        
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        vm.prank(bob);
        pong.joinGame{value: STAKE}(1);
        
        vm.prank(alice);
        vm.expectRevert(PingPong.InvalidPowerupType.selector);
        pong.usePowerup(1, 4);
    }

    function testGrantPowerupNonOwnerFails() public {
        vm.prank(alice);
        vm.expectRevert();
        pong.grantPowerup(alice, 1);
    }

    // ============ ADDITIONAL PAUSE FUNCTIONALITY TESTS ============

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

    // ============ ADDITIONAL DEV FEES TESTS ============

    function testDevFeeCollectedOnGameEnd() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        vm.prank(bob);
        pong.joinGame{value: STAKE}(1);
        
        uint256 expectedFee = (STAKE * 5) / 100;
        
        pong.endGame(1, alice);
        
        uint256 devFees = pong.getDevFees();
        assertEq(devFees, expectedFee * 2);
    }

    function testMultipleGameFeesAccumulate() public {
        for (uint256 i = 0; i < 3; i++) {
            vm.prank(alice);
            pong.createGame{value: STAKE}();
            
            vm.prank(bob);
            pong.joinGame{value: STAKE}(i + 1);
            
            pong.endGame(i + 1, alice);
        }
        
        uint256 expectedTotalFees = (3 * STAKE * 5) / 100 * 2;
        uint256 devFees = pong.getDevFees();
        assertEq(devFees, expectedTotalFees);
    }

    function testWithdrawDevFees() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        vm.prank(bob);
        pong.joinGame{value: STAKE}(1);
        
        pong.endGame(1, alice);
        
        uint256 expectedFee = (STAKE * 5) / 100;
        
        uint256 balanceBefore = address(this).balance;
        pong.withdrawDevFees();
        uint256 balanceAfter = address(this).balance;
        
        assertEq(balanceAfter - balanceBefore, expectedFee * 2);
    }

    function testWithdrawDevFeesZeroBalance() public {
        uint256 devFees = pong.getDevFees();
        assertEq(devFees, 0);
        
        uint256 balanceBefore = address(this).balance;
        pong.withdrawDevFees();
        uint256 balanceAfter = address(this).balance;
        
        assertEq(balanceAfter, balanceBefore);
    }

    function testWithdrawDevFeesClears() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        vm.prank(bob);
        pong.joinGame{value: STAKE}(1);
        
        pong.endGame(1, alice);
        
        pong.withdrawDevFees();
        
        uint256 devFeesAfter = pong.getDevFees();
        assertEq(devFeesAfter, 0);
    }

    function testNonOwnerCannotWithdraw() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        vm.prank(bob);
        pong.joinGame{value: STAKE}(1);
        
        pong.endGame(1, alice);
        
        vm.prank(alice);
        vm.expectRevert();
        pong.withdrawDevFees();
    }

    function testFeeCalculationAccuracy() public {
        uint256 largeStake = 10 ether;
        vm.deal(alice, 500 ether);
        vm.deal(bob, 500 ether);
        
        vm.prank(alice);
        pong.createGame{value: largeStake}();
        
        vm.prank(bob);
        pong.joinGame{value: largeStake}(1);
        
        pong.endGame(1, alice);
        
        uint256 expectedFee = (largeStake * 5) / 100;
        uint256 devFees = pong.getDevFees();
        assertEq(devFees, expectedFee * 2);
    }

    function testSequentialWithdrawals() public {
        for (uint256 i = 0; i < 2; i++) {
            vm.prank(alice);
            pong.createGame{value: STAKE}();
            
            vm.prank(bob);
            pong.joinGame{value: STAKE}(i + 1);
            
            pong.endGame(i + 1, alice);
            
            uint256 expectedFee = (STAKE * 5) / 100;
            uint256 feesBeforeWithdraw = pong.getDevFees();
            assertEq(feesBeforeWithdraw, expectedFee * 2);
            
            pong.withdrawDevFees();
            
            uint256 feesAfterWithdraw = pong.getDevFees();
            assertEq(feesAfterWithdraw, 0);
        }
    }

    function testDevFeeDoesNotAffectWinnerPayout() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        vm.prank(bob);
        pong.joinGame{value: STAKE}(1);
        
        uint256 aliceBalanceBefore = alice.balance;
        
        pong.endGame(1, alice);
        
        uint256 expectedFee = (STAKE * 5) / 100;
        uint256 expectedWinnings = 2 * STAKE - (expectedFee * 2);
        
        assertEq(alice.balance, aliceBalanceBefore + expectedWinnings);
    }

    function testDevFeeWithManyGames() public {
        for (uint256 i = 0; i < 10; i++) {
            vm.prank(alice);
            pong.createGame{value: STAKE}();
            
            vm.prank(bob);
            pong.joinGame{value: STAKE}(i + 1);
            
            pong.endGame(i + 1, alice);
        }
        
        uint256 expectedTotalFees = (10 * STAKE * 5) / 100 * 2;
        uint256 devFees = pong.getDevFees();
        assertEq(devFees, expectedTotalFees);
    }

    // ============ ADDITIONAL GAME CREATION STRESS TESTS ============

    function testCreateGameWithMinimumStake() public {
        vm.prank(alice);
        pong.createGame{value: 0.001 ether}();
        
        assertEq(pong.getTotalGames(), 1);
        assertEq(pong.getGameEscrow(1), 0.001 ether);
    }

    function testCreateGameWithLargeStake() public {
        vm.prank(alice);
        pong.createGame{value: 100 ether}();
        
        assertEq(pong.getTotalGames(), 1);
        assertEq(pong.getGameEscrow(1), 100 ether);
    }

    function testCreateGameTimestampRecorded() public {
        uint256 beforeTime = block.timestamp;
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        uint256 afterTime = block.timestamp;
        
        PingPong.GameSession memory game = pong.getGame(1);
        assertTrue(game.createdAt >= beforeTime && game.createdAt <= afterTime);
    }

    function testMultiplePlayersCreateGamesConcurrently() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        vm.prank(bob);
        pong.createGame{value: STAKE}();
        
        vm.prank(carol);
        pong.createGame{value: STAKE}();
        
        assertEq(pong.getTotalGames(), 3);
    }

    function testCreateGamePlayerOneSet() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        PingPong.GameSession memory game = pong.getGame(1);
        assertEq(game.player1, alice);
        assertEq(game.player2, address(0));
    }

    function testCreateGameStatusNotActive() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        uint256 status = pong.getGameStatus(1);
        assertNotEq(status, 2);
    }

    function testJoinGameWithExactStakeAmount() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        vm.prank(bob);
        pong.joinGame{value: STAKE}(1);
        
        PingPong.GameSession memory game = pong.getGame(1);
        assertEq(game.player2, bob);
    }

    function testJoinGameIncreasesEscrowProperly() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        uint256 escrowBefore = pong.getGameEscrow(1);
        
        vm.prank(bob);
        pong.joinGame{value: STAKE}(1);
        
        uint256 escrowAfter = pong.getGameEscrow(1);
        assertEq(escrowAfter, escrowBefore + STAKE);
    }

    function testJoinGameMakesGameActive() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        vm.prank(bob);
        pong.joinGame{value: STAKE}(1);
        
        assertEq(pong.getGameStatus(1), 2);
    }

    function testEndGamePayoutCalculation() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        vm.prank(bob);
        pong.joinGame{value: STAKE}(1);
        
        uint256 totalStake = STAKE * 2;
        uint256 fee = (totalStake * 5) / 100;
        uint256 expectedPayout = totalStake - fee;
        
        uint256 balanceBefore = alice.balance;
        pong.endGame(1, alice);
        
        assertEq(alice.balance - balanceBefore, expectedPayout);
    }

    function testEndGameDevFeeAccumulation() public {
        for (uint256 i = 0; i < 5; i++) {
            vm.prank(alice);
            pong.createGame{value: STAKE}();
            
            vm.prank(bob);
            pong.joinGame{value: STAKE}(i + 1);
            
            pong.endGame(i + 1, alice);
        }
        
        uint256 expectedFees = (5 * STAKE * 2 * 5) / 100;
        assertEq(pong.getDevFees(), expectedFees);
    }

    function testRefundGameStatusChange() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        assertEq(pong.getGameStatus(1), 1);
        
        vm.prank(alice);
        pong.requestRefund(1);
        
        assertEq(pong.getGameStatus(1), 4);
    }

    function testRefundRestoresBalance() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        uint256 balanceBefore = alice.balance;
        
        vm.prank(alice);
        pong.requestRefund(1);
        
        uint256 balanceAfter = alice.balance;
        assertEq(balanceAfter - balanceBefore, STAKE);
    }

    function testRefundClearsEscrow() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        assertEq(pong.getGameEscrow(1), STAKE);
        
        vm.prank(alice);
        pong.requestRefund(1);
        
        assertEq(pong.getGameEscrow(1), 0);
    }

    function testTimeoutRefundChangesStatus() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        vm.warp(block.timestamp + TIMEOUT + 1);
        
        vm.prank(alice);
        pong.claimTimeoutRefund(1);
        
        assertEq(pong.getGameStatus(1), 4);
    }

    function testPowerupGrantingIncreasesInventory() public {
        assertEq(pong.getPowerupCount(alice, 1), 0);
        
        pong.grantPowerup(alice, 1);
        
        assertEq(pong.getPowerupCount(alice, 1), 1);
    }

    function testPowerupUsageDecrementsInventory() public {
        pong.grantPowerup(alice, 1);
        
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        vm.prank(bob);
        pong.joinGame{value: STAKE}(1);
        
        assertEq(pong.getPowerupCount(alice, 1), 1);
        
        vm.prank(alice);
        pong.usePowerup(1, 1);
        
        assertEq(pong.getPowerupCount(alice, 1), 0);
    }

    function testPausePreventsBidding() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        pong.togglePause();
        
        vm.prank(bob);
        vm.expectRevert(PingPong.GameplayPaused.selector);
        pong.joinGame{value: STAKE}(1);
    }

    function testPausePreventsBidding2() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        pong.togglePause();
        
        vm.prank(alice);
        vm.expectRevert(PingPong.GameplayPaused.selector);
        pong.requestRefund(1);
    }

    function testGameCreationWithDifferentPlayers() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        vm.prank(bob);
        pong.createGame{value: STAKE}();
        
        vm.prank(carol);
        pong.createGame{value: STAKE}();
        
        assertEq(pong.getTotalGames(), 3);
        assertTrue(pong.isGameExists(1));
        assertTrue(pong.isGameExists(2));
        assertTrue(pong.isGameExists(3));
    }

    function testGameCreationIdSequential() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        assertEq(pong.getGame(1).id, 1);
        assertEq(pong.getGame(2).id, 2);
    }

    function testGameHistoryTracking() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        uint64[] memory games = pong.getPlayerGames(alice);
        assertEq(games.length, 3);
    }

    function testGameCountIncrements() public {
        assertEq(pong.getTotalGames(), 0);
        
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        assertEq(pong.getTotalGames(), 1);
        
        vm.prank(bob);
        pong.createGame{value: STAKE}();
        assertEq(pong.getTotalGames(), 2);
    }

    function testJoinGameBothPlayersTracked() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        vm.prank(bob);
        pong.joinGame{value: STAKE}(1);
        
        uint64[] memory aliceGames = pong.getPlayerGames(alice);
        uint64[] memory bobGames = pong.getPlayerGames(bob);
        
        assertEq(aliceGames.length, 1);
        assertEq(bobGames.length, 1);
    }

    function testMultipleGamesWithSamePlayer() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        vm.prank(bob);
        pong.joinGame{value: STAKE}(1);
        
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        vm.prank(carol);
        pong.joinGame{value: STAKE}(2);
        
        uint64[] memory aliceGames = pong.getPlayerGames(alice);
        assertEq(aliceGames.length, 2);
    }

    function testGameStatusProgression() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        assertEq(pong.getGameStatus(1), 1);
        
        vm.prank(bob);
        pong.joinGame{value: STAKE}(1);
        assertEq(pong.getGameStatus(1), 2);
        
        pong.endGame(1, alice);
        assertEq(pong.getGameStatus(1), 3);
    }

    function testEndGameWithBobWinsPayoutCalculation() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        vm.prank(bob);
        pong.joinGame{value: STAKE}(1);
        
        uint256 totalStake = STAKE * 2;
        uint256 fee = (totalStake * 5) / 100;
        uint256 expectedPayout = totalStake - fee;
        
        uint256 balanceBefore = bob.balance;
        pong.endGame(1, bob);
        
        assertEq(bob.balance - balanceBefore, expectedPayout);
    }

    function testMultiplePowerupTypes() public {
        pong.grantPowerup(alice, 1);
        pong.grantPowerup(alice, 2);
        pong.grantPowerup(alice, 3);
        
        (uint64 pad, uint64 multi, uint64 shield) = pong.getAllPowerups(alice);
        assertEq(pad, 1);
        assertEq(multi, 1);
        assertEq(shield, 1);
    }

    function testPowerupInventoryMultiple() public {
        pong.grantPowerup(alice, 1);
        pong.grantPowerup(alice, 1);
        pong.grantPowerup(alice, 1);
        
        assertEq(pong.getPowerupCount(alice, 1), 3);
    }

    function testGameRefundCancelGameSequence() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        assertEq(pong.getGameStatus(1), 1);
        
        vm.prank(alice);
        pong.requestRefund(1);
        
        assertEq(pong.getGameStatus(1), 4);
        assertEq(pong.getGameEscrow(1), 0);
    }

    function testTimeoutRefundWaitingGameFullRefund() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        vm.warp(block.timestamp + TIMEOUT + 1);
        
        uint256 balanceBefore = alice.balance;
        vm.prank(alice);
        pong.claimTimeoutRefund(1);
        
        assertEq(alice.balance - balanceBefore, STAKE);
    }

    function testTimeoutRefundActiveGameBothPlayers() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        vm.prank(bob);
        pong.joinGame{value: STAKE}(1);
        
        vm.warp(block.timestamp + TIMEOUT + 1);
        
        uint256 aliceBalBefore = alice.balance;
        uint256 bobBalBefore = bob.balance;
        
        vm.prank(alice);
        pong.claimTimeoutRefund(1);
        
        assertEq(alice.balance - aliceBalBefore, STAKE);
        assertEq(bob.balance - bobBalBefore, STAKE);
    }

    function testGameExistenceCheck() public {
        assertFalse(pong.isGameExists(1));
        
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        assertTrue(pong.isGameExists(1));
    }

    function testPlayerGameCount() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        assertEq(pong.getPlayerGameCount(alice), 2);
    }

    function testGameDataRetrieval() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        PingPong.GameSession memory game = pong.getGame(1);
        assertEq(game.player1, alice);
        assertEq(game.stakeAmount, STAKE);
        assertEq(game.status, 1);
    }

    function testDevFeeWithdrawalOwnerOnly() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        vm.prank(bob);
        pong.joinGame{value: STAKE}(1);
        
        pong.endGame(1, alice);
        
        uint256 devFees = pong.getDevFees();
        assertGt(devFees, 0);
        
        pong.withdrawDevFees();
        assertEq(pong.getDevFees(), 0);
    }

    function testGameCreationEdgeCaseJoin() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        vm.prank(bob);
        pong.joinGame{value: STAKE}(1);
        
        vm.prank(carol);
        vm.expectRevert(PingPong.Player2SlotNotEmpty.selector);
        pong.joinGame{value: STAKE}(1);
    }

    function testRefundOnlyWaitingGame() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        vm.prank(bob);
        pong.joinGame{value: STAKE}(1);
        
        vm.prank(alice);
        vm.expectRevert(PingPong.InvalidStatus.selector);
        pong.requestRefund(1);
    }

    function testPauseToggleCycle() public {
        for (uint256 i = 0; i < 5; i++) {
            pong.togglePause();
            if (i % 2 == 0) {
                assertTrue(pong.isVaultPaused());
            } else {
                assertFalse(pong.isVaultPaused());
            }
        }
    }

    function testPowerupAllThreeTypes() public {
        pong.grantPowerup(alice, 1);
        pong.grantPowerup(bob, 2);
        pong.grantPowerup(carol, 3);
        
        assertEq(pong.getPowerupCount(alice, 1), 1);
        assertEq(pong.getPowerupCount(bob, 2), 1);
        assertEq(pong.getPowerupCount(carol, 3), 1);
    }

    function testCascadingGameCreations() public {
        for (uint256 i = 1; i <= 10; i++) {
            vm.prank(alice);
            pong.createGame{value: STAKE}();
        }
        assertEq(pong.getTotalGames(), 10);
    }

    function testGameJoinSequential() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        vm.prank(bob);
        pong.createGame{value: STAKE}();
        
        vm.prank(carol);
        pong.joinGame{value: STAKE}(1);
        
        assertEq(pong.getGameStatus(2), 1);
        assertEq(pong.getGameStatus(1), 2);
    }

    function testFeeAccumulationMultipleGames() public {
        for (uint256 i = 0; i < 3; i++) {
            vm.prank(alice);
            pong.createGame{value: STAKE}();
            
            vm.prank(bob);
            pong.joinGame{value: STAKE}(i + 1);
            
            pong.endGame(i + 1, alice);
        }
        
        uint256 totalFees = pong.getDevFees();
        assertGt(totalFees, 0);
    }

    function testTimeoutRefundMultipleGamesSequence() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        vm.prank(bob);
        pong.createGame{value: STAKE}();
        
        vm.warp(block.timestamp + TIMEOUT + 1);
        
        vm.prank(alice);
        pong.claimTimeoutRefund(1);
        
        vm.prank(bob);
        pong.claimTimeoutRefund(2);
        
        assertEq(pong.getGameStatus(1), 4);
        assertEq(pong.getGameStatus(2), 4);
    }

    function testEndGameWithAlternateWinner() public {
        for (uint256 i = 0; i < 2; i++) {
            vm.prank(alice);
            pong.createGame{value: STAKE}();
            
            vm.prank(bob);
            pong.joinGame{value: STAKE}(i + 1);
            
            if (i % 2 == 0) {
                pong.endGame(i + 1, alice);
            } else {
                pong.endGame(i + 1, bob);
            }
        }
    }

    function testGameCreationBalanceDeduction() public {
        uint256 balanceBefore = alice.balance;
        
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        uint256 balanceAfter = alice.balance;
        assertEq(balanceBefore - balanceAfter, STAKE);
    }

    function testGameJoinBalanceDeduction() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        uint256 balanceBefore = bob.balance;
        
        vm.prank(bob);
        pong.joinGame{value: STAKE}(1);
        
        uint256 balanceAfter = bob.balance;
        assertEq(balanceBefore - balanceAfter, STAKE);
    }

    function testRefundBalanceRestoration() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        uint256 balanceAfterCreation = alice.balance;
        
        vm.prank(alice);
        pong.requestRefund(1);
        
        uint256 balanceAfterRefund = alice.balance;
        assertEq(balanceAfterRefund - balanceAfterCreation, STAKE);
    }

    function testPowerupGrantingMultiplePlayers() public {
        pong.grantPowerup(alice, 1);
        pong.grantPowerup(alice, 1);
        
        pong.grantPowerup(bob, 1);
        
        assertEq(pong.getPowerupCount(alice, 1), 2);
        assertEq(pong.getPowerupCount(bob, 1), 1);
    }

    function testPauseAndUnpauseGameFlow() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        pong.togglePause();
        assertTrue(pong.isVaultPaused());
        
        vm.prank(bob);
        vm.expectRevert(PingPong.GameplayPaused.selector);
        pong.joinGame{value: STAKE}(1);
        
        pong.togglePause();
        assertFalse(pong.isVaultPaused());
        
        vm.prank(bob);
        pong.joinGame{value: STAKE}(1);
        assertEq(pong.getGameStatus(1), 2);
    }

    function testMultiGameRefundScenario() public {
        for (uint256 i = 1; i <= 3; i++) {
            vm.prank(alice);
            pong.createGame{value: STAKE}();
        }
        
        assertEq(pong.getTotalGames(), 3);
        
        vm.prank(alice);
        pong.requestRefund(1);
        
        assertEq(pong.getGameStatus(1), 4);
        assertEq(pong.getGameStatus(2), 1);
        assertEq(pong.getGameStatus(3), 1);
    }

    function testGameStateConsistency() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        vm.prank(bob);
        pong.joinGame{value: STAKE}(1);
        
        PingPong.GameSession memory game = pong.getGame(1);
        
        assertEq(game.status, uint8(pong.getGameStatus(1)));
        assertEq(game.escrow, pong.getGameEscrow(1));
    }

    function testPlayerTrackedInBothGames() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        vm.prank(bob);
        pong.createGame{value: STAKE}();
        
        vm.prank(alice);
        pong.joinGame{value: STAKE}(2);
        
        uint64[] memory aliceGames = pong.getPlayerGames(alice);
        assertEq(aliceGames.length, 2);
    }

    function testGameEscrowAccuracy() public {
        vm.prank(alice);
        pong.createGame{value: 5 ether}();
        
        assertEq(pong.getGameEscrow(1), 5 ether);
        
        vm.prank(bob);
        pong.joinGame{value: 5 ether}(1);
        
        assertEq(pong.getGameEscrow(1), 10 ether);
    }

    function testMultipleRefundsSequence() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        vm.prank(bob);
        pong.createGame{value: STAKE}();
        
        vm.prank(alice);
        pong.requestRefund(1);
        
        vm.prank(bob);
        pong.requestRefund(2);
        
        assertEq(pong.getGameStatus(1), 4);
        assertEq(pong.getGameStatus(2), 4);
    }

    function testGameEndingAffectsOtherGames() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        vm.prank(bob);
        pong.createGame{value: STAKE}();
        
        vm.prank(alice);
        pong.joinGame{value: STAKE}(2);
        
        pong.endGame(2, alice);
        
        assertEq(pong.getGameStatus(1), 1);
        assertEq(pong.getGameStatus(2), 3);
    }

    function testTimeoutRefundDoesNotAffectOthers() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        vm.prank(bob);
        pong.createGame{value: STAKE}();
        
        vm.warp(block.timestamp + TIMEOUT + 1);
        
        vm.prank(alice);
        pong.claimTimeoutRefund(1);
        
        assertEq(pong.getGameStatus(1), 4);
        assertEq(pong.getGameStatus(2), 1);
    }

    function testPowerupUsageInMultipleGames() public {
        pong.grantPowerup(alice, 1);
        pong.grantPowerup(alice, 1);
        
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        vm.prank(bob);
        pong.joinGame{value: STAKE}(1);
        
        vm.prank(alice);
        pong.usePowerup(1, 1);
        
        assertEq(pong.getPowerupCount(alice, 1), 1);
    }

    function testCrossPlayerGameSequence() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        vm.prank(bob);
        pong.createGame{value: STAKE}();
        
        vm.prank(carol);
        pong.joinGame{value: STAKE}(1);
        
        vm.prank(alice);
        pong.joinGame{value: STAKE}(2);
        
        assertEq(pong.getGameStatus(1), 2);
        assertEq(pong.getGameStatus(2), 2);
    }

    function testGameCreationWithVaryingStakes() public {
        vm.prank(alice);
        pong.createGame{value: 1 ether}();
        
        vm.prank(bob);
        pong.createGame{value: 2 ether}();
        
        vm.prank(carol);
        pong.createGame{value: 5 ether}();
        
        assertEq(pong.getGameEscrow(1), 1 ether);
        assertEq(pong.getGameEscrow(2), 2 ether);
        assertEq(pong.getGameEscrow(3), 5 ether);
    }

    function testFeeCalculationAccuracy() public {
        vm.prank(alice);
        pong.createGame{value: 10 ether}();
        
        vm.prank(bob);
        pong.joinGame{value: 10 ether}(1);
        
        uint256 totalStake = 20 ether;
        uint256 fee = (totalStake * 5) / 100;
        
        pong.endGame(1, alice);
        
        assertEq(pong.getDevFees(), fee);
    }

    function testGameEndSequentialWinners() public {
        for (uint256 i = 1; i <= 3; i++) {
            vm.prank(alice);
            pong.createGame{value: STAKE}();
            
            vm.prank(bob);
            pong.joinGame{value: STAKE}(i);
            
            if (i % 2 == 1) {
                pong.endGame(i, alice);
            } else {
                pong.endGame(i, bob);
            }
        }
        
        assertEq(pong.getGameStatus(1), 3);
        assertEq(pong.getGameStatus(2), 3);
        assertEq(pong.getGameStatus(3), 3);
    }

    function testRefundBalancePrecision() public {
        vm.prank(alice);
        pong.createGame{value: 3.5 ether}();
        
        uint256 balanceBefore = alice.balance;
        
        vm.prank(alice);
        pong.requestRefund(1);
        
        uint256 balanceAfter = alice.balance;
        assertEq(balanceAfter - balanceBefore, 3.5 ether);
    }

    function testGameHistoryOrdering() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        uint64[] memory games = pong.getPlayerGames(alice);
        assertEq(games[0], 1);
        assertEq(games[1], 2);
    }

    function testPowerupCounterAccuracy() public {
        for (uint256 i = 0; i < 5; i++) {
            pong.grantPowerup(alice, 1);
        }
        
        assertEq(pong.getPowerupCount(alice, 1), 5);
    }

    function testGameEscrowAfterEachJoin() public {
        vm.prank(alice);
        pong.createGame{value: 2 ether}();
        
        assertEq(pong.getGameEscrow(1), 2 ether);
        
        vm.prank(bob);
        pong.joinGame{value: 2 ether}(1);
        
        assertEq(pong.getGameEscrow(1), 4 ether);
    }

    function testTimeoutRefundPrecision() public {
        vm.prank(alice);
        pong.createGame{value: 7.5 ether}();
        
        vm.warp(block.timestamp + TIMEOUT + 1);
        
        uint256 balanceBefore = alice.balance;
        vm.prank(alice);
        pong.claimTimeoutRefund(1);
        
        assertEq(alice.balance - balanceBefore, 7.5 ether);
    }

    function testMultiplayerGameConcurrency() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        vm.prank(bob);
        pong.createGame{value: STAKE}();
        
        vm.prank(carol);
        pong.createGame{value: STAKE}();
        
        assertEq(pong.getTotalGames(), 3);
    }

    function testDevFeePercentageCorrect() public {
        vm.prank(alice);
        pong.createGame{value: 100 ether}();
        
        vm.prank(bob);
        pong.joinGame{value: 100 ether}(1);
        
        pong.endGame(1, alice);
        
        uint256 expectedFee = (200 ether * 5) / 100;
        assertEq(pong.getDevFees(), expectedFee);
    }

    function testGameStatusAfterRefund() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        vm.prank(alice);
        pong.requestRefund(1);
        
        uint256 status = pong.getGameStatus(1);
        assertEq(status, 4);
    }

    function testPowerupTypesIndependent() public {
        pong.grantPowerup(alice, 1);
        pong.grantPowerup(alice, 2);
        
        assertEq(pong.getPowerupCount(alice, 1), 1);
        assertEq(pong.getPowerupCount(alice, 2), 1);
        assertEq(pong.getPowerupCount(alice, 3), 0);
    }

    function testGameJoinWithCorrectStatus() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        assertEq(pong.getGameStatus(1), 1);
        
        vm.prank(bob);
        pong.joinGame{value: STAKE}(1);
        
        assertEq(pong.getGameStatus(1), 2);
    }

    function testMultipleGameEndings() public {
        for (uint256 i = 1; i <= 5; i++) {
            vm.prank(alice);
            pong.createGame{value: STAKE}();
            
            vm.prank(bob);
            pong.joinGame{value: STAKE}(i);
            
            pong.endGame(i, alice);
            
            assertEq(pong.getGameStatus(i), 3);
        }
    }

    function testGamePlayerAssignment() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        PingPong.GameSession memory game = pong.getGame(1);
        assertEq(game.player1, alice);
        assertEq(game.player2, address(0));
        
        vm.prank(bob);
        pong.joinGame{value: STAKE}(1);
        
        game = pong.getGame(1);
        assertEq(game.player2, bob);
    }

    function testGameRefundWaitingState() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        assertEq(pong.getGameStatus(1), 1);
        
        vm.prank(alice);
        pong.requestRefund(1);
        
        assertEq(pong.getGameStatus(1), 4);
    }

    function testBalanceChangesOnGameEnd() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        vm.prank(bob);
        pong.joinGame{value: STAKE}(1);
        
        uint256 aliceBalBefore = alice.balance;
        pong.endGame(1, alice);
        uint256 aliceBalAfter = alice.balance;
        
        assertGt(aliceBalAfter, aliceBalBefore);
    }

    function testPauseStateToggling() public {
        for (uint256 i = 0; i < 3; i++) {
            pong.togglePause();
        }
        
        assertTrue(pong.isVaultPaused());
    }

    function testGameCounterIncrementAccuracy() public {
        uint256 countBefore = pong.getTotalGames();
        
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        assertEq(pong.getTotalGames(), countBefore + 1);
    }

    function testGameCreationEscrowVerification() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        uint256 escrow = pong.getGameEscrow(1);
        assertEq(escrow, STAKE);
    }

    function testGameJoinEscrowAddition() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        uint256 escrowBefore = pong.getGameEscrow(1);
        
        vm.prank(bob);
        pong.joinGame{value: STAKE}(1);
        
        uint256 escrowAfter = pong.getGameEscrow(1);
        assertEq(escrowAfter, escrowBefore + STAKE);
    }

    function testRefundReducesEscrow() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        vm.prank(alice);
        pong.requestRefund(1);
        
        assertEq(pong.getGameEscrow(1), 0);
    }

    function testTimeoutRefundCompletionStatus() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        vm.warp(block.timestamp + TIMEOUT + 1);
        
        vm.prank(alice);
        pong.claimTimeoutRefund(1);
        
        assertEq(pong.getGameStatus(1), 4);
    }

    function testPowerupMultipleGrants() public {
        for (uint256 i = 0; i < 10; i++) {
            pong.grantPowerup(alice, 1);
        }
        
        assertEq(pong.getPowerupCount(alice, 1), 10);
    }

    function testGameStatusAfterJoin() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        uint256 statusBefore = pong.getGameStatus(1);
        assertEq(statusBefore, 1);
        
        vm.prank(bob);
        pong.joinGame{value: STAKE}(1);
        
        uint256 statusAfter = pong.getGameStatus(1);
        assertEq(statusAfter, 2);
    }

    function testGameIDSequence() public {
        for (uint256 i = 1; i <= 5; i++) {
            vm.prank(alice);
            pong.createGame{value: STAKE}();
            
            PingPong.GameSession memory game = pong.getGame(i);
            assertEq(game.id, uint64(i));
        }
    }

    function testPlayerHistoryAfterJoin() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        vm.prank(bob);
        pong.joinGame{value: STAKE}(1);
        
        uint64[] memory aliceGames = pong.getPlayerGames(alice);
        uint64[] memory bobGames = pong.getPlayerGames(bob);
        
        assertEq(aliceGames.length, 1);
        assertEq(bobGames.length, 1);
    }

    function testGameExistsAfterCreation() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        assertTrue(pong.isGameExists(1));
    }

    function testGameNotExistsAfterRefund() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        vm.prank(alice);
        pong.requestRefund(1);
        
        assertTrue(pong.isGameExists(1));
        assertEq(pong.getGameStatus(1), 4);
    }

    function testGameEndingTransfersWinnings() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        vm.prank(bob);
        pong.joinGame{value: STAKE}(1);
        
        uint256 winnerBalBefore = alice.balance;
        
        pong.endGame(1, alice);
        
        uint256 winnerBalAfter = alice.balance;
        assertTrue(winnerBalAfter > winnerBalBefore);
    }

    function testGameRefundValidation() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        vm.prank(alice);
        pong.requestRefund(1);
        
        assertTrue(pong.isGameExists(1));
    }

    function testGameStateTransition() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        assertEq(pong.getGameStatus(1), 1);
        
        vm.prank(bob);
        pong.joinGame{value: STAKE}(1);
        assertEq(pong.getGameStatus(1), 2);
        
        pong.endGame(1, alice);
        assertEq(pong.getGameStatus(1), 3);
    }

    function testGameDataConsistency() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        PingPong.GameSession memory game1 = pong.getGame(1);
        
        vm.prank(bob);
        pong.joinGame{value: STAKE}(1);
        
        PingPong.GameSession memory game2 = pong.getGame(1);
        
        assertEq(game1.player1, game2.player1);
        assertEq(game1.stakeAmount, game2.stakeAmount);
    }

    function testGameCreationPlayerTracking() public {
        address[] memory players = new address[](3);
        players[0] = alice;
        players[1] = bob;
        players[2] = carol;
        
        for (uint256 i = 0; i < 3; i++) {
            vm.prank(players[i]);
            pong.createGame{value: STAKE}();
        }
        
        PingPong.GameSession memory game1 = pong.getGame(1);
        PingPong.GameSession memory game2 = pong.getGame(2);
        PingPong.GameSession memory game3 = pong.getGame(3);
        
        assertEq(game1.player1, alice);
        assertEq(game2.player1, bob);
        assertEq(game3.player1, carol);
    }

    function testGameJoinPlayerAssignment() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        vm.prank(bob);
        pong.joinGame{value: STAKE}(1);
        
        PingPong.GameSession memory game = pong.getGame(1);
        assertEq(game.player1, alice);
        assertEq(game.player2, bob);
    }

    function testRefundMultipleGamesConcurrent() public {
        for (uint256 i = 0; i < 3; i++) {
            vm.prank(alice);
            pong.createGame{value: STAKE}();
        }
        
        for (uint256 i = 1; i <= 3; i++) {
            vm.prank(alice);
            pong.requestRefund(i);
        }
        
        for (uint256 i = 1; i <= 3; i++) {
            assertEq(pong.getGameStatus(i), 4);
        }
    }

    function testTimeoutRefundPrecisionMultiple() public {
        for (uint256 i = 0; i < 3; i++) {
            vm.prank(alice);
            pong.createGame{value: STAKE}();
        }
        
        vm.warp(block.timestamp + TIMEOUT + 1);
        
        for (uint256 i = 1; i <= 3; i++) {
            vm.prank(alice);
            pong.claimTimeoutRefund(i);
        }
        
        for (uint256 i = 1; i <= 3; i++) {
            assertEq(pong.getGameStatus(i), 4);
        }
    }

    function testGameEndMultiplePlayers() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        vm.prank(bob);
        pong.createGame{value: STAKE}();
        
        vm.prank(carol);
        pong.joinGame{value: STAKE}(1);
        
        vm.prank(alice);
        pong.joinGame{value: STAKE}(2);
        
        pong.endGame(1, carol);
        pong.endGame(2, alice);
        
        assertEq(pong.getGameStatus(1), 3);
        assertEq(pong.getGameStatus(2), 3);
    }

    function testFeeAccumulationTracker() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        vm.prank(bob);
        pong.joinGame{value: STAKE}(1);
        
        uint256 feeBefore = pong.getDevFees();
        
        pong.endGame(1, alice);
        
        uint256 feeAfter = pong.getDevFees();
        assertGt(feeAfter, feeBefore);
    }

    function testPowerupInventoryIndependence() public {
        pong.grantPowerup(alice, 1);
        pong.grantPowerup(bob, 1);
        
        assertEq(pong.getPowerupCount(alice, 1), 1);
        assertEq(pong.getPowerupCount(bob, 1), 1);
        
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        vm.prank(bob);
        pong.joinGame{value: STAKE}(1);
        
        vm.prank(alice);
        pong.usePowerup(1, 1);
        
        assertEq(pong.getPowerupCount(alice, 1), 0);
        assertEq(pong.getPowerupCount(bob, 1), 1);
    }

    function testCreateGameStakeTracking() public {
        vm.prank(alice);
        pong.createGame{value: 5 ether}();

    receive() external payable {}
}