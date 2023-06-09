// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.18;

// import "forge-std/Test.sol";
// import {Control} from "../src/Control.sol";
// import {HYDT} from "../src/HYDT.sol";
// import {HYGT} from "../src/HYGT.sol";
// import {Reserve} from "../src/Reserve.sol";
// import {IERC20} from "../src/interfaces/IERC20.sol";
// import {IHYDT} from "../src/interfaces/IHYDT.sol";
// import {UniswapV2Factory} from "../src/uni/UniswapV2Factory.sol";
// import {UniswapV2Router02} from "../src/router/UniswapV2Router02.sol";
// import {USDT} from "../src/extensions/USDT.sol";
// import {WETH} from "../src/extensions/WETH.sol";
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
//     USDT public usdt;
//     WETH public weth;
//     HYDT public hydt;
//     HYGT public hygt;
//     Reserve public reserve;
//     Earn public earn;
//     sHYDT public shydt;
//     Farm public farm;
//     UniswapV2Factory public factory;
//     UniswapV2Router02 public router;

//     // Invoked before each test
//     function setUp() public {
      
//         weth = new WETH();
//         usdt = new USDT();
//         reserve = new Reserve();
//         control = new Control();
//         hydt = new HYDT(address(reserve));
//         factory = new UniswapV2Factory(address(this));
//         router = new UniswapV2Router02(address(factory), address(weth));
//         earn = new Earn();
//         shydt = new sHYDT();
//         farm = new Farm();
//         hygt = new HYGT(address(0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496), address(reserve));
//     }

//     function initializing() public{
//         hydt.initialize(address(control), address(earn));
//         reserve.initialize(address (factory), address (control), address(usdt), address(weth));
//         hygt.initialize(address (earn), address (farm));
//         shydt.initialize(address(earn));
//         earn.initialize( address(hydt), address( hygt),  address(shydt),  address(reserve),  block.timestamp ) ;
//     }

//     function test_Initialize() public {
//         uint initialMintTime = uint (block.timestamp);
//         earn.initialize( address(hydt), address( hygt),  address(shydt),  address(reserve),  initialMintTime ) ;
//         uint depositFee= earn.depositFee();
//         assertEq(depositFee,15);
//         assertTrue(earn.hasRole(control.GOVERNOR_ROLE(), address(this)));
//         assertTrue(earn.hasRole(control.DEFAULT_ADMIN_ROLE(), address(this)));
//         uint expectedLength= 3;
//         assertEq(earn.poolLength(), expectedLength);
//         uint HYGTPerSecond= earn.HYGTPerSecond();
//         assertEq(HYGTPerSecond, 0.166666666666666667 * 1e18);
//     }

//     function test_Initialize_RevertOn_HYDTt_AddressZero() public {
//         uint initialMintTime = uint (block.timestamp);
//         vm.expectRevert("Earn: invalid HYDT address");
//         earn.initialize( address(0), address( hygt),  address(shydt),  address(reserve),  initialMintTime ) ;
//     }

//     function test_InitializeWithHYGTAddressZero() public {
//         uint initialMintTime = uint (block.timestamp);
//         vm.expectRevert("Earn: invalid HYGT address");
//         earn.initialize( address(hydt), address( 0),  address(shydt),  address(reserve),  initialMintTime ) ;
//     }

//     function test_Initialize_RevertOn_sHYDT_AddressZero() public {
//         uint initialMintTime = uint (block.timestamp);
//         vm.expectRevert("Earn: invalid sHYDT address");
//         earn.initialize( address(hydt), address(hygt),  address(0),  address(reserve),  initialMintTime ) ;
//     }

//     function test_Initialize_RevertOn_Treasury_AddressZero() public {
//         uint initialMintTime = uint (block.timestamp);
//         vm.expectRevert("Earn: invalid Treasury address");
//         earn.initialize( address(hydt), address(hygt),  address(shydt),  address(0),  initialMintTime ) ;
//     }

