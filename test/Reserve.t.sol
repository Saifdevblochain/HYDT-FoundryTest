// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import {Control} from "../src/Control.sol";
import {Reserve} from "../src/Reserve.sol";
import {WBNB} from "../src/WBNB.sol";

contract ControlTest is Test {
    uint256 initialMintStartTime_ = uint256(block.timestamp);
    Control public control;
    Reserve public reserve;
    WBNB public wbnb;

    // Invoked before each test
    function setUp() public {
        reserve = new Reserve();
        control = new Control();
        wbnb = new WBNB();
    }

    function test_Initialize ( ) public {
        reserve.initialize(address(control));
        assertTrue(true);
    }
    
    function test_InitializeWithZeroAddress ( ) public {
        vm.prank(address(0));
        vm.expectRevert();
        reserve.initialize(address(control));
    }

    function test_InitializeWithControlZero ( ) public {
        address control_= address(0);
        vm.expectRevert();
        reserve.initialize(control_);
    }

    function test_Withdraw (uint amount ) public {
         
        reserve.initialize(address(control));
        vm.expectRevert();
        reserve.withdraw( amount);
    }
}
