// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "./PingPong.sol";

contract PingPongDeploymentTest is Test {
    PingPong pong;
    address owner = address(this);

    function setUp() public {
        pong = new PingPong();
    }

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
}
