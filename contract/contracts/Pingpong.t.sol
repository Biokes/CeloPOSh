// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {PingPong} from "./PingPong.sol";
import {console} from "forge-std/Console.sol";

contract PingpongTest is Test{
    PingPong pong;
    address deployer = address(1);
    function setUp() public {
        pong = new PingPong();
    }

    function testGameCanBeCreated() public{
        address user = address(2);
        vm.startPrank(user);
        pong.createNewGame(0);
        assert(pong.getUserActiveGame(user).length ==0,"invalid assertion");
    }

}