//     function test_Initialize_RevertOn_NonInitializer() public {
//         uint initialMintTime = uint (block.timestamp);
//         vm.prank(address(0));
//         vm.expectRevert("Earn: caller is not the initializer");
//         earn.initialize( address(hydt), address( hygt),  address(shydt),  address(reserve),  initialMintTime);
//     }

//     function test_dailyPayouts_On_Initialize() public {
//         uint initialMintTime = uint (block.timestamp);
//         earn.initialize( address(hydt), address( hygt),  address(shydt),  address(reserve),  initialMintTime ) ;
//         uint dailyPayouts= earn.dailyPayouts(0);
//         uint dailyPayouts1= earn.dailyPayouts(1);
//         uint dailyPayouts2= earn.dailyPayouts(2);
//         assertEq(dailyPayouts,1.156 * 1e18);
//         assertEq(dailyPayouts1, 0.611 * 1e18);
//         assertEq(dailyPayouts2,0.356 * 1e18);
//     }

//     function test_updateAllocPoint () public {
//         uint allocPoint=2000;
//         uint8 stakeType= 2;
//         uint initialMintTime = uint (block.timestamp);
//         earn.initialize( address(hydt), address( hygt),  address(shydt),  address(reserve),  initialMintTime ) ;
//         earn.updateAllocationWithUpdate( stakeType,  allocPoint);
//         assertTrue(true);
//     }

//     function test_updateAllocPoint_RevertOn_NonGOVERNOR_ROLE () public {
//         uint allocPoint=2000;
//         uint8 stakeType= 2;
//         uint initialMintTime = uint (block.timestamp);
//         earn.initialize( address(hydt), address( hygt),  address(shydt),  address(reserve),  initialMintTime ) ;
//         vm.prank(address(weth));
//         vm.expectRevert("AccessControl: account 0x5615deb798bb3e4dfa0139dfa1b3d433cc23b72f is missing role 0xd0990c50b6714f222e6fd1faaf5345bf1aa2867d2861fc2cc43b364e7d948647");
//         earn.updateAllocationWithUpdate( stakeType,  allocPoint);
        
//     }

//     function test_GrantRole() public {
//         initializing();
//         earn.grantRole(earn.GOVERNOR_ROLE(), address(weth));
//         assertTrue(earn.hasRole(earn.GOVERNOR_ROLE(), address(weth)));
//     }  

//     function test_RevokeRole() public {
//         initializing();
//         earn.grantRole(earn.GOVERNOR_ROLE(), address(weth));
//         assertTrue(earn.hasRole(earn.GOVERNOR_ROLE(), address(weth)));

//         earn.revokeRole(earn.GOVERNOR_ROLE(), address(weth));
//         bool expectedRole = earn.hasRole(earn.GOVERNOR_ROLE(),  address(weth));
//         assertEq(expectedRole,false);
//     }  

//     // function test_stake() public {
//     //     initializing();
//     //     hydt.approve(address(earn), uint(100000e18));
//     //     uint _amount = uint(10e18);
//     //     assertTrue(shydt.hasRole(shydt.CALLER_ROLE(), address(earn)));
//     //     earn.stake(_amount, 0);
//     //     (,bool stakingStatus,uint256 amount,,,uint stakingendTime,uint stakinglastClaimTime,)= earn.getStakings(address(this), uint(0));
//     //     uint fee=uint (_amount*15/1000);
//     //     assertEq(amount,_amount-fee);
//     //     assertTrue(stakingStatus);
//     //     assertEq(stakingendTime,5401 );
//     //     assertEq(stakinglastClaimTime,1);
        
//     // }  

//     function test_stake_RevertWhen_AmountZero() public {
//         initializing();
//         hydt.approve(address(earn), uint(100000e18));
//         uint _amount = uint(0);
//         assertTrue(shydt.hasRole(shydt.CALLER_ROLE(), address(earn)));
//         vm.expectRevert("Earn: insufficient amount");
//         earn.stake(_amount, 0);
//     }    
    
