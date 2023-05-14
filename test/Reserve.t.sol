// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import {Control} from "../src/Control.sol";
import {Reserve} from "../src/Reserve.sol";

contract ReserveTest is Test {
    Control public control;
    Reserve public reserve;

    // Invoked before each test
    function setUp() public {
        reserve = new Reserve();
        control = new Control();
    }

    function test_Initialize ( ) public {
        reserve.initialize(address(control));
        assertTrue(true);
    }
    
    function test_Initialize_RevertOn_NonInitializer ( ) public {
        vm.prank(address(0));
        vm.expectRevert("Reserve: caller is not the initializer");
        reserve.initialize(address(control));
    }

    function test_Initialize_RevertOn_ControlZeroAddress( ) public {
        vm.expectRevert("Reserve: invalid Control address");
        reserve.initialize(address(0));
    }

    function test_Withdraw (uint amount ) public {
         
        reserve.initialize(address(control));
        vm.expectRevert("AccessControl: account 0x7fa9385be102ac3eac297483dd6233d62b3e1496 is missing role 0x19efed7511dad497f336fbaa05740ad432d42bb8e64228479f57ef6936bb2a9c");
        reserve.withdraw( amount);
    }
}
