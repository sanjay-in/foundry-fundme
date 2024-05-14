// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../src/FundMe.sol";

contract FundMeTest is Test {
    FundMe fundMe;

    function setUp() external {
        fundMe = new FundMe();
    }

    function testMinimumUSD() public view {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerOfContract() public view {
        assertEq(fundMe.i_owner(), address(this));
    }

    // function testEthPrice() public view {

    // }
}