//     function test_stake_RevertWhen_StakeTypeIncorrect() public {
//         initializing();
//         hydt.approve(address(earn), uint(100000e18));
//         uint _amount = uint(10e18);
//         assertTrue(shydt.hasRole(shydt.CALLER_ROLE(), address(earn)));
//         vm.expectRevert("Earn: invalid stake type");
//         earn.stake(_amount, uint8(3));
//     } 

//     // function test_stakeEvent() public {
//     //     initializing();
//     //     hydt.approve(address(earn), uint(100000e18));
//     //     uint _amount = uint(10e18);
//     //     assertTrue(shydt.hasRole(shydt.CALLER_ROLE(), address(earn)));

//     //     vm.expectEmit(false, true, true, false);
//     //     emit Stake(address(this), uint8(0) , uint(10e18), uint8(0),1, 5401);

//     //     earn.stake(_amount, 0);
//     //     (,bool stakingStatus,uint256 amount,,,uint stakingendTime,uint stakinglastClaimTime,)= earn.getStakings(address(this), uint(0));
//     //     uint fee=uint (_amount*15/1000);
//     //     console.logUint(stakingendTime);
//     //     console.logUint(stakinglastClaimTime);
//     //     //  vm.expectEmit(true, true, false, true);
//     //     // // emit Transfer(address(this), address(this), 10);
//     //     // // hydt.transfer(address(this), 10);
//     //     // hydt.approve(address(earn), uint(100000e18));
//     // } 


//     function test_stake_RevertOn_ZeroHYDTAllowance ( ) public {
//         initializing();
//         uint _amount = uint(10e18);
//         vm.expectRevert("ERC20: insufficient allowance");
//         earn.stake(_amount, 0);

//     }    
  
//     function test_claimPayoutWithNoStakings()  public {
//         initializing();
//         hydt.approve(address(earn), uint(100000e18));
//         uint _amount = uint(10e18);
//         assertTrue(shydt.hasRole(shydt.CALLER_ROLE(), address(earn)));
//                 // staking here
//         vm.warp(1683705649);
//         earn.stake(_amount, 0);
//         // (,bool stakingStatus,uint256 amount,,,uint stakingendTime,uint stakinglastClaimTime,)= earn.getStakings(address(this), uint(0));
//         // uint fee=uint (_amount*15/1000);
//         // (,,, uint accHYGTPerShare,)=earn.poolInfo(0);
//         // console.logUint(accHYGTPerShare);
//         // uint balanceBeforeUnstake = hydt.balanceOf(address(this));
//         // uint balanceBeforeUnstakehygt = hygt.balanceOf(address(this));
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
//         // (,bool stakingStatus,uint256 amount,,,uint stakingendTime,uint stakinglastClaimTime,)= earn.getStakings(address(this), uint(0));
        
//         // // checking Rewards after a sepecific time
//         vm.warp(200);
//         uint result =earn.getPayout(address(this),0);
//         assertGt(result,0);
        
//     }


//     function test_claimPayout_DeadlinePassedPending()  public {
//         initializing();
//         hydt.approve(address(earn), uint(100000e18));
//         uint _amount = uint(10e18);
//                 // staking here
//         // vm.warp(1683705649);
//         earn.stake(_amount, 0);
//         (,,,,,uint stakingendTime,,)= earn.getStakings(address(this), uint(0));
        
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
//         // (,,,,,,uint stakinglastClaimTime,)= earn.getStakings(address(this), uint(0));
        
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
//         (,, ,,,uint stakingendTime,,)= earn.getStakings(address(this), uint(0));
        
//         // // checking Rewards after a sepecific time
//         vm.warp(stakingendTime);
//         earn.updatePool(0);
//         uint256 amount__= earn.getPayout(address(this), 0);
//         assertGt(amount__,0);
//     }

