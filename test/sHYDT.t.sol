// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";

import {Earn} from "../src/Earn.sol";
import {sHYDT} from "../src/sHYDT.sol";

contract sHYDTtest is Test {
    Earn public earn;
    sHYDT public shydt;

    function setUp() public {
        earn = new Earn();
        shydt = new sHYDT();
    }

    function test_Initialize() public {
        shydt.initialize(address(earn));
        assertTrue(shydt.hasRole(shydt.CALLER_ROLE(), address(earn)));
        assertTrue(shydt.hasRole(shydt.DEFAULT_ADMIN_ROLE(), address(this)));
    }

    function test_Initialize_Revert_EarnZeroAddress() public {
        vm.expectRevert("sHYDT: invalid Earn address");
        shydt.initialize(address(0));
    }

    function test_Initialize_Revert_UsingNonInitializer() public {
        vm.expectRevert("sHYDT: caller is not the initializer");
        vm.prank(address(earn));
        shydt.initialize(address(earn));
    }

    function test_Mint() public {
        shydt.initialize(address(earn));
        vm.prank(address(earn));
        bool success = shydt.mint(address(this), 1000e18);
        assertTrue(success);
    }

    function test_Mint_Revert() public {
        shydt.initialize(address(earn));
        vm.prank(address(123123));
        vm.expectRevert(
            "AccessControl: account 0x000000000000000000000000000000000001e0f3 is missing role 0x19efed7511dad497f336fbaa05740ad432d42bb8e64228479f57ef6936bb2a9c"
        );
        shydt.mint(address(this), 1000e18);
    }

    function test_Burn() public {
        shydt.initialize(address(earn));
        vm.startPrank(address(earn));
        bool success = shydt.mint(address(this), 1000e18);
        assertTrue(success);
        vm.stopPrank();
        bool done = shydt.burn(100e18);
        assertTrue(done);
    }

    function test_BurnFrom() public {
        shydt.initialize(address(earn));
        vm.startPrank(address(earn));
        bool success = shydt.mint(address(this), 1000e18);
        assertTrue(success);
        vm.stopPrank();
        shydt.approve(address(earn), 1000e18);
        vm.prank(address(earn));
        bool done = shydt.burnFrom(address(this), 100e18);
        assertTrue(done);
    }
}
