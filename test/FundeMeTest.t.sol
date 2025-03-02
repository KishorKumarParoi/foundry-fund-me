// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../src/FundMe.sol";

contract FundmeTest is Test {
    uint256 number = 1;
    FundMe fundme;

    function setUp() external {
        number = 100;
        fundme = new FundMe(address(0));
    }

    function testDemo() public view {
        console.log("Hello World");
        console.log("Number is: ", number);
        assertEq(number, 100);
        assertEq(fundme.MINIMUM_USD(), 5 * 10 ** 18);
    }

    function testOwnerIsMsgSender() public view {
        console.log(fundme.i_owner());
        console.log(msg.sender);
        assertEq(fundme.i_owner(), address(this));
    }

    function testPriceFeedVersionIsAccurate() public view {
        uint256 version = fundme.getVersion();
        console.log(version);
        assertEq(version, 5);
    }
}