//     function test_getStakings()  public {
//         initializing();
//         hydt.approve(address(earn), uint(100000e18));
//         uint _amount = uint(10e18);
//         vm.warp(1683705649);
//         earn.stake(_amount, 0);
//         (,,uint256 amount,,,,,)= earn.getStakings(address(this), uint(0));
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
//         earn.stake(_amount, 0);
//         uint res1= earn.getStakingLengths(address(this));
//         assertEq(res1,2);
//         earn.stake(_amount, 1);
//         uint res2= earn.getStakingLengths(address(this));
//         assertEq(res2,3);
//     } 
    

//     function test_updatePool( ) public {
//         initializing();
//         hydt.approve(address(earn), uint(100000e18));
//         vm.warp(1683788870);

//         uint8 stakeType = uint8(0);
//         uint _amount = uint(10e18);
//         earn.stake(_amount, stakeType);
//         // (,,,,,,uint lastClaimTime,)= earn.getStakings(address(this), uint(0));
//         vm.warp(1683794196);
//         earn.updatePool( uint8(0));
//         vm.warp(1683794273);
//         uint pending = earn.getPending(address(this), uint8(0));
//         assertEq(pending, uint(89999999999995550000));
//     }

//     // function test_getPendingTimeGreaterthanLastRewardTime( ) public {
//     //     initializing();
//     //     hydt.approve(address(earn), uint(100000e18));
//     //     vm.warp(1683788850);

//     //     uint8 stakeType = uint8(0);
//     //     uint _amount = uint(10e18);
//     //     earn.stake(_amount, stakeType);
//     //     // (,,,,,,uint lastClaimTime,)= earn.getStakings(address(this), uint(0));
//     //     vm.warp(1683788851);
//     //     earn.claimPayout(0);
//     //     vm.expectRevert("Earn: no amount to withdraw");
//     //     vm.warp(1683788850);
//     //     earn.claimPayout(0);
        
//     //     // uint pending = earn.getPending(address(this), uint8(0));
//     //     // (,,uint256 amount2,,,,uint lastClaimTime1,)= earn.getStakings(address(this), uint(0));
//     //     // console.logUint(pending);
//     //     // assertEq(pending, uint(89999999999995550000));
//     // }

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

//     // function test_getPendingType( ) public {
//     //     initializing();
//     //     hydt.approve(address(earn), uint(100000e18));
//     //     vm.warp(1683788870);
//     //     uint8 stakeType = uint8(0);
//     //     uint _amount = uint(10e18);
//     //     earn.stake(_amount, stakeType);
//     //     earn.stake(_amount, stakeType);
//     //     vm.warp(1683794196);
//     //     earn.updatePool( uint8(0));
//     //     vm.warp(1683794273);
//     //     uint pending = earn.getPendingType(address(this), uint8(0));
//     //     assertEq(pending, uint(89999999999985700000));
//     // }

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
    

    
//   /**
//      * @notice multiple stakes at same time of same amount and staketype.
//                 OnclaimPayout : everyone will get same amount of hydt and hygt
//      */
//  function test_stake_MultipleStakes_SametimeAndStakeType ( ) public {
//     initializing();
//     address wallet1= address(123);
//     address wallet2= address(2345);
//     address wallet3= address(3456);
//     address wallet4= address(45678);
//     address wallet5= address(5678);
//     hydt.transfer(wallet1, 10e18);
//     hydt.transfer(wallet2, 10e18);
//     hydt.transfer(wallet3, 10e18);
//     hydt.transfer(wallet4, 10e18);
//     hydt.transfer(wallet5, 10e18);
//     // hydt.approve(address(earn), 1000e18);
//     // earn.stake(uint(10e18), 0);
//     // assertEq(earn.getStakingLengths(address(this)),1);
//     vm.warp(block.timestamp+32);
//     vm.startPrank(wallet1);

