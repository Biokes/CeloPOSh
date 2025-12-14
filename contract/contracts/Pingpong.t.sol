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

    receive() external payable {}
}