// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../src/FundMe.sol";
import {MockV3Aggregator} from "./MockV3Aggregator.sol";

contract FundmeTest is Test {
    uint256 number = 1;
    FundMe fundme;
    MockV3Aggregator mockV3Aggregator;

    function setUp() external {
        number = 100;
        mockV3Aggregator = new MockV3Aggregator(4); // Initialize with version 4
        fundme = new FundMe(address(mockV3Aggregator));
    }

    function testDemo() public view {
        console.log("Hello World");
        console.log("Number is: ", number);
        assertEq(number, 100);
        assertEq(fundme.MINIMUM_USD(), 5 * 10 ** 18);
    }

    function testOwnerIsMsgSender() public view {
        console.log("Owner: ", fundme.i_owner());
        console.log("msg.sender: ", msg.sender);
        console.log("Address: ", address(this));
        assertEq(fundme.i_owner(), address(this));
    }

    function testPriceFeedVersionIsAccurate() public view {
        uint256 version = fundme.getVersion();
        console.log("Price Feed Version: ", version);
        assertEq(version, 4);
    }
}
