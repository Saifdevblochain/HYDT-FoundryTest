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
        hygt.initialize( address(earn), address(farm) ) ;
        assertTrue(hygt.hasRole(hygt.CALLER_ROLE(), address(farm)));
        assertTrue(hygt.hasRole(hygt.CALLER_ROLE(), address(earn)));
    }

    function test_InitializeWithNotInitializer() public {
        vm.prank(address(wbnb));
        vm.expectRevert("HYGT: caller is not the initializer");
        hygt.initialize( address(earn), address(farm) ) ;
    }

    function test_Initialize_EarnZeroAddress() public {
        vm.expectRevert("HYGT: invalid Earn address");
        hygt.initialize( address(0), address(farm) ) ;
    }

    function test_Initialize_FarmZeroAddress() public {
        vm.expectRevert("HYGT: invalid Farm address");
        hygt.initialize( address(earn), address(0) ) ;
    }

    function test_mint_to_withCallerRole () public{
        hygt.initialize( address(earn), address(farm) ) ;
        vm.prank(address(earn));
        bool success = hygt.mint(address(123), 100e18);
        assertTrue(success);
    }

    function test_mint_to_withOutCallerRole () public{
        hygt.initialize( address(earn), address(farm) ) ;
        vm.prank(address(1234));
        vm.expectRevert();
        hygt.mint(address(123), 100e18);
    }

    function test_mint_to_GreateThancallerMaxSupply() public{
        test_Initialize();
        vm.prank(address(earn));
        vm.expectRevert("HYGT: invalid amount considering caller max supply");
        hygt.mint(address(farm), 1000000000e18);
    }

    function test_burn( ) public {
        hygt.initialize( address(earn), address(farm) ) ;
        vm.prank(address(earn));
        bool success = hygt.mint( address(this),  1000e18);
        assertTrue( success);
        bool done = hygt.burn(1000e18);
        assertTrue( done);
    }

    function test_BurnFrom () public {
        hygt.initialize( address(earn), address(farm) ) ;
        vm.startPrank(address(earn));
        bool success = hygt.mint( address(this),  1000e18);
        vm.stopPrank();

        hygt.approve(address(earn), 1000e18);

        vm.prank(address(earn));
        bool done = hygt.burnFrom(address(this),100e18);
        assertTrue( done);
    }

    //delegate


   
}