//     hydt.approve(address(earn), 1000e18);
//     earn.stake(10e18, 0);
//     assertEq(earn.getStakingLengths(address(wallet1)),1);
//     vm.stopPrank();
//     // vm.warp(block.timestamp+5);
//     vm.startPrank(wallet2);

//     hydt.approve(address(earn), 1000e18);
//     earn.stake(10e18, 0);
//     assertEq(earn.getStakingLengths(address(wallet2)),1);
//     vm.stopPrank();

//     // vm.warp(block.timestamp+5);
//     vm.startPrank(wallet3);

//     hydt.approve(address(earn), 1000e18);
//     earn.stake(10e18, 0);
//     assertEq(earn.getStakingLengths(address(wallet3)),1);
//     vm.stopPrank();
//     // vm.warp(block.timestamp+5);
//     vm.startPrank(wallet4);

//     hydt.approve(address(earn), 1000e18);
//     earn.stake(10e18, 0);
//     assertEq(earn.getStakingLengths(address(wallet4)),1);
//     vm.stopPrank();

//     // vm.warp(block.timestamp+5);
//     vm.startPrank(wallet5);

//     hydt.approve(address(earn), 1000e18);
//     earn.stake(10e18, 0);
//     assertEq(earn.getStakingLengths(address(wallet5)),1);
//     vm.stopPrank();

//     vm.warp(123);
//     // given the same time of stake & same amount, rewards should be same for all stakers,
//     // when they are in the same pool
//     uint256 amountMint = earn.getPayout(address(wallet1), 0);
//     uint256 pending = earn.getPending(address(wallet1), 0);

//     vm.startPrank(wallet1);
//     earn.claimPayout(0);
//     assertEq(hydt.balanceOf(address(wallet1)), amountMint);
//     assertEq(hygt.balanceOf(address(wallet1)), pending);
//     vm.stopPrank();

//     vm.startPrank(wallet2);
//     earn.claimPayout(0);
//     assertEq(hydt.balanceOf(address(wallet2)), amountMint);
//     assertEq(hygt.balanceOf(address(wallet2)), pending);
//     vm.stopPrank();

    
//     vm.startPrank(wallet3);
//     uint getpendingtype = earn.getPendingType(wallet3, 0);
//     earn.claimPayout(0);
//     assertEq(hydt.balanceOf(address(wallet3)), amountMint);
//     assertEq(hygt.balanceOf(address(wallet3)), pending);
//     assertEq(hygt.balanceOf(address(wallet3)), getpendingtype);
//     vm.stopPrank();

//     vm.startPrank(wallet4);
//     earn.claimPayout(0);
//     assertEq(hydt.balanceOf(address(wallet4)), amountMint);
//     assertEq(hygt.balanceOf(address(wallet4)), pending);
//     uint256 getpayouttype=  earn.getPayoutType( wallet4, 0 );
//     assertEq(getpayouttype, 0);
//     vm.stopPrank();

//     vm.startPrank(wallet5);
//     uint256  getpayouttype5=  earn.getPayoutType( wallet5, 0 );
//     earn.claimPayout(0);
//     assertEq(hydt.balanceOf(address(wallet5)), amountMint);
//     assertEq(hydt.balanceOf(address(wallet5)), getpayouttype5);
//     assertEq(hygt.balanceOf(address(wallet5)), pending);
//     vm.stopPrank();

// }   

//     function test_stake_MultipleStakes_DifferentTime( ) public {
//         initializing();
//         address wallet1= address(123);
//         address wallet2= address(2345);
//         address wallet3= address(3456);
//         address wallet4= address(45678);
//         address wallet5= address(5678);
//         hydt.transfer(wallet1, 10e18);
//         hydt.transfer(wallet2, 10e18);
//         hydt.transfer(wallet3, 10e18);
//         hydt.transfer(wallet4, 10e18);
//         hydt.transfer(wallet5, 10e18);

//         vm.warp(block.timestamp+32);
        
