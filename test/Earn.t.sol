// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.18;

// import "forge-std/Test.sol";
// import {Control} from "../src/Control.sol";
// import {HYDT} from "../src/HYDT.sol";
// import {HYGT} from "../src/HYGT.sol";
// import {Reserve} from "../src/Reserve.sol";
// import {WBNB} from "../src/WBNB.sol";
// // import {IERC20} from "../src/interfaces/IERC20.sol";
// import {Earn} from "../src/Earn.sol";
// import {sHYDT} from "../src/sHYDT.sol";
// import {Farm} from "../src/Farm.sol";

// interface EarnEvents {
//     event UpdateAllocationWithUpdate(uint256 indexed stakeType, uint256 newAllocPoint, uint256 oldAllocPoint);
//     event Stake(
//         address indexed user,
//         uint256 index,
//         uint256 amount,
//         uint8 stakeType,
//         uint256 startTime,
//         uint256 endTime
//     );
//     event Payout(address indexed user, uint256 index, uint256 payout);
//     event Unstake(address indexed user, uint256 index, uint256 amount, uint256 activeDeposits);
// }
// contract EarnTest is EarnEvents,Test {
//     // uint256 initialMintStartTime_ = uint256(block.timestamp);
//     Control public control;
//     HYDT public hydt;
//     HYGT public hygt;
//     Reserve public reserve;
//     WBNB public wbnb;
//     Earn public earn;
//     sHYDT public shydt;
//     Farm public farm;

//     // Invoked before each test
//     function setUp() public {
//         reserve = new Reserve();
//         control = new Control();
//         hydt = new HYDT(address(reserve));
//         wbnb = new WBNB();
//         earn = new Earn();
//         shydt = new sHYDT();
//         farm = new Farm();
//         hygt = new HYGT(address(0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496), address(reserve));
//     }

//     function initializing() public{
//         shydt.initialize(address(earn));
//         hydt.initialize(address(control), address(earn));
//         reserve.initialize(address (control));
//         hygt.initialize(address (earn), address (farm));
//         earn.initialize( address(hydt), address( hygt),  address(shydt),  address(reserve),  uint(1) ) ;
//     }

//     function test_Initialize() public {
//         uint initialMintTime = uint (block.timestamp);
//         earn.initialize( address(hydt), address( hygt),  address(shydt),  address(reserve),  initialMintTime ) ;
//         uint depositFee= earn.depositFee();
//         assertEq(depositFee,15);
//         assertTrue(earn.hasRole(control.GOVERNOR_ROLE(), address(this)));
//         assertTrue(earn.hasRole(control.DEFAULT_ADMIN_ROLE(), address(this)));
//          uint length= earn.poolLength();
//         uint expectedLength= 3;
//         assertEq(length, expectedLength);
//     }

//     function test_InitializeWithHydtAddressZero() public {
//         uint initialMintTime = uint (block.timestamp);
//         vm.expectRevert("Earn: invalid HYDT address");
//         earn.initialize( address(0), address( hygt),  address(shydt),  address(reserve),  initialMintTime ) ;
//     }

//     function test_InitializeWithHYGTAddressZero() public {
//         uint initialMintTime = uint (block.timestamp);
//         vm.expectRevert("Earn: invalid HYGT address");
//         earn.initialize( address(hydt), address( 0),  address(shydt),  address(reserve),  initialMintTime ) ;
//     }

//     function test_InitializeWithshydtAddressZero() public {
//         uint initialMintTime = uint (block.timestamp);
//         vm.expectRevert("Earn: invalid sHYDT address");
//         earn.initialize( address(hydt), address(hygt),  address(0),  address(reserve),  initialMintTime ) ;
//     }

//     function test_InitializeWithTreasuryAddressZero() public {
//         uint initialMintTime = uint (block.timestamp);
//         vm.expectRevert("Earn: invalid Treasury address");
//         earn.initialize( address(hydt), address(hygt),  address(shydt),  address(0),  initialMintTime ) ;
//     }

//     function test_InitializeRAddressAfterIniitalize() public {
//         uint initialMintTime = uint (block.timestamp);
//         earn.initialize( address(hydt), address(hygt),  address(shydt),  address(reserve),  initialMintTime ) ;
//         address initializer = earn._initializer();
//         assertEq(initializer, address(this));
//     }

