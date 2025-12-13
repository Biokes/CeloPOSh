// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;


import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PingPong is ReentrancyGuard, Ownable {
    uint8 private constant WAITING_STATUS = 1;
    uint8 private constant ACTIVE_STATUS = 2;
    uint8 private constant ENDED_STATUS = 3;
    uint8 private constant CANCELLED_STATUS = 4;

    uint8 private constant POWERUP_PAD_STRETCH = 1;
    uint8 private constant POWERUP_MULTIBALL = 2;
    uint8 private constant POWERUP_SHIELD = 3;

    uint256 private constant DEV_FEE_PERCENTAGE = 5;

    error GameplayPaused();
    error InvalidAmount();
    error Unauthorized();
    error Player2SlotNotEmpty();
    error CannotJoinOwnGame();
    error InvalidStatusTransition();
    error InsufficientBalance();
    error InvalidStatus();
    error Player2NotJoined();
    error InvalidPowerupType();
    error GameNotFound();
    error InsufficientPowerups();
    error TransferFailed();

    // ============ Structs ============
    struct GameSession {
        uint64 gameId;
        address player1;
        address player2;
        uint256 stakeAmount;
        uint256 escrowBalance;
        uint8 status;
        address winner;
        uint64 createdAt;
        uint64 completedAt;
    }

    struct PowerupInventory {
        uint64 padStretchCount;
        uint64 multiballCount;
        uint64 shieldCount;
    }

    // ============ Events ============
    event GameCreated(
        uint64 indexed gameId,
        address indexed player1,
        uint256 stakeAmount,
        uint64 createdAt,
        uint8 status
    );

    event GameJoined(
        uint64 indexed gameId,
        address indexed player2,
        uint256 stakeAmount,
        uint64 timestamp
    );

    event GameEnded(
        uint64 indexed gameId,
        address indexed winner,
        address indexed loser,
        uint256 winnerAmount,
        uint256 devFeeAmount,
        uint64 completedAt
    );

    event RefundClaimed(
        uint64 indexed gameId,
        address indexed player,
        uint256 amount,
        uint64 timestamp
    );

    event PowerupUsed(
        uint64 indexed gameId,
        address indexed player,
        uint8 powerupType,
        uint64 timestamp
    );

    event PowerupGranted(
        address indexed recipient,
        uint8 powerupType,
        uint64 count,
        uint64 timestamp
    );

    event VaultPauseToggled(
        bool paused,
        address indexed toggledBy,
        uint64 timestamp
    );

    event FeeWithdrawn(
        address indexed recipient,
        uint256 amount,
        uint64 timestamp
    );

    uint64 public totalGames;
    uint256 public devFeeVault;
    bool public paused;

    mapping(uint64 => GameSession) public games;
    mapping(address => PowerupInventory) public inventories;
    mapping(address => uint64[]) public playerGames;

    modifier notPaused() {
        if (paused) revert GameplayPaused();
        _;
    }

    modifier gameExists(uint64 gameId) {
        if (games[gameId].gameId == 0) revert GameNotFound();
        _;
    }

    constructor() Ownable(msg.sender) {
        totalGames = 0;
        paused = false;
    }

    function createGame() external payable notPaused nonReentrant {
        if (msg.value == 0) revert InvalidAmount();
        uint64 gameId = ++totalGames;
        games[gameId] = GameSession({
            gameId: gameId,
            player1: msg.sender,
            player2: address(0),
            stakeAmount: msg.value,
            escrowBalance: msg.value,
            status: WAITING_STATUS,
            winner: address(0),
            createdAt: uint64(block.timestamp),
            completedAt: 0
        });

        playerGames[msg.sender].push(gameId);

        emit GameCreated(
            gameId,
            msg.sender,
            msg.value,
            uint64(block.timestamp),
            WAITING_STATUS
        );
    }

    function joinGame(uint64 gameId)
        external
        payable
        notPaused
        nonReentrant
        gameExists(gameId)
    {
        GameSession storage game = games[gameId];

        if (game.status != WAITING_STATUS) revert InvalidStatus();
        if (msg.sender == game.player1) revert CannotJoinOwnGame();
        if (game.player2 != address(0)) revert Player2SlotNotEmpty();
        if (msg.value != game.stakeAmount) revert InvalidAmount();

        game.player2 = msg.sender;
        game.escrowBalance += msg.value;
        game.status = ACTIVE_STATUS;

        playerGames[msg.sender].push(gameId);

        emit GameJoined(gameId, msg.sender, msg.value, uint64(block.timestamp));
    }

    function endGame(uint64 gameId, address winner)
        external
        onlyOwner
        notPaused
        nonReentrant
        gameExists(gameId)
    {
        GameSession storage game = games[gameId];

        if (game.status != ACTIVE_STATUS) revert InvalidStatus();
        if (game.player2 == address(0)) revert Player2NotJoined();
        if (winner != game.player1 && winner != game.player2) revert Unauthorized();
        if (game.escrowBalance == 0) revert InsufficientBalance();

        uint256 totalBalance = game.escrowBalance;
        uint256 devFee = (totalBalance * DEV_FEE_PERCENTAGE) / 100;
        uint256 winnerAmount = totalBalance - devFee;

        devFeeVault += devFee;
        game.escrowBalance = 0;
        game.status = ENDED_STATUS;
        game.winner = winner;
        game.completedAt = uint64(block.timestamp);

        address loser = winner == game.player1 ? game.player2 : game.player1;

        // Transfer winnings to winner
        (bool success, ) = winner.call{value: winnerAmount}("");
        if (!success) revert TransferFailed();

        emit GameEnded(gameId, winner, loser, winnerAmount, devFee, game.completedAt);
    }

    function requestRefund(uint64 gameId)
        external
        notPaused
        nonReentrant
        gameExists(gameId)
    {
        GameSession storage game = games[gameId];

        if (game.status != WAITING_STATUS) revert InvalidStatus();
        if (msg.sender != game.player1) revert Unauthorized();

        uint256 refundAmount = game.escrowBalance;
        if (refundAmount == 0) revert InvalidAmount();

        game.escrowBalance = 0;
        game.status = CANCELLED_STATUS;
        game.completedAt = uint64(block.timestamp);

        // Transfer refund to player
        (bool success, ) = msg.sender.call{value: refundAmount}("");
        if (!success) revert TransferFailed();

        emit RefundClaimed(gameId, msg.sender, refundAmount, game.completedAt);
    }

    // ============ Powerup Management ============
    function grantPowerup(address recipient, uint8 powerupType)
        external
        onlyOwner
    {
        if (powerupType < 1 || powerupType > 3) revert InvalidPowerupType();

        PowerupInventory storage inventory = inventories[recipient];

        if (powerupType == POWERUP_PAD_STRETCH) {
            inventory.padStretchCount++;
        } else if (powerupType == POWERUP_MULTIBALL) {
            inventory.multiballCount++;
        } else {
            inventory.shieldCount++;
        }

        emit PowerupGranted(
            recipient,
            powerupType,
            getPowerupCount(recipient, powerupType),
            uint64(block.timestamp)
        );
    }

    function usePowerup(uint64 gameId, uint8 powerupType)
        external
        notPaused
        gameExists(gameId)
    {
        GameSession storage game = games[gameId];

        if (game.status != ACTIVE_STATUS) revert InvalidStatus();
        if (powerupType < 1 || powerupType > 3) revert InvalidPowerupType();

        PowerupInventory storage inventory = inventories[msg.sender];

        if (powerupType == POWERUP_PAD_STRETCH) {
            if (inventory.padStretchCount == 0) revert InsufficientPowerups();
            inventory.padStretchCount--;
        } else if (powerupType == POWERUP_MULTIBALL) {
            if (inventory.multiballCount == 0) revert InsufficientPowerups();
            inventory.multiballCount--;
        } else if (powerupType == POWERUP_SHIELD) {
            if (inventory.shieldCount == 0) revert InsufficientPowerups();
            inventory.shieldCount--;
        }

        emit PowerupUsed(gameId, msg.sender, powerupType, uint64(block.timestamp));
    }

    // ============ Admin Functions ============
    function withdrawDevFees() external onlyOwner nonReentrant {
        uint256 feeAmount = devFeeVault;
        if (feeAmount == 0) revert InvalidAmount();

        devFeeVault = 0;

        (bool success, ) = owner().call{value: feeAmount}("");
        if (!success) revert TransferFailed();

        emit FeeWithdrawn(owner(), feeAmount, uint64(block.timestamp));
    }

    function togglePause() external onlyOwner {
        paused = !paused;
        emit VaultPauseToggled(paused, msg.sender, uint64(block.timestamp));
    }

    // ============ View Functions ============
    function getGame(uint64 gameId)
        external
        view
        gameExists(gameId)
        returns (GameSession memory)
    {
        return games[gameId];
    }

    function getGameStatus(uint64 gameId)
        external
        view
        gameExists(gameId)
        returns (uint8)
    {
        return games[gameId].status;
    }

    function getGameEscrow(uint64 gameId)
        external
        view
        gameExists(gameId)
        returns (uint256)
    {
        return games[gameId].escrowBalance;
    }

    function getDevFees() external view returns (uint256) {
        return devFeeVault;
    }

    function isVaultPaused() external view returns (bool) {
        return paused;
    }

    function getTotalGames() external view returns (uint64) {
        return totalGames;
    }

    function getPowerupCount(address player, uint8 powerupType)
        public
        view
        returns (uint64)
    {
        PowerupInventory storage inventory = inventories[player];

        if (powerupType == POWERUP_PAD_STRETCH) {
            return inventory.padStretchCount;
        } else if (powerupType == POWERUP_MULTIBALL) {
            return inventory.multiballCount;
        } else if (powerupType == POWERUP_SHIELD) {
            return inventory.shieldCount;
        }
        return 0;
    }

    function getAllPowerups(address player)
        external
        view
        returns (
            uint64 padStretch,
            uint64 multiball,
            uint64 shield
        )
    {
        PowerupInventory storage inventory = inventories[player];
        return (
            inventory.padStretchCount,
            inventory.multiballCount,
            inventory.shieldCount
        );
    }

    function getPlayerGames(address player)
        external
        view
        returns (uint64[] memory)
    {
        return playerGames[player];
    }

    function getPlayerGameCount(address player)
        external
        view
        returns (uint256)
    {
        return playerGames[player].length;
    }

    receive() external payable {
        revert("Use createGame() to participate");
    }
}