//         vm.startPrank(wallet1);
//         hydt.approve(address(earn), 1000e18);
//         earn.stake(10e18, 0);
//         vm.stopPrank();

//         vm.warp(block.timestamp+15);
//         vm.startPrank(wallet2);

//         hydt.approve(address(earn), 1000e18);
//         earn.stake(10e18, 0);
//         assertEq(earn.getStakingLengths(address(wallet2)),1);

//         vm.stopPrank();

//         vm.warp(block.timestamp+15);

//         vm.startPrank(wallet3);
//         hydt.approve(address(earn), 1000e18);
//         earn.stake(10e18, 0);
//         assertEq(earn.getStakingLengths(address(wallet3)),1);
//         vm.stopPrank();
//         vm.warp(block.timestamp+15);

//         vm.startPrank(wallet4);
//         hydt.approve(address(earn), 1000e18);
//         earn.stake(10e18, 0);
//         assertEq(earn.getStakingLengths(address(wallet4)),1);
//         vm.stopPrank();
//         vm.warp(block.timestamp+15);

//         vm.startPrank(wallet5);
//         hydt.approve(address(earn), 1000e18);
//         earn.stake(10e18, 0);
//         assertEq(earn.getStakingLengths(address(wallet5)),1);
//         vm.stopPrank();

//         vm.warp(1000);
//         vm.startPrank(wallet1);
//         uint256 pending1 = earn.getPending(wallet1, 0);
//         earn.claimPayout(0);
//         // wallet has Zero Hygt Balance
//         // after Claim , pending & his hygt balance should match 
//         assertEq(pending1, hygt.balanceOf(wallet1));
//         console.log(pending1);
//         vm.stopPrank();

//         vm.startPrank(wallet2);
//         uint256 pending2 = earn.getPending(wallet2, 0);
//         earn.claimPayout(0);
//         // wallet has Zero Hygt Balance
//         // after Claim , pending & his hygt balance should match 
//         assertEq(pending2, hygt.balanceOf(wallet2));
//         console.log(pending2);
//         vm.stopPrank();

//         vm.startPrank(wallet3);
//         uint256 pending3 = earn.getPending(wallet3, 0);
//         earn.claimPayout(0);
//         // wallet has Zero Hygt Balance
//         // after Claim , pending & his hygt balance should match 
//         assertEq(pending3, hygt.balanceOf(wallet3));
//         console.log(pending3);
//         vm.stopPrank();

//         vm.startPrank(wallet4);
//         uint256 pending4 = earn.getPending(wallet4, 0);
//         earn.claimPayout(0);
//         // wallet has Zero Hygt Balance
//         // after Claim , pending & his hygt balance should match 
//         assertEq(pending4, hygt.balanceOf(wallet4));
//         console.log(pending4);
//         vm.stopPrank();

//         vm.startPrank(wallet5);
//         uint256 pending5 = earn.getPending(wallet5, 0);
//         earn.claimPayout(0);
//         // wallet has Zero Hygt Balance
//         // after Claim , pending & his hygt balance should match 
//         assertEq(pending5, hygt.balanceOf(wallet5));
//         console.log(pending5);
//         vm.stopPrank();
//     }    


//     function test_stake_InSFirstMonth__NoReward( ) public {
//     /**
//      * @notice test satisfies that first month reward is not being calculated in total Rewards
//      */
//         initializing();
//         address wallet1= address(123);
//         hydt.transfer(wallet1, 10e18);
//         vm.startPrank(wallet1);
//         hydt.approve(address(earn), 10e18);
//         earn.stake(10e18, 0);
//         vm.warp(92);
//         uint getPending = earn.getPending(wallet1, 0);
//         earn.claimPayout(0);
//         vm.stopPrank();

//         hydt.approve(address(earn), 10e18);
//         earn.stake(10e18, 0);

//         vm.warp(184);

//         uint getPending1 = earn.getPending(address(this), 0);
//         assertGt(getPending1, getPending);

//     }  
// }      
 