//     function test_InitializeWithInitializerZeroAddress() public {
//         uint initialMintTime = uint (block.timestamp);
//         vm.prank(address(0));
//         vm.expectRevert();
//         earn.initialize( address(hydt), address( hygt),  address(shydt),  address(reserve),  initialMintTime);
//     }

//     function test_dailyPayouts() public {
//         uint initialMintTime = uint (block.timestamp);
//         earn.initialize( address(hydt), address( hygt),  address(shydt),  address(reserve),  initialMintTime ) ;
//         uint dailyPayouts= earn.dailyPayouts(0);
//         uint dailyPayouts1= earn.dailyPayouts(1);
//         uint dailyPayouts2= earn.dailyPayouts(2);
//         assertEq(dailyPayouts,1.156 * 1e18);
//         assertEq(dailyPayouts1, 0.611 * 1e18);
//         assertEq(dailyPayouts2,0.356 * 1e18);
//     }

//     // yearlyYields = [16 * 1e18, 20 * 1e18, 30 * 1e18];
//     // function test_yearlyYields() public {
//     //     uint initialMintTime = uint (block.timestamp);
//     //     earn.initialize( address(hydt), address( hygt),  address(shydt),  address(reserve),  initialMintTime ) ;
//     //     uint yearlyYields= earn.yearlyYields(0);
//     //     uint yearlyYields1= earn.yearlyYields(1);
//     //     uint yearlyYields2= earn.yearlyYields(2);
//     //     assertEq(yearlyYields,16 * 1e18);
//     //     assertEq(yearlyYields1,20 * 1e18);
//     //     assertEq(yearlyYields2, 30 * 1e18);
//     // }
//     // HYGTPerSecond

//     function test_VariableUpdateAfterInitialize() public {
//         uint initialMintTime = uint (block.timestamp);
//         earn.initialize( address(hydt), address( hygt),  address(shydt),  address(reserve),  initialMintTime ) ;
//         uint HYGTPerSecond= earn.HYGTPerSecond();
//         assertEq(HYGTPerSecond, 0.166666666666666667 * 1e18);
//     }

//     function test_updateAllocPoint () public {
//         uint allocPoint=2000;
//         uint8 stakeType= 2;
//         uint initialMintTime = uint (block.timestamp);
//         earn.initialize( address(hydt), address( hygt),  address(shydt),  address(reserve),  initialMintTime ) ;
//         earn.updateAllocationWithUpdate( stakeType,  allocPoint);
//         assertTrue(true);
//     }

//     function test_updateAllocPointWithNonGOVERNOR_ROLE () public {
//         uint allocPoint=2000;
//         uint8 stakeType= 2;
//         uint initialMintTime = uint (block.timestamp);
//         earn.initialize( address(hydt), address( hygt),  address(shydt),  address(reserve),  initialMintTime ) ;
//         vm.prank(address(wbnb));
//         vm.expectRevert("AccessControl: account 0x5991a2df15a8f6a256d3ec51e99254cd3fb576a9 is missing role 0xd0990c50b6714f222e6fd1faaf5345bf1aa2867d2861fc2cc43b364e7d948647");
//         earn.updateAllocationWithUpdate( stakeType,  allocPoint);
        
//     }

//     function test_GrantRole() public {
//         initializing();
//         earn.grantRole(earn.GOVERNOR_ROLE(), address(wbnb));
//         assertTrue(earn.hasRole(earn.GOVERNOR_ROLE(), address(wbnb)));
//     }  

//     function test_RevokeRole() public {
//         initializing();
//         earn.grantRole(earn.GOVERNOR_ROLE(), address(wbnb));
//         assertTrue(earn.hasRole(earn.GOVERNOR_ROLE(), address(wbnb)));

//         earn.revokeRole(earn.GOVERNOR_ROLE(), address(wbnb));
//         bool expectedRole = earn.hasRole(earn.GOVERNOR_ROLE(),  address(wbnb));
//         assertEq(expectedRole,false);
//     }  

//     function test_stake() public {
//         initializing();
//         hydt.approve(address(earn), uint(100000e18));
//         uint _amount = uint(10e18);
//         assertTrue(shydt.hasRole(shydt.CALLER_ROLE(), address(earn)));
//         earn.stake(_amount, 0);
//         (,bool stakingStatus,uint256 amount,,,uint stakingendTime,uint stakinglastClaimTime,)= earn.getStakings(address(this), uint(0));
//         uint fee=uint (_amount*15/1000);
//         assertEq(amount,_amount-fee);
//         assertTrue(stakingStatus);
//         assertEq(stakingendTime,5401 );
//         assertEq(stakinglastClaimTime,1);
        
