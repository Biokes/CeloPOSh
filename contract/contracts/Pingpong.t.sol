// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {Pingpong} from "./PingPong.sol";


contract PingpongTest is Test{
    PingPong pong;

    function setUp() public {
        pong = new Pong();
    }
}