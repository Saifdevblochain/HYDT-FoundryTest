// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import {Control} from "../src/Control.sol";
import {HYDT} from "../src/HYDT.sol";
// import {HYGT} from "../src/HYGT.sol";
import {Reserve} from "../src/Reserve.sol";
import {WBNB} from "../src/WBNB.sol";
import {IERC20} from "../src/interfaces/IERC20.sol";

contract ControlTest is Test {
    IERC20 public token;
    uint256 initialMintStartTime_ = uint256(block.timestamp);
    Control public control;
    HYDT public hydt;
    // HYGT public hygt;
    Reserve public reserve;
    WBNB public wbnb;

    // Invoked before each test
    function setUp() public {
        reserve = new Reserve();
        control = new Control();
        hydt = new HYDT(address(reserve));
        wbnb = new WBNB();
        token = IERC20(hydt);
        // hygt = new HYGT(address(0x34136d58CB3ED22EB4844B481DDD5336886b3cec), address(reserve));
    }

    // Test must be external or public
    function test_Initialize() public {
        
        control.initialize(
            address(wbnb),
            address(hydt),
            address(reserve),
            initialMintStartTime_
        );
        assertTrue(control.hasRole(control.GOVERNOR_ROLE(), address(this)));
        assertTrue(control.hasRole(control.CALLER_ROLE(), address(this)));
    }

    function test_Initialize_with_zeroAddress() public {
        vm.prank(address(0));
        vm.expectRevert("Control: caller is not the initializer");
        control.initialize(
            address(wbnb),
            address(hydt),
            address(reserve),
            initialMintStartTime_
        );
    }

    function test_Initialize_hydt_zeroAddress() public {
        address hydt_ = address(0);
        vm.expectRevert("Control: invalid HYDT address");
        control.initialize(
            address(wbnb),
            address(hydt_),
            address(reserve),
            initialMintStartTime_
        );
    }

    function test_Initialize_reserve_zeroAddress() public {
        address reserve_ = address(0);
        vm.expectRevert("Control: invalid Reserve address");
        control.initialize(
            address(wbnb),
            address(hydt),
            address(reserve_),
            initialMintStartTime_
        );
    }

    function test_updateOpsReadyState() public {
        control.initialize(
            address(wbnb),
            address(hydt),
            address(reserve),
            initialMintStartTime_
        );
        assertTrue(true);
        control.updateOpsReadyState(false);
        assertTrue(true);
    }

    function test_updateOpsReadyStateWithOutInitializing() public {
        vm.expectRevert();
        control.updateOpsReadyState(true);
    }

    function test_delegateApprove() public {
        address to = address(0xC0FC8954c62A45c3c0a13813Bd2A10d88D70750D);
        control.initialize(
            address(wbnb),
            address(hydt),
            address(reserve),
            initialMintStartTime_
        );
        control.delegateApprove(token, to, true);
        assertTrue(true);
    }

    function test_delegateApproveWithBoolFalse() public {
        address to = address(0xC0FC8954c62A45c3c0a13813Bd2A10d88D70750D);
        control.initialize(
            address(wbnb),
            address(hydt),
            address(reserve),
            initialMintStartTime_
        );
        control.delegateApprove(token, to, false);
        assertTrue(true);
    }

    function test_getInitialmints() public {
        uint256 initialMintStartTime = uint256(12123123);
        control.initialize(
            address(wbnb),
            address(hydt),
            address(reserve),
            initialMintStartTime
        );
        (uint startTime, uint endTime, uint amountUSD) = control
            .getInitialMints();
        assertEq(startTime, initialMintStartTime);
        assertEq(endTime, initialMintStartTime + 5400);
        assertEq(amountUSD, 0);
    }

    function test_getDailyInitialMints() public {}
}