//     }  

//     function test_stakeWithAmountZero() public {
//         initializing();
//         hydt.approve(address(earn), uint(100000e18));
//         uint _amount = uint(0);
//         assertTrue(shydt.hasRole(shydt.CALLER_ROLE(), address(earn)));
//         vm.expectRevert("Earn: insufficient amount");
//         earn.stake(_amount, 0);
//     }    
    
//     function test_stakeWithStakeTypeIncorrect() public {
//         initializing();
//         hydt.approve(address(earn), uint(100000e18));
//         uint _amount = uint(10e18);
//         assertTrue(shydt.hasRole(shydt.CALLER_ROLE(), address(earn)));
//         vm.expectRevert("Earn: invalid stake type");
//         earn.stake(_amount, uint8(3));
//     } 

//     function test_stakeEvent() public {
//         initializing();
//         hydt.approve(address(earn), uint(100000e18));
//         uint _amount = uint(10e18);
//         assertTrue(shydt.hasRole(shydt.CALLER_ROLE(), address(earn)));

//         vm.expectEmit(false, true, true, false);
//         emit Stake(address(this), uint8(0) , uint(10e18), uint8(0),1, 5401);

//         earn.stake(_amount, 0);
//         (,bool stakingStatus,uint256 amount,,,uint stakingendTime,uint stakinglastClaimTime,)= earn.getStakings(address(this), uint(0));
//         uint fee=uint (_amount*15/1000);
//         console.logUint(stakingendTime);
//         console.logUint(stakinglastClaimTime);
//         //  vm.expectEmit(true, true, false, true);
//         // // emit Transfer(address(this), address(this), 10);
//         // // hydt.transfer(address(this), 10);
//         // hydt.approve(address(earn), uint(100000e18));
//     } 


//     function test_stakeWithCallerWithOutHYDTAllowance ( ) public {
//         initializing();
//         uint _amount = uint(10e18);
//         vm.expectRevert("ERC20: insufficient allowance");
//         earn.stake(_amount, 0);
//     }    
//     // not to use this
//     // function test_claimPayout()  public {
//     //     initializing();
//     //     hydt.approve(address(earn), uint(100000e18));
//     //     uint _amount = uint(10e18);
//     //     assertTrue(shydt.hasRole(shydt.CALLER_ROLE(), address(earn)));
//     //             // staking here
//     //     vm.warp(1683634003);
//     //     uint8 _type= uint8(0);
//     //     earn.stake(_amount,_type);
//     //     (,bool stakingStatus,uint256 amount,,,uint stakingendTime,uint stakinglastClaimTime,)= earn.getStakings(address(this), uint(0));
//     //     uint fee=uint (_amount*15/1000);
//     //     // (,,, uint accHYGTPerShare,)=earn.poolInfo(0);
//     //     // console.logUint(accHYGTPerShare);
//     //     uint balanceBeforeUnstake = hydt.balanceOf(address(this));
//     //     // checking data updating or not on staking
//     //     // assertEq(amount,_amount-fee);
//     //     // assertTrue(stakingStatus);
//     //     // assertEq(stakingendTime,5401 );
//     //     // assertEq(stakinglastClaimTime,1);
//     //     // uint res= earn.getStakingLengths(address(this));
//     //     // assertEq(res,1);
//     //     console.logUint(uint(block.timestamp));
//     //     // (,,,,,,,uint256 rewardDebt)= earn.getStakings(address(this), uint(0));
//     //     console.logUint(hydt.balanceOf(address(this)));
//     //     // console.logUint(uint(rewardDebt));

//     //     // checking Rewards after a sepecific time
//     //     vm.warp(1683639503);
//     //     earn.claimPayout(uint(0));
//     //     uint balanceAfterUnstake = hydt.balanceOf(address(this));
//     //     uint resultCheck = balanceAfterUnstake- balanceBeforeUnstake;
//     //     // (,,,,,,,uint256 rewardDebt1)= earn.getStakings(address(this), uint(0));
//     //     assertEq(resultCheck,uint(10247940000000000000));

//     //     // console.logUint(uint(rewardDebt1));
//     // } 

