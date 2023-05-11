// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import {Control} from "../src/Control.sol";
import {HYDT} from "../src/HYDT.sol";
import {HYGT} from "../src/HYGT.sol";
import {Reserve} from "../src/Reserve.sol";
import {WBNB} from "../src/WBNB.sol";
import {IERC20} from "../src/interfaces/IERC20.sol";
import {Earn} from "../src/Earn.sol";
import {sHYDT} from "../src/sHYDT.sol";
import {Farm} from "../src/Farm.sol";
import {USDT} from  "../src/extensions/USDT.sol";

contract HYDTTest is Test {
    Control public control;
    HYDT public hydt;
    HYGT public hygt;
    Reserve public reserve;
    WBNB public wbnb;
    Earn public earn;
    sHYDT public shydt;
    Farm public farm;
    USDT public usdt;
    IERC20 public token;

    function setUp() public {
        reserve = new Reserve();
        control = new Control();
        hydt = new HYDT(address(reserve));
        wbnb = new WBNB();
        earn = new Earn();
        shydt = new sHYDT();
        farm = new Farm();
        usdt= new USDT();
        hygt = new HYGT(address(0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496), address(reserve));
        // token = IERC20(usdt);
    }
    function initializing() public{
        shydt.initialize(address(earn));
        hydt.initialize(address(control), address(earn));
        reserve.initialize(address (control));
        hygt.initialize(address (earn), address (farm));
        earn.initialize( address(hydt), address( hygt),  address(shydt),  address(reserve),  uint(1) ) ;
    }

    function test_initialize() public {
        initializing();
        address[3] memory tokens  ;
        tokens = [address(wbnb), address(usdt), address(hygt)];
        uint256 initialMintStartTime_=block.timestamp ;

        farm.initialize(address (hygt), tokens,initialMintStartTime_ ) ;
        assertTrue(farm.hasRole(farm.GOVERNOR_ROLE(), address(this)));
        assertTrue(farm.hasRole(farm.DEFAULT_ADMIN_ROLE(), address(this)));
        uint length= farm.poolLength();
        uint expectedLength= 3;
        assertEq(length, expectedLength);
    }

   

    function test_InitializeWithRandomAddress() public {
        address[3] memory tokens  ;
        tokens = [address(wbnb), address(usdt), address(hygt)];
        uint256 initialMintStartTime_=block.timestamp ;

        vm.prank(address(123));
        vm.expectRevert("Farm: caller is not the initializer");
        farm.initialize(address (hygt), tokens,initialMintStartTime_ ) ;
    }

    function test_InitializeInvalidHYGTAddress() public {
        address[3] memory tokens  ;
        tokens = [address(wbnb), address(usdt), address(hygt)];
        uint256 initialMintStartTime_=block.timestamp ;
        
        vm.expectRevert("Farm: invalid HYGT address");
        farm.initialize(address (0), tokens,initialMintStartTime_ ) ;
    }

    function test_addPool() public {
        test_initialize();
        // (IERC20 lpToken,
        // uint256 allocPoint,
        // uint256 lastRewardBlock,
        // uint256 accHYGTPerShare)=farm.poolInfo(0);
        uint totalAllocPoint= farm.totalAllocPoint();

        vm.roll(200);
        farm.addPool(IERC20(address(usdt)), uint(10), "testToken", true); 
        assertEq(farm.totalAllocPoint(), totalAllocPoint+=uint(10));
        
        (IERC20 lpToken,
        uint256 allocPoint,
        uint256 lastRewardBlock,
        uint256 accHYGTPerShare)=farm.poolInfo(0);
        assertEq(allocPoint, uint(400));
        assertEq(lastRewardBlock, uint(200));
        assertEq(accHYGTPerShare, uint(0));
    }

    function test_addPoolWithoutRole() public {
        test_initialize();
        uint totalAllocPoint= farm.totalAllocPoint();

        vm.roll(200);
        vm.prank(address(12345));
        vm.expectRevert("AccessControl: account 0x0000000000000000000000000000000000003039 is missing role 0xd0990c50b6714f222e6fd1faaf5345bf1aa2867d2861fc2cc43b364e7d948647");
        farm.addPool(IERC20(address(usdt)), uint(10), "testToken", true); 
    }

    function test_addPoolwithOutUpdate() public {
        test_initialize();
        uint totalAllocPoint= farm.totalAllocPoint();

        farm.addPool(IERC20(address(usdt)), uint(10), "testToken", false); 

        vm.roll(3000);
        assertEq(farm.totalAllocPoint(), totalAllocPoint+=uint(10));
        (IERC20 lpToken,
        uint256 allocPoint,
        uint256 lastRewardBlock,
        uint256 accHYGTPerShare)=farm.poolInfo(0);
        assertEq(allocPoint, uint(400));
        assertEq(lastRewardBlock, uint(151));
        assertEq(accHYGTPerShare, uint(0));
    }

    function test_addPoolTimeLessThanLastRewardBlock() public {
        test_initialize();
        uint totalAllocPoint= farm.totalAllocPoint();

        farm.addPool(IERC20(address(usdt)), uint(10), "testToken", false); 

        vm.roll(100);
        assertEq(farm.totalAllocPoint(), totalAllocPoint+=uint(10));
        (IERC20 lpToken,
        uint256 allocPoint,
        uint256 lastRewardBlock,
        uint256 accHYGTPerShare)=farm.poolInfo(0);
        assertEq(allocPoint, uint(400));
        assertEq(lastRewardBlock, uint(151));
        assertEq(accHYGTPerShare, uint(0));
    }



    //     // (IERC20 lpToken,
    //     // uint256 allocPoint,
    //     // uint256 lastRewardBlock,
    //     // uint256 accHYGTPerShare)=farm.poolInfo(0);
    //     // assertEq(allocPoint, uint(400));
    //     // assertEq(lastRewardBlock, uint(151));
    //     // assertEq(accHYGTPerShare, uint(0));

    function test_Deposit() public {
        test_initialize();
        usdt.approve(address(farm), 10000e18);
        (uint amount0,uint rewarddebt0)=farm.userInfo(uint(1),address(this));
        
        // vm.expectRevert("Farm: not good");
        usdt.approve(address(farm), 1000e18);
        farm.deposit(uint(1), 100e18);
        (uint amount,uint rewarddebt)=farm.userInfo(uint(1),address(this));
        assertEq(amount,amount0+=100e18);
        assertEq(rewarddebt,0);
    }

    function test_EmergencyWithdraw() public {
        test_initialize();
        usdt.approve(address(farm), 10000e18);
        (uint amount0,uint rewarddebt0)=farm.userInfo(uint(1),address(this));
        
        usdt.approve(address(farm), 1000e18);
        farm.deposit(uint(1), 100e18);
        (uint amount,uint rewarddebt)=farm.userInfo(uint(1),address(this));
        uint prevBal= usdt.balanceOf(address(this));
        vm.warp(300);
        farm.emergencyWithdraw(uint(1));
        assertEq( usdt.balanceOf(address(this)) ,prevBal+amount );
    }

    function test_DepositTwice() public {
        test_initialize();
        
        usdt.approve(address(farm), 10000e18);
        (uint amount0,uint rewarddebt0)=farm.userInfo(uint(1),address(this));
        
        // vm.expectRevert("Farm: not good");
        usdt.approve(address(farm), 1000e18);
        farm.deposit(uint(1), 100e18);
        (uint amount,uint rewarddebt)=farm.userInfo(uint(1),address(this));
        assertEq(amount,amount0+=100e18);
        assertEq(rewarddebt,0);
        (IERC20 lpToken,
        uint256 allocPoint,
        uint256 lastRewardBlock,
        uint256 accHYGTPerShare)=farm.poolInfo(uint(1));

        hygt.balanceOf(address(this));

        vm.roll(200);

        farm.deposit(uint(1), 100e18);
        assertEq(hygt.balanceOf(address(this)),uint(39200000000000000000));
        // farm.updatePool(uint(1));
        // (uint amount1,uint rewardebt)=farm.userInfo(uint(1),address(this));
        //     (IERC20 lpToken1,
        // uint256 allocPoint1, //400
        // uint256 lastRewardBlock1, //170
        // uint256 accHYGTPerShare1   )=farm.poolInfo(uint(1)); //152000000000
        // farm.deposit(uint(1), 100e18);
    }

    function test_updateAllocPoint () public {
        uint allocPoint=2000;
        uint8 stakeType= 2;
        test_initialize();
        vm.roll(11);
        farm.updateAllocation(uint(1),  uint(20),  true);
        (IERC20 lpToken,
        uint256 allocPoint1,
        uint256 lastRewardBlock, //151
        uint256 accHYGTPerShare)=farm.poolInfo(uint(1)); //0
        assertEq(lastRewardBlock,151);
        assertEq(accHYGTPerShare,0);
        assertEq(allocPoint1,20);
        uint res= farm.totalAllocPoint();
        assertEq(res,620);

    }

    function test_updateAllocPointOnly () public {
        uint allocPoint=2000;
        uint8 stakeType= 2;
        test_initialize();
        vm.roll(1011);
        farm.updateAllocation(uint(1),  uint(50),  true);
        (IERC20 lpToken,
        uint256 allocPoint1,
        uint256 lastRewardBlock,  
        uint256 accHYGTPerShare)=farm.poolInfo(uint(1));  
        assertEq(allocPoint1,50);
        uint res= farm.totalAllocPoint();
        assertEq(res,650);
    }

    function test_updateAllocPointWithNonGOVERNOR_ROLE () public {
            uint allocPoint=2000;
            uint8 stakeType= 2;
            test_initialize();
            vm.roll(1011);
            vm.prank(address(1234));
            vm.expectRevert("AccessControl: account 0x00000000000000000000000000000000000004d2 is missing role 0xd0990c50b6714f222e6fd1faaf5345bf1aa2867d2861fc2cc43b364e7d948647");
            farm.updateAllocation(uint(1),  uint(50),  true);
    }

    function test_getpending() public {
        test_initialize();
        usdt.approve(address(farm), 10000e18);
        (uint amount0,uint rewarddebt0)=farm.userInfo(uint(1),address(this));
        
        // vm.expectRevert("Farm: not good");
        usdt.approve(address(farm), 1000e18);
        farm.deposit(uint(1), 100e18);
        vm.roll(240);
        uint amount=farm.getPending(uint(1),address(this));
        assertEq(amount,71200000000000000000);
    }

    function test_getpendingBatch() public {
        test_initialize();
        usdt.approve(address(farm), 10000e18);
        (uint amount0,uint rewarddebt0)=farm.userInfo(uint(1),address(this));
        
        // vm.expectRevert("Farm: not good");
        usdt.approve(address(farm), 1000e18);
        farm.deposit(uint(1), 100e18);
        vm.roll(240);
        uint amount=farm.getPendingBatch(address(this));
        assertEq(amount,71200000000000000000);
    }


    // function test_withdraw() public {
    //     test_initialize();
        
    //     // vm.expectRevert("Farm: not good");
    //     usdt.approve(address(farm), 1000e18);
    //     farm.deposit(uint(1), 100e18);
    //     vm.roll(240);

    //     farm.deposit(uint(1), 100e18);
    //     (uint amount0,uint rewardebt0)=farm.userInfo(uint(1),address(this));

    //     farm.withdraw(1, 100e18);
    //     assertEq(usdt.balanceOf(address(this)),uint(29999900000000000000000000));

    //     (uint amount,uint rewardebt)=farm.userInfo(uint(1),address(this));
    //     assertEq(rewardebt,uint(71200000000000000000));
        
        
    // }

    function test_withdraw() public {
        test_initialize();
        usdt.approve(address(farm), 1000e18);
        farm.deposit(uint(1), 100e18);

        vm.roll(290);
        farm.updatePool(uint(1));

        farm.deposit(uint(1), 100e18);
        (uint amount0,uint rewardebt0)=farm.userInfo(uint(1),address(this));

        vm.roll(390);
        usdt.balanceOf(address(this));
        (uint amount1,uint rewardebt1)=farm.userInfo(uint(1),address(this));

        farm.withdraw(1, 100e18);

        uint bal= usdt.balanceOf(address(this));
        assertEq(bal,uint(29999900000000000000000000));

        (uint amount,uint rewardebt)=farm.userInfo(uint(1),address(this));
        assertEq(amount,amount1- 100e18);
       
        assertEq(rewardebt,uint(151200000000000000000));
    }


    // (IERC20 lpToken,
    //     uint256 allocPoint1,
    //     uint256 lastRewardBlock,  
    //     uint256 accHYGTPerShare)=farm.poolInfo(uint(1));

    }