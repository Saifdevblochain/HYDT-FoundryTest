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


contract HYDTTest is Test {
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
        hygt = new HYGT(address(0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496), address(reserve));
    }
 

    function test_Initialize() public {
        hydt.initialize( address(control), address(earn) ) ;
        assertTrue(hydt.hasRole(hydt.CALLER_ROLE(), address(control)));
        assertTrue(hydt.hasRole(hydt.CALLER_ROLE(), address(earn)));
        assertTrue(hydt.hasRole(hydt.DEFAULT_ADMIN_ROLE(), address(this)));
    }

    function test_InitializeWithRandomAddress() public {
        vm.prank(address(123));
        vm.expectRevert("HYDT: caller is not the initializer");
        hydt.initialize( address(control), address(earn) ) ;
    }

    function test_InitializeWithContorlAddressZero() public {
        vm.expectRevert("HYDT: invalid Control address");
        hydt.initialize( address(0), address(earn) ) ;
    }

    function test_InitializeWithHYGTAddressZero() public {
        uint initialMintTime = uint (block.timestamp);
        vm.expectRevert("HYDT: invalid Earn address");
        hydt.initialize( address(control), address(0) ) ;
    }

    function test_mintFunctionFail() public {
        hydt.initialize( address(control), address(earn) ) ;
        vm.prank(address(farm));
        vm.expectRevert("AccessControl: account 0x1d1499e622d69689cdf9004d05ec547d650ff211 is missing role 0x19efed7511dad497f336fbaa05740ad432d42bb8e64228479f57ef6936bb2a9c");
        hydt.mint( address(this),  1000e18);
    }

    function test_mintFunction() public {
        hydt.initialize( address(control), address(earn) ) ;
        vm.prank(address(earn));
        bool success = hydt.mint( address(this),  1000e18);
        assertTrue( success);
    }

    function test_Burn() public {
        hydt.initialize( address(control), address(earn) ) ;
        vm.prank(address(earn));
        bool success = hydt.mint( address(earn),  1000e18);
        assertTrue( success);
        bool done = hydt.burn(100e18);
        assertTrue( done);
    }

    function test_BurnFrom () public {

        hydt.initialize( address(control), address(earn) ) ;
        vm.startPrank(address(earn));
        bool success = hydt.mint( address(this),  1000e18);
        vm.stopPrank();

        hydt.approve(address(earn), 1000e18);

        // vm.prank(address(wbnb));
        vm.prank(address(earn));
        bool done = hydt.burnFrom(address(this),100e18);
        assertTrue( done);
    }


}