//     function test_claimPayoutWithNoStakings()  public {
//         initializing();
//         hydt.approve(address(earn), uint(100000e18));
//         uint _amount = uint(10e18);
//         assertTrue(shydt.hasRole(shydt.CALLER_ROLE(), address(earn)));
//                 // staking here
//         vm.warp(1683705649);
//         earn.stake(_amount, 0);
//         (,bool stakingStatus,uint256 amount,,,uint stakingendTime,uint stakinglastClaimTime,)= earn.getStakings(address(this), uint(0));
//         // uint fee=uint (_amount*15/1000);
//         // (,,, uint accHYGTPerShare,)=earn.poolInfo(0);
//         // console.logUint(accHYGTPerShare);
//         uint balanceBeforeUnstake = hydt.balanceOf(address(this));
//         uint balanceBeforeUnstakehygt = hygt.balanceOf(address(this));
//         // assertEq(balanceBeforeUnstakehygt,uint(0));

//         // checking data updating or not on staking
//         // assertEq(amount,_amount-fee);
      
//         // checking Rewards after a sepecific time
//         vm.warp(1683717049);
//         // vm.warp(1683639503);
//         earn.claimPayout(uint(0));
//         vm.warp(1683717051);
//         vm.expectRevert("Earn: invalid staking");
//         earn.claimPayout(uint(0));
//     } 


//     function test_claimPayout_EarlierThanDeadlinePassed()  public {
//         initializing();
//         hydt.approve(address(earn), uint(100000e18));
//         uint _amount = uint(10e18);
//                 // staking here
//         // vm.warp(1683705649);
//         earn.stake(_amount, 0);
//         (,bool stakingStatus,uint256 amount,,,uint stakingendTime,uint stakinglastClaimTime,)= earn.getStakings(address(this), uint(0));
        
//         // // checking Rewards after a sepecific time
//         vm.warp(200);
//         uint result =earn.getPayout(address(this),0);
//         assertGt(result,0);
        
//     }

//     function test_claimPayout_StakingDataUpdate()  public {
//         initializing();
//         hydt.approve(address(earn), uint(100000e18));
//         uint _amount = uint(10e18);
//                 // staking here
//         // vm.warp(1683705649);
//         earn.stake(_amount, 0);
//                                     // 5401, 1, 0
//         (,, ,,, uint endTime ,uint stakinglastClaimTime,uint rewardDebt)= earn.getStakings(address(this), uint(0));
//         vm.warp(endTime-12);
//         vm.expectEmit(true, false, false, false);
//         emit Payout(address(this), uint(0), uint(10134074000000000000));
//         earn.claimPayout( 0);
//                                 // 5401, 5341, 59799999999992950000
//         (,, ,,, uint endTime1 ,uint stakinglastClaimTime1,uint rewardDebt1)= earn.getStakings(address(this), uint(0));
//         uint expectedstakinglastClaimTime1=uint(5341);
//         uint expectedrewardDebt1=uint(59799999999992950000);
        
//         assertEq(stakinglastClaimTime1, expectedstakinglastClaimTime1 );
//         assertEq(rewardDebt1, expectedrewardDebt1 );
        

//         // // checking Rewards after a sepecific time
//         // uint result =earn.getPayout(address(this),0);
//         // assertGt(result,0);
        
//     }

//     function test_claimPayout_DeadlinePassedPending()  public {
//         initializing();
//         hydt.approve(address(earn), uint(100000e18));
//         uint _amount = uint(10e18);
//                 // staking here
//         // vm.warp(1683705649);
//         earn.stake(_amount, 0);
//         (,bool stakingStatus,uint256 amount,,,uint stakingendTime,uint stakinglastClaimTime,)= earn.getStakings(address(this), uint(0));
        
//         // // checking Rewards after a sepecific time
//         vm.warp(stakingendTime);
//         earn.updatePool(0);
//         uint256 pending= earn.getPending(address(this), 0);
//         assertGt(pending,0);
//     }

//     function test_updatePoolTimeLessThanLastClaim()  public {
//         initializing();
//         hydt.approve(address(earn), uint(100000e18));
//         uint _amount = uint(10e18);
//                 // staking here
//         // vm.warp(1683705649);
//         earn.stake(_amount, 0);
//         (,bool stakingStatus,uint256 amount,,,uint stakingendTime,uint stakinglastClaimTime,)= earn.getStakings(address(this), uint(0));
        
//         // // checking Rewards after a sepecific time
//         vm.warp(0);
//         earn.poolInfo(0);
//         // earn.updatePool(0);
//         // uint256 pending= earn.getPending(address(this), 0);
//         // assertGt(pending,0);
//     }

//     function test_claimPayout_DeadlinePassedAmount()  public {
//         initializing();
//         hydt.approve(address(earn), uint(100000e18));
//         uint _amount = uint(10e18);
//                 // staking here
//         // vm.warp(1683705649);
//         earn.stake(_amount, 0);
//         (,bool stakingStatus,uint256 amount,,,uint stakingendTime,uint stakinglastClaimTime,)= earn.getStakings(address(this), uint(0));
        
//         // // checking Rewards after a sepecific time
//         vm.warp(stakingendTime);
//         earn.updatePool(0);
//         uint256 amount__= earn.getPayout(address(this), 0);
//         assertGt(amount__,0);
//     }

//     function test_claimPayout()  public {
//         initializing();
//         hydt.approve(address(earn), uint(100000e18));
//         uint _amount = uint(10e18);
//         assertTrue(shydt.hasRole(shydt.CALLER_ROLE(), address(earn)));
//                 // staking here
//         vm.warp(1683705649);
//         earn.stake(_amount, 0);
//         (,bool stakingStatus,uint256 amount,,,uint stakingendTime,uint stakinglastClaimTime,)= earn.getStakings(address(this), uint(0));
//         uint fee=uint (_amount*15/1000);
//         uint balanceBeforeUnstake = hydt.balanceOf(address(this));
//         uint balanceBeforeUnstakehygt = hygt.balanceOf(address(this));
//         assertEq(balanceBeforeUnstakehygt,uint(0));

//         // checking data updating or not on staking
//         assertEq(amount,_amount-fee);
      
//         // checking Rewards after a sepecific time
//         vm.warp(1683711049);
//         // uint result =earn.getPayout(address(this),0);
//         earn.updatePool( uint8(0));
//         earn.claimPayout(uint(0));
//         uint balanceAfterUnstake = hydt.balanceOf(address(this));
//         uint resultCheck = balanceAfterUnstake- balanceBeforeUnstake;

//         assertEq(resultCheck,uint(10247940000000000000));
//         uint balanceAfterUnstakehygt = hygt.balanceOf(address(this));
//         // console.logUint(balanceAfterUnstakehygt);
//         assertEq(balanceAfterUnstakehygt, uint(89999999999995550000) );
//         // earn.poolInfo(0);
//         // earn.poolShares(0,0);
//         // console.logUint(hygt.balanceOf(address(this)));
//         // (,,,,,,,uint256 rewardDebt1)= earn.getStakings(address(this), uint(0));

//         // console.logUint(uint(resultCheck));
//     } 
    

//     function test_getStakings()  public {
//         initializing();
//         hydt.approve(address(earn), uint(100000e18));
//         uint _amount = uint(10e18);
//         vm.warp(1683705649);
//         earn.stake(_amount, 0);
//         (,bool stakingStatus,uint256 amount,,,uint stakingendTime,uint stakinglastClaimTime,)= earn.getStakings(address(this), uint(0));
//         uint fee=uint (_amount*15/1000);
//         assertEq(amount,_amount-fee);
//     } 

//     function test_stakingLength()  public {
//         initializing();
//         hydt.approve(address(earn), uint(100000e18));
//         uint _amount = uint(10e18);
//         earn.stake(_amount, 0);
//         uint res= earn.getStakingLengths(address(this));
//         assertEq(res,1);
//     } 
    

//     function test_updatePool( ) public {
//         initializing();
//         hydt.approve(address(earn), uint(100000e18));
//         vm.warp(1683788870);

//         uint8 stakeType = uint8(0);
//         uint _amount = uint(10e18);
//         earn.stake(_amount, stakeType);
//         (,,uint256 amount,,,,uint lastClaimTime,)= earn.getStakings(address(this), uint(0));
//         vm.warp(1683794196);
//         earn.updatePool( uint8(0));
//         vm.warp(1683794273);
//         uint pending = earn.getPending(address(this), uint8(0));
//         assertEq(pending, uint(89999999999995550000));
//     }

//     function test_getPendingTimeGreaterthanLastRewardTime( ) public {
//         initializing();
//         hydt.approve(address(earn), uint(100000e18));
//         vm.warp(1683788850);

//         uint8 stakeType = uint8(0);
//         uint _amount = uint(10e18);
//         earn.stake(_amount, stakeType);
//         (,,uint256 amount1,,,,uint lastClaimTime,)= earn.getStakings(address(this), uint(0));
//         vm.warp(1683788851);
//         earn.claimPayout(0);
//         vm.expectRevert("Earn: no amount to withdraw");
//         vm.warp(1683788850);
//         earn.claimPayout(0);
        
