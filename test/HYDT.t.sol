// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import {Control} from "../src/Control.sol";
import {HYDT} from "../src/HYDT.sol";
import {Reserve} from "../src/Reserve.sol";
import {Earn} from "../src/Earn.sol";
import {Farm} from "../src/Farm.sol";

contract HYDTTest is Test {
    Control public control;
    HYDT public hydt;
    Reserve public reserve;
    Earn public earn;
    Farm public farm;

    function setUp() public {
        reserve = new Reserve();
        control = new Control();
        hydt = new HYDT(address(reserve));
        earn = new Earn();
        farm = new Farm();
    }

    function test_Initialize() public {
        hydt.initialize(address(control), address(earn));
        assertTrue(hydt.hasRole(hydt.CALLER_ROLE(), address(control)));
        assertTrue(hydt.hasRole(hydt.CALLER_ROLE(), address(earn)));
        assertTrue(hydt.hasRole(hydt.DEFAULT_ADMIN_ROLE(), address(this)));
    }

    function test_Initialize_Revert_UsingNonInitializer() public {
        vm.prank(address(123));
        vm.expectRevert("HYDT: caller is not the initializer");
        hydt.initialize(address(control), address(earn));
    }

    function test_Initialize_Revert_ControlZeroAddress() public {
        vm.expectRevert("HYDT: invalid Control address");
        hydt.initialize(address(0), address(earn));
    }

    function test_Initialize_Revert_EarnZeroAddress() public {
        vm.expectRevert("HYDT: invalid Earn address");
        hydt.initialize(address(control), address(0));
    }

    function test_Mint() public {
        hydt.initialize(address(control), address(earn));
        vm.prank(address(earn));
        bool success = hydt.mint(address(this), 1000e18);
        assertTrue(success);
    }

    function test_Mint_Revert() public {
        hydt.initialize(address(control), address(earn));
        vm.prank(address(farm));
        vm.expectRevert(
            "AccessControl: account 0xc7183455a4c133ae270771860664b6b7ec320bb1 is missing role 0x19efed7511dad497f336fbaa05740ad432d42bb8e64228479f57ef6936bb2a9c"
        );
        hydt.mint(address(this), 1000e18);
    }

    function test_Burn() public {
        hydt.initialize(address(control), address(earn));
        vm.prank(address(earn));
        bool success = hydt.mint(address(earn), 1000e18);
        assertTrue(success);
        bool done = hydt.burn(100e18);
        assertTrue(done);
    }

    function test_BurnFrom() public {
        hydt.initialize(address(control), address(earn));
        vm.startPrank(address(earn));
        bool success = hydt.mint(address(this), 1000e18);
        assertTrue(success);
        vm.stopPrank();
        hydt.approve(address(earn), 1000e18);
        // vm.prank(address(wbnb));
        vm.prank(address(earn));
        bool done = hydt.burnFrom(address(this), 100e18);
        assertTrue(done);
    }

    function test_BurnFrom_Revert() public {
        hydt.initialize(address(control), address(earn));
        vm.startPrank(address(earn));
        bool success = hydt.mint(address(this), 1000e18);
        assertTrue(success);
        vm.stopPrank();
        hydt.approve(address(earn), 1000e18);
        // vm.prank(address(wbnb));
        vm.prank(address(123456));
        vm.expectRevert(
            "AccessControl: account 0x000000000000000000000000000000000001e240 is missing role 0x19efed7511dad497f336fbaa05740ad432d42bb8e64228479f57ef6936bb2a9c"
        );
        hydt.burnFrom(address(this), 100e18);
    }
}
