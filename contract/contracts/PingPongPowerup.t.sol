// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "./PingPong.sol";

contract PingPongPowerupTest is Test {
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

    function testGrantPowerupInvalidTypeFails() public {
        vm.expectRevert(PingPong.InvalidPowerupType.selector);
        pong.grantPowerup(alice, 4);
    }

    function testGrantPowerupNullAddressFails() public {
        vm.expectRevert(PingPong.InvalidAmount.selector);
        pong.grantPowerup(address(0), 1);
    }

    function testGrantPowerupMultipleTimes() public {
        pong.grantPowerup(alice, 1);
        pong.grantPowerup(alice, 1);
        pong.grantPowerup(alice, 1);
        assertEq(pong.getPowerupCount(alice, 1), 3);
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

    function testUsePowerupWithoutInventoryFails() public {
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        vm.prank(bob);
        pong.joinGame{value: STAKE}(1);
        
        vm.prank(alice);
        vm.expectRevert(PingPong.InsufficientPowerups.selector);
        pong.usePowerup(1, 1);
    }

    function testUsePowerupNonParticipantFails() public {
        pong.grantPowerup(alice, 1);
        
        vm.prank(alice);
        pong.createGame{value: STAKE}();
        
        vm.prank(bob);
        pong.joinGame{value: STAKE}(1);
        
        vm.prank(carol);
        vm.expectRevert(PingPong.NotGameParticipant.selector);
        pong.usePowerup(1, 1);
    }

    function testGrantPowerupNonOwnerFails() public {
        vm.prank(alice);
        vm.expectRevert();
        pong.grantPowerup(alice, 1);
    }
}