//         // uint pending = earn.getPending(address(this), uint8(0));
//         // (,,uint256 amount2,,,,uint lastClaimTime1,)= earn.getStakings(address(this), uint(0));
//         // console.logUint(pending);
//         // assertEq(pending, uint(89999999999995550000));
//     }

//     function test_pendingBatch( ) public {
//         initializing();
//         hydt.approve(address(earn), uint(100000e18));
//         vm.warp(1683788870);
//         uint8 stakeType = uint8(0);
//         uint _amount = uint(10e18);
//         earn.stake(_amount, stakeType);
//         earn.stake(_amount, stakeType);
//         vm.warp(1683794196);
//         earn.updatePool( uint8(0));
//         vm.warp(1683794273);
//         uint res= earn.getStakingLengths(address(this));
//         uint totalPending;
//         for (uint256 i = 0 ; i < res ; i++) {
//             totalPending +=   earn.getPending(address(this), i);
//         }
//         uint pending = earn.getPendingBatch(address(this));
//         assertEq(pending, totalPending);
//     }

//     function test_getPendingType( ) public {
//         initializing();
//         hydt.approve(address(earn), uint(100000e18));
//         vm.warp(1683788870);
//         uint8 stakeType = uint8(0);
//         uint _amount = uint(10e18);
//         earn.stake(_amount, stakeType);
//         earn.stake(_amount, stakeType);
//         vm.warp(1683794196);
//         earn.updatePool( uint8(0));
//         vm.warp(1683794273);
//         uint pending = earn.getPendingType(address(this), uint8(0));
//         assertEq(pending, uint(89999999999985700000));
//     }

//     // // // 48483333333323700000

//     // // // 0x0000000000000000000000000000000000000000

//     function test_massUpdatePool() public {
//         initializing();
//         hydt.approve(address(earn), uint(100000e18));
//         uint _amount = uint(10e18);
//         earn.stake(_amount, 0);
//         uint res= earn.getStakingLengths(address(this));
//         assertEq(res,1);
//         earn.massUpdatePools();
//     }

//     function test_poolLength() public{
//         initializing();
//         hydt.approve(address(earn), uint(100000e18));
//         uint _amount = uint(10e18);
//         earn.stake(_amount, 0);
//         vm.warp(2343242342);
//         uint length= earn.poolLength();
//         uint expectedLength= 3;
//         assertEq(length, expectedLength);
//     }
    
    
    
   
//     // -----------------  all above tests will be used
//     // function test_updatePool ( ) public {
//     //     uint initialMintTime = uint (block.timestamp);
//     //     shydt.initialize(address(earn));
//     //     hydt.initialize(address(control), address(earn));
//     //     reserve.initialize(address (control));
//     //     hygt.initialize(address (earn), address (farm));
//     //     hydt.approve(address(earn), uint(100000e18));
//     //     earn.initialize( address(hydt), address( hygt),  address(earn),  address(reserve),  block.timestamp ) ;
//     //     // earn.updatePool(0);
//     //     // (,,uint256 amount,,,,,)= earn.getStakings(address(this), uint(0));
//     //     uint amount = earn.getStakingLengths(address(this));
//     //     console.logUint(amount);
//     // } 

    

//     // function test_stake ( ) public {
//     //     uint initialMintTime = uint (block.timestamp);
//     //     shydt.initialize(address(earn));
//     //     hydt.initialize(address(control), address(earn));
//     //     reserve.initialize(address (control));
//     //     hygt.initialize(address (earn), address (farm));
//     //     hydt.approve(address(earn), uint(100000e18));
//     //     earn.initialize( address(hydt), address( hygt),  address(earn),  address(reserve),  block.timestamp ) ;
//     //     vm.prank(address(0));
//     //     shydt.mint(address(this), 100e18);
//     //     console.logAddress(address(earn));
//     // }    
// }      

// // └─ ← ()
// // ├─ [1213] Earn::poolInfo(0) [staticcall]
// // │   └─ ← 0, 100, 9850000000000000000, 3230118443316, 1683711049
// // ├─ [997] Earn::poolShares(0, 0) [staticcall]
// // │   └─ ← 9850000000000000000, 3230118443316, 168371104



// /// 48483333333323700000