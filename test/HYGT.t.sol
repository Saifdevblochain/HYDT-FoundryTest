// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import {Control} from "../src/Control.sol";
import {HYDT} from "../src/HYDT.sol";
import {HYGT} from "../src/HYGT.sol";
import {Reserve} from "../src/Reserve.sol";
import {WBNB} from "../src/WBNB.sol";
// import {IERC20} from "../src/interfaces/IERC20.sol";
import {Earn} from "../src/Earn.sol";
import {sHYDT} from "../src/sHYDT.sol";
import {Farm} from "../src/Farm.sol";

contract HYGTtest is Test {
    Control public control;
    HYDT public hydt;
    HYGT public hygt;
    Reserve public reserve;
    WBNB public wbnb;
    Earn public earn;
    sHYDT public shydt;
    Farm public farm;

    function setUp() public {
        reserve = new Reserve();
        control = new Control();
        hydt = new HYDT(address(reserve));
        wbnb = new WBNB();
        earn = new Earn();
        shydt = new sHYDT();
        farm = new Farm();
        hygt = new HYGT(
            address(0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496),
            address(reserve)
        );
    }

    function test_Initialize() public {
        hygt.initialize(address(earn), address(farm));
        assertTrue(hygt.hasRole(hygt.CALLER_ROLE(), address(farm)));
        assertTrue(hygt.hasRole(hygt.CALLER_ROLE(), address(earn)));
        assertEq(hygt.maxSupply(),1000000000e18);
    }

    function test_Initialize_RevertOn_NonInitializer() public {
        vm.prank(address(wbnb));
        vm.expectRevert("HYGT: caller is not the initializer");
        hygt.initialize(address(earn), address(farm));
    }

    function test_Initialize_RevertOn_EarnZeroAddress() public {
        vm.expectRevert("HYGT: invalid Earn address");
        hygt.initialize(address(0), address(farm));
    }

    function test_Initialize_RevertOn_FarmZeroAddress() public {
        vm.expectRevert("HYGT: invalid Farm address");
        hygt.initialize(address(earn), address(0));
    }

    function test_mint() public {
        hygt.initialize(address(earn), address(farm));
        vm.prank(address(earn));
        bool success = hygt.mint(address(123), 100e18);
        assertTrue(success);
    }

    function test_mint_RevertOn_NonCallerRole() public {
        hygt.initialize(address(earn), address(farm));
        vm.prank(address(1234));
        vm.expectRevert("AccessControl: account 0x00000000000000000000000000000000000004d2 is missing role 0x19efed7511dad497f336fbaa05740ad432d42bb8e64228479f57ef6936bb2a9c");
        hygt.mint(address(123), 100e18);
    }

    function test_mint_RevertOn_GreateThancallerMaxSupply() public {
        test_Initialize();
        vm.prank(address(earn));
        vm.expectRevert("HYGT: invalid amount considering caller max supply");
        hygt.mint(address(farm), 1000000000e18);
    }

    function test_burn() public {
        hygt.initialize(address(earn), address(farm));
        vm.prank(address(earn));
        bool success = hygt.mint(address(this), 1000e18);
        assertTrue(success);
        bool done = hygt.burn(1000e18);
        assertTrue(done);
    }

    function test_BurnFrom() public {
        hygt.initialize(address(earn), address(farm));
        vm.startPrank(address(earn));
        bool success = hygt.mint(address(this), 1000e18);
        assertTrue(success);
        vm.stopPrank();
        hygt.approve(address(earn), 1000e18);
        vm.prank(address(earn));
        bool done = hygt.burnFrom(address(this), 100e18);
        assertTrue(done);
    }

    function test_BurnFrom_RevertOn_NonCalleRole() public {
        hygt.initialize(address(earn), address(farm));
        vm.startPrank(address(earn));
        bool success = hygt.mint(address(this), 1000e18);
        assertTrue(success);
        vm.stopPrank();
        hygt.approve(address(earn), 1000e18);
        vm.prank(address(12345));
        vm.expectRevert("AccessControl: account 0x0000000000000000000000000000000000003039 is missing role 0x19efed7511dad497f336fbaa05740ad432d42bb8e64228479f57ef6936bb2a9c");
        bool done = hygt.burnFrom(address(this), 100e18);
        assertFalse(done);
    }

    function test_unLock_RevertOn_NonCallerRole() public{
        hygt.initialize(address(earn), address(farm));
        vm.prank(address(1234));
        vm.expectRevert("AccessControl: account 0x00000000000000000000000000000000000004d2 is missing role 0x0e87e1788ebd9ed6a7e63c70a374cd3283e41cad601d21fbe27863899ed4a709");
        hygt.unlock();
    }

    function test_unLock_RevertWhen_NoIntervalsPassed() public{
        hygt.initialize(address(earn), address(farm));
        vm.expectRevert("HYGT: no intervals have passed yet");
        hygt.unlock();
    }

    function test_unLock_AfterOneInterval() public{
        hygt.initialize(address(earn), address(farm));
        uint balanceBefore = hygt.balanceOf(address(this));
        vm.warp(61);
        hygt.unlock();
        uint balanceAfter = hygt.balanceOf(address(this));
        (,
        ,
        uint256 unlockedAmount,
        ,
        ,
        ,)= hygt.lockups(address(this));
        uint expected = balanceAfter-balanceBefore;
        assertEq(expected, unlockedAmount);
    }

    function test_unLock_AfterAllIntervals() public{
        hygt.initialize(address(earn), address(farm));
        uint balanceBefore = hygt.balanceOf(address(this));
        vm.warp(8000);
        hygt.unlock();
        uint balanceAfter = hygt.balanceOf(address(this));
        (,
        ,
        uint256 unlockedAmount,
        ,
        ,
        ,)= hygt.lockups(address(this));
        uint expected = balanceAfter-balanceBefore;
        assertEq(expected, unlockedAmount);
        (bool status,,,,,,)= hygt.lockups(address(this));
        assertFalse(status);
    }

    function test_delegate() public{
        hygt.initialize(address(earn), address(farm));
        hygt.mint(address(this),100000e18);
        uint bn= block.number+5;
        uint balanceOf= hygt.balanceOf(address(this));
        vm.roll(bn);
        hygt.delegate(address(this));
        vm.roll(block.number+5);
        uint256 votesPrior= hygt.getPriorVotes( address(this),  bn);
        assertEq(balanceOf,votesPrior);
        uint currentvotes= hygt.getCurrentVotes( address(this) );
        assertEq(balanceOf,currentvotes);
        vm.roll(100);
        hygt.transfer(address(2), 10e18) ;
        vm.prank(address(2));
        hygt.delegate(address(2)) ;
        vm.roll(104);
        uint256 votesNow= hygt.getPriorVotes( address(2),  100);
        uint256 currentvotesNow= hygt.getCurrentVotes( address(2) );
        assertEq(votesNow, 10e18);
        assertEq(currentvotesNow, 10e18);
    }

    function test_delegate_2() public{
        hygt.initialize(address(earn), address(farm));
        hygt.mint(address(123), 28);
        uint balanceThis = hygt.balanceOf(address(this));
        uint balance123 = hygt.balanceOf(address(123));
        vm.roll(5);
        hygt.delegate(address(this));
        vm.roll(10);
        assertEq(balanceThis, hygt.getCurrentVotes( address(this) ));
        vm.startPrank(address(123));
        hygt.delegate(address(123));
        vm.roll(15);
        assertEq(balance123, hygt.getCurrentVotes( address(123) ));
        hygt.transfer(address(this), 14);
        vm.roll(20);

        console.log(" ---Current Votes shold be 46||",hygt.getCurrentVotes( address(this) ));
        assertEq(hygt.getCurrentVotes( address(this) ), 46);
        console.log("balance of This--- 46",hygt.balanceOf(address(this)));
        assertEq(hygt.balanceOf( address(this) ), 46);
        console.log("123-- CurrentVotes 14||",hygt.getCurrentVotes( address(123) ));
        assertEq(hygt.getCurrentVotes( address(123) ), 14);
        console.log("balance of 123---",hygt.balanceOf(address(123)));
        assertEq(hygt.balanceOf( address(123) ), 14);
        vm.stopPrank();
    }

    function test_delegate_3() public{
        hygt.initialize(address(earn), address(farm));
        vm.roll(5);
        hygt.delegate(address(this));
        uint expected = hygt.getPriorVotes( address(this), 4 );
        assertEq(expected ,0);
        console.log("expected -----",expected);
        console.log("numcheckpoints---",hygt.numCheckpoints(address(this)));
    }

    function test_delegate_4() public{
        hygt.initialize( address(earn), address(farm));
        hygt.mint(address(this), 100e18);
        vm.roll(5);
        hygt.delegate(address(1234));
        vm.roll(10);
        hygt.mint(address(this), 100e18);
        hygt.delegate(address(1234));
        vm.roll(15);
        hygt.mint(address(this), 100e18);
        hygt.delegate(address(1234));
        vm.roll(20);
        assertEq(hygt.getPriorVotes(address(1234), 10),200000000000000000032);
    }

    function test_delegate_5() public{
        hygt.initialize( address(earn), address(farm));
        hygt.mint(address(this), 100e18);
        vm.roll(5);
        hygt.delegate(address(1234));
        vm.roll(10);
        hygt.mint(address(this), 100e18);
        hygt.delegate(address(1234));
        vm.roll(15);
        hygt.mint(address(this), 100e18);
        hygt.delegate(address(1234));
        vm.roll(20);
        hygt.mint(address(this), 100e18);
        hygt.delegate(address(1234));
        vm.roll(25);
        hygt.mint(address(this), 100e18);
        hygt.delegate(address(1234));
        vm.roll(30);
        uint result= hygt.getPriorVotes(address(1234), 24);
        assertEq(result, 400000000000000000032);
    }

    function test_delegate_6() public{
        hygt.initialize(address(earn), address(farm));
        vm.roll(5);
        uint expected = hygt.getPriorVotes( address(this), 4 );
        assertEq(expected ,0);
    }

    function test_delegate_7() public{
        hygt.initialize( address(earn), address(farm));
        hygt.mint(address(this), 100e18);
        vm.roll(5);
        hygt.delegate(address(1234));
        vm.roll(10);
        hygt.mint(address(this), 100e18);
        hygt.delegate(address(1234));
        hygt.mint(address(this), 100e18);
        hygt.delegate(address(1234));
        uint max= hygt.numCheckpoints(address(1234));
        (, uint votes )=hygt.checkpoints(address(1234),max-1);
        assertEq(votes,300000000000000000032);
    }

    // function test_PriorVotes_OnDelegate() public {
    //     hygt.initialize(address(earn), address(farm));
    //     hygt.delegate( address(123));
    //     uint expected = hygt.getCurrentVotes(address(123));
    //     console.log("expected------",expected);
    // }


    //delegate
}
