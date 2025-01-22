// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {DeployOurToken} from "script/DeployOurToken.s.sol";
import {OurToken} from "src/OurToken.sol";

contract OurTokenTests is Test {
    OurToken public ourToken;
    DeployOurToken public deployer;

    address bob = makeAddr("bob");
    address alice = makeAddr("alice");

    uint256 public constant STARTING_BALANCE = 100 ether;
    uint256 public initialSupply;

    function setUp() public {
        deployer = new DeployOurToken();
        ourToken = deployer.run();

        initialSupply = deployer.INITIAL_TOKEN_SUPPLY();
    }

    function testBobBalance() public {
        vm.prank(msg.sender);
        ourToken.transfer(bob, STARTING_BALANCE);

        assertEq(STARTING_BALANCE, ourToken.balanceOf(bob));
    }

    function testAllowancesWorks() public {
        uint256 initialAllowance = 1000;

        vm.prank(msg.sender);
        ourToken.transfer(bob, STARTING_BALANCE);

        // Bob approves Alice to spend tokens on his behalf
        vm.prank(bob);
        ourToken.approve(alice, initialAllowance);

        uint256 transferAmount = 500;

        vm.prank(alice);
        ourToken.transferFrom(bob, alice, transferAmount);

        assertEq(ourToken.balanceOf(alice), transferAmount);
        assertEq(ourToken.balanceOf(bob), STARTING_BALANCE - transferAmount);
    }

    function testTransferFromExceedsAllowance() public {
        uint256 allowanceAmount = 50;
        uint256 transferAmount = 100;

        ourToken.approve(bob, allowanceAmount);

        vm.expectRevert();
        ourToken.transferFrom(bob, alice, transferAmount);
    }

    function testTransfer() public {
        uint256 amount = 1000;
        address receiver = address(0x1);
        vm.prank(msg.sender);
        ourToken.transfer(receiver, amount);
        assertEq(ourToken.balanceOf(receiver), amount);
    }

    function testBalanceAfterTransfer() public {
        uint256 amount = 1000;
        address receiver = address(0x1);
        uint256 initialBalance = ourToken.balanceOf(msg.sender);
        vm.prank(msg.sender);
        ourToken.transfer(receiver, amount);
        assertEq(ourToken.balanceOf(msg.sender), initialBalance - amount);
    }

    function testTransferFrom() public {
        uint256 amount = 1000;
        address receiver = address(0x1);
        vm.prank(msg.sender);
        ourToken.approve(address(this), amount);
        ourToken.transferFrom(msg.sender, receiver, amount);
        assertEq(ourToken.balanceOf(receiver), amount);
    }

    function testInitialSupply() public view {
        assertEq(ourToken.totalSupply(), initialSupply);
        assertEq(ourToken.balanceOf(msg.sender), initialSupply);
    }

    function testTransferExceedsBalance() public {
        uint256 transferAmount = initialSupply + 1;

        // Attempting to transfer more than the available balance should fail
        vm.expectRevert();
        ourToken.transfer(bob, transferAmount);
    }
}
