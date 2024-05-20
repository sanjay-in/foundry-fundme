// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../src/FundMe.sol";
import {DeployFundMe} from "../script/DeployFundMe.s.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;
    HelperConfig public helperConfig;

    string public constant USER = "user";
    address public user = makeAddr(USER);
    uint256 public constant INITIAL_FUND = 10 ether;
    uint256 public constant SEND_ETH = 10 ether;

    function setUp() external {
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(user, INITIAL_FUND);
    }

    function testMinimumUSD() public view {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerOfContract() public view {
        assertEq(fundMe.i_owner(), msg.sender);
    }

    function testFundWithoutEth() public {
        vm.expectRevert();
        fundMe.fund();
    }

    function testPriceFeedSetCorrectly() public {
        address retreivedPriceFeed = address(fundMe.getPriceFeed());
        address expectedPriceFeed = helperConfig.activeNetworkConfig();
        assertEq(retreivedPriceFeed, expectedPriceFeed);
    }

    function testFundAddress() public {
        vm.startPrank(user);
        fundMe.fund{value: SEND_ETH}();
        vm.stopPrank();

        address[] memory lastUser = fundMe.getUserAddresses();
        assertEq(user, lastUser[0]);
    }

    function testFundedAmount() public {
        vm.startPrank(user);
        fundMe.fund{value: SEND_ETH}();
        vm.stopPrank();

        uint256 fundedAmount = fundMe.getUserFundedAmount(user);
        assertEq(fundedAmount, SEND_ETH);
    }

    function testWithdrawNotAsAOwner() public {
        vm.startPrank(user);
        fundMe.fund{value: SEND_ETH}();

        vm.expectRevert();
        fundMe.withdraw();
        vm.stopPrank();
    }

    function testWithdraw() public {
        vm.startPrank(user);
        fundMe.fund{value: SEND_ETH}();
        vm.stopPrank();
        uint256 startingFundMeBalance = address(fundMe).balance;
        uint256 startingOwnerBalance = fundMe.getOwner().balance;

        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        uint256 endingFundMeBalance = address(fundMe).balance;
        uint256 endingOwnerBalance = fundMe.getOwner().balance;

        assertEq(endingFundMeBalance, 0);
        assertEq(
            endingOwnerBalance,
            startingOwnerBalance + startingFundMeBalance
        );
    }

    function testWithdrawFromMultipleFunders() public {
        uint160 funderIndex = 1;
        for (uint160 i = funderIndex; i < 10; i++) {
            hoax(address(i), INITIAL_FUND);
            fundMe.fund{value: SEND_ETH}();
        }
        uint256 startingFundMeBalance = address(fundMe).balance;
        uint256 startingOwnerBalance = fundMe.getOwner().balance;

        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        uint256 endingFundMeBalance = address(fundMe).balance;
        uint256 endingOwnerBalance = fundMe.getOwner().balance;

        assert(address(fundMe).balance == 0);
        assert(
            startingFundMeBalance + startingOwnerBalance ==
                fundMe.getOwner().balance
        );
        assert(
            9 * SEND_ETH == fundMe.getOwner().balance - startingOwnerBalance
        );
    }
}
