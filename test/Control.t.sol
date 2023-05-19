// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import {Control} from "../src/Control.sol";
import {HYDT} from "../src/HYDT.sol";
import {HYGT} from "../src/HYGT.sol";
import {Reserve} from "../src/Reserve.sol";
// import {WBNB} from "../src/WBNB.sol";
import {IERC20} from "../src/interfaces/IERC20.sol";
import {IHYDT} from "../src/interfaces/IHYDT.sol";
import {UniswapV2Factory} from "../src/uni/UniswapV2Factory.sol";
import {UniswapV2Router02} from "../src/router/UniswapV2Router02.sol";
import {USDT} from "../src/extensions/USDT.sol";
import {WETH} from "../src/extensions/WETH.sol";
import {Earn} from "../src/Earn.sol";
import {sHYDT} from "../src/sHYDT.sol";

contract ControlTest is Test {
    IERC20 public token;
    uint256 initialMintStartTime_ = uint256(block.timestamp);
    Control public control;
    HYDT public hydt;
    HYGT public hygt;
    Reserve public reserve;
    // WBNB public wbnb;
    UniswapV2Factory public factory;
    UniswapV2Router02 public router;
    USDT public usdt;
    WETH public weth;
    sHYDT public shydt;
    Earn public earn;

    // Invoked before each test
    function setUp() public {

        reserve = new Reserve();
        hydt = new HYDT(address(reserve));
        token = IERC20(hydt);
        earn = new Earn();
        weth = new WETH();
        usdt = new USDT();
        factory = new UniswapV2Factory(
            address(this)
        );
        router = new UniswapV2Router02(address(factory), address(weth));
        
        deal(address(this), 100000000000e18);
        deal(address(reserve), 64000e18);
        usdt.approve(address(router), 3211920779369330438779728312);

        weth.deposit{value: 100000000000e18}();
        weth.approve(address(router), 100000000000e18);
        hydt.approve(address(router), 100000000000e18);

        uint deadline = uint(block.timestamp + 1000);

        // router.addLiquidity(
        //     address(usdt),
        //     address(weth),
        //     22119207793693304387797283,
        //     70006926146614989754719,
        //     uint(0),
        //     uint(0),
        //     address(1234),
        //     deadline
        // );
        // router.addLiquidity(
        //     address(hydt),
        //     address(weth),
        //     (1000000 * 1e18),
        //     (1000000 * 3164983429767117),
        //     uint(0),
        //     uint(0),
        //     address(1234),
        //     deadline
        // );
        control = new Control( address(usdt),address(factory),
        address(router),
        address(weth),
        address(hydt),
        address(reserve),
        initialMintStartTime_);
        hydt.initialize(address(control), address(earn));

        reserve.initialize(address(factory) ,address(control), address(usdt), address (weth));
        // hygt.initialize(address (earn), address (farm));
       
    }

//     // deal(to, amount);
//     // hoax(address, amount);
    function initializing() public {
        shydt.initialize(address(earn));
        hydt.initialize(address(control), address(earn));
        reserve.initialize(address (factory), address (control), address(usdt), address(weth));
        // hygt.initialize(address (earn), address (farm));
        earn.initialize(
            address(hydt),
            address(hygt),
            address(shydt),
            address(reserve),
            uint(1)
        );
        // addingLiquidity();

    }

    // function test_Initialize() public {
    //     control.initialize(
    //         address(factory),
    //         address(router),
    //         address(weth),
    //         address(hydt),
    //         address(reserve),
    //         initialMintStartTime_
    //     );
    //     assertTrue(control.hasRole(control.GOVERNOR_ROLE(), address(this)));
    //     assertTrue(control.hasRole(control.CALLER_ROLE(), address(this)));
    //     assertTrue(
    //         control.hasRole(control.DEFAULT_ADMIN_ROLE(), address(this))
    //     );
    //     (uint256 startTime, uint256 endTime, uint256 amountUSD) = control
    //         .getInitialMints();
    //     assertEq(startTime, initialMintStartTime_);
    //     assertEq(endTime, initialMintStartTime_ + 5400);
    //     assertEq(amountUSD, 0);

    //     (uint256 startTime1, uint256 endTime1, uint256 amountUSD1) = control
    //         .getDailyInitialMints();
    //     assertEq(startTime1, initialMintStartTime_);
    //     assertEq(endTime1, initialMintStartTime_ + 60);
    //     assertEq(amountUSD1, 0);
    // }

    // function addingLiquidity() public {
    //     deal(address(this), 100000000000e18);
    //     deal(address(reserve), 64000e18);
    //     usdt.approve(address(router), 3211920779369330438779728312);

    //     weth.deposit{value: 100000000000e18}();
    //     weth.approve(address(router), 100000000000e18);
    //     hydt.approve(address(router), 100000000000e18);

    //     uint deadline = uint(block.timestamp + 1000);

    //     router.addLiquidity(
    //         address(usdt),
    //         address(weth),
    //         22119207793693304387797283,
    //         70006926146614989754719,
    //         uint(0),
    //         uint(0),
    //         address(this),
    //         deadline
    //     );
    //     router.addLiquidity(
    //         address(hydt),
    //         address(weth),
    //         (1000000 * 1e18),
    //         (1000000 * 3164983429767117),
    //         uint(0),
    //         uint(0),
    //         address(this),
    //         deadline
    //     );
    // }

    // function test_Initialize_with_NonInitializer() public {
    //     vm.prank(address(0));
    //     vm.expectRevert("Control: caller is not the initializer");
    //     // control.initialize(
    //     //     address(weth),
    //     //     address(hydt),
    //     //     address(reserve),
    //     //     initialMintStartTime_
    //     // );
    // }

    // function test_Initialize_hydt_zeroAddress() public {
    //     address hydt_ = address(0);
    //     vm.expectRevert("Control: invalid HYDT address");
    //     // control.initialize(
    //     //     address(weth),
    //     //     address(hydt_),
    //     //     address(reserve),
    //     //     initialMintStartTime_
    //     // );
    // }

    // function test_Initialize_RevertOn_reserve_zeroAddress() public {
    //     address reserve_ = address(0);
    //     vm.expectRevert("Control: invalid Reserve address");
    //     // control.initialize(
    //     //     address(weth),
    //     //     address(hydt),
    //     //     address(reserve_),
    //     //     initialMintStartTime_
    //     // );
    // }

    // function test_Initialize_RevertWhen_ReInitialize() public {
    //     control.initialize(address(weth),address(hydt),address(reserve),initialMintStartTime_);
    //     vm.expectRevert( "Control: already initialized");
    //     control.initialize(address(weth),address(hydt),address(reserve),initialMintStartTime_);
    // }

    // function test_updateOpsReadyState() public {
    //     // control.initialize(
    //     //     address(weth),
    //     //     address(hydt),
    //     //     address(reserve),
    //     //     initialMintStartTime_
    //     // );
    //     control.updateOpsReadyState(true);
    //     assertTrue(control.opsReadyState());
    // }

    // function test_updateOpsReadyState_RevertOn_NoAccessRole() public {
    //     // control.initialize(
    //     //     address(weth),
    //     //     address(hydt),
    //     //     address(reserve),
    //     //     initialMintStartTime_
    //     // );
    //     vm.prank(address(1234));
    //     vm.expectRevert("AccessControl: account 0x00000000000000000000000000000000000004d2 is missing role 0xd0990c50b6714f222e6fd1faaf5345bf1aa2867d2861fc2cc43b364e7d948647");
    //     control.updateOpsReadyState(false);
    // }

    // function test_updateOpsReadyState_RevertOn_SameValue_AsOldState() public {
    //     // control.initialize(
    //     //     address(weth),
    //     //     address(hydt),
    //     //     address(reserve),
    //     //     initialMintStartTime_
    //     // );
    //     vm.expectRevert("Control: OpsReadyState is already this state");
    //     control.updateOpsReadyState(false);
    // }

    // function test_delegateApprove() public {
    //     address to = address(0xC0FC8954c62A45c3c0a13813Bd2A10d88D70750D);
    //     // control.initialize(
    //     //     address(weth),
    //     //     address(hydt),
    //     //     address(reserve),
    //     //     initialMintStartTime_
    //     // );
    //     control.delegateApprove(token, address(123), true);
    //     uint balance= type(uint).max ;
    //     uint res= token.allowance(address(control),address(123));
    //     assertEq(balance,res);
    //      control.delegateApprove(token, address(123), false);
    //      uint res1 =token.allowance(address(control),address(123));
    //      assertEq(res1,0);
    // }

    // function test_delegateApproveWithBoolFalse() public {
    //     address to = address(0xC0FC8954c62A45c3c0a13813Bd2A10d88D70750D);
    //     // control.initialize(
    //     //     address(weth),
    //     //     address(hydt),
    //     //     address(reserve),
    //     //     initialMintStartTime_
    //     // );
    //     control.delegateApprove(token, to, false);
    //     assertTrue(true);
    // }

    function test_getInitial() public{
        // initializing();
        deal(address(this), 100000000000e18);
        deal(address(reserve), 64000e18);
        // usdt.approve(address(factory), 100000e18);
        usdt.approve(address(router), 3211920779369330438779728312 );
        weth.deposit{value:100000000000e18}();
        weth.approve(address(router), 100000000000e18);
        // weth.approve(address(factory), 1000e18);

        // uint amount_= weth.allowance(address(this), address(router));
        // console.log("eth balance",address(this).balance/1e18);
        // console.log("Weth Allowance",amount_);
        // console.log(factory.feeToSetter());
        hydt.approve(address(router), 100000000000e18 );
        uint deadline= uint(block.timestamp+1000);
        console.log("22222222222222222222");

        router.addLiquidity(address(usdt),address(weth) , 22119207793693304387797283, 70006926146614989754719, uint(0), uint(0), address(this), deadline);
        router.addLiquidity(address(hydt),address(weth) , (1000000*1e18), (1000000*3164983429767117), uint(0), uint(0), address(this), deadline);
        // control.initialize(address(weth),address(hydt),address(reserve),initialMintStartTime_);
        uint price = control.getCurrentPrice();
        console.log("price initial :::",price);
        address[] memory path= new address[](2);
        path[0] = address(weth);
        path[1] = address(hydt);
        router.swapExactTokensForTokens ( 80e18,1, path, address(this), block.timestamp+100 ) ;
        uint price1 = control.getCurrentPrice();
        console.log("price after swap :::",price1);
        console.log("22222222222222222222");

        uint iterations;

        uint max = control.PRICE_UPPER_BOUND();

        for (uint i; i < 100; i++){

           control.execute(0);
           uint res= control.mintProgressCount() ;
           console.log("res-------",res);
        //    assertEq(res,control.mintProgressCount() );
        // uint price1 = control.getCurrentPrice();
        // console.log("price :",price1);

        iterations++;
        // console.log("Iterations::::",iterations);

        if (control.mintProgressCount() > 0.1 * 1e18) {
            uint res1= control.mintProgressCount() ;
            console.log("res1------",res1);
            // console.log("mint progress count:::::",control.mintProgressCount());
            // console.log("Iterations special case::::",iterations);
        }
        else {
            // console.log("Iterations::::",iterations);
        }
        if (price1<=max){
            break;
        }
        }

        uint priceAfterr = control.getCurrentPrice();
        console.log("priceAfterr----",priceAfterr);
        console.log(control.PRICE_UPPER_BOUND());
        assertLe(priceAfterr, control.PRICE_UPPER_BOUND());

    }

    function test_getInitial1() public{
        // initializing();

        deal(address(this), 100000000000e18);
        deal(address(reserve), 100000000000e18);
        // usdt.approve(address(factory), 100000e18);
        usdt.approve(address(router), 3211920779369330438779728312 );

        weth.deposit{value:100000000000e18}();
        weth.approve(address(router), 100000000000e18);
        // weth.approve(address(factory), 1000e18);

        // uint amount_= weth.allowance(address(this), address(router));
        // console.log("eth balance",address(this).balance/1e18);
        // console.log("Weth Allowance",amount_);
        // console.log(factory.feeToSetter());
        hydt.approve(address(router), 100000000000e18 );

        uint deadline= uint(block.timestamp+1000);

        router.addLiquidity(address(usdt),address(weth) , 22119207793693304387797283, 70006926146614989754719, uint(0), uint(0), address(this), deadline);
        router.addLiquidity(address(hydt),address(weth) , (1000000*1e18), (1000000*3164983429767117), uint(0), uint(0), address(this), deadline);
        // control.initialize(address(weth),address(hydt),address(reserve),initialMintStartTime_);
        uint price = control.getCurrentPrice();
        console.log("price initial :::",price);
        address[] memory path= new address[](2);
        path[0] = address(hydt);
        path[1] = address(weth);
        router.swapExactTokensForTokens(
        // 400e18,
        118000e18,
        1,
        path,
        address(this),
         block.timestamp+100);
        uint price1 = control.getCurrentPrice();
        console.log("price after swap :::",price1);
        uint iterations;

        uint max = control.PRICE_LOWER_BOUND();

        for (uint i; i<100; i++){
           control.execute(1);

        uint price1 = control.getCurrentPrice();
        console.log("price :",price1);

        iterations++;
        if (control.redeemProgressCount() > 0.1 * 1e18) {
            console.log("redeem progress count:::::",control.redeemProgressCount());
            console.log("Iterations special case::::",iterations);
        }
        else {
            console.log("Iterations::::",iterations);
        }

        if (price1>=max){
            break;
        }
        }
    }

    // function test_initialMint() public {
    //     initializing();
    //     control.initialize(address(weth), address(hydt),  address(reserve),  initialMintStartTime_ );
    //     vm.warp(100);
      
    //     // uint amountB= router.quote(1e18, uint(70006926146614989754719), uint(22119207793693304387797283));
    //     // console.log("amountB is:",amountB); //315957420375367009208
        
    //     deal(address(this), 1000e18);
    //     control.initialMint{value: 1e18}();
    //     (, , uint256 amountInitialMints)= control.getInitialMints();
    //     (,, uint256 amountDailyMints)= control.getDailyInitialMints();
    //     assertEq(uint(315957420375367009208),amountInitialMints);
    //     assertEq(uint(315957420375367009208),amountDailyMints);
    // }

    // function test_initialMint_AfterOneDay() public {
    //     // initializing();
    //     // control.initialize(address (factory),address (router),address(weth), address(hydt),  address(reserve),  initialMintStartTime_ );
    //     vm.warp(64);
      
    //     // uint amountB= router.quote(1e18, uint(70006926146614989754719), uint(22119207793693304387797283));
    //     // console.log("amountB is:",amountB); //315957420375367009208
        
    //     deal(address(this), 1000e18);
    //     control.initialMint{value: 1e18}();
    //     (uint starttime1, uint endtime1 , uint256 amountInitialMints)= control.getInitialMints();
    //     (uint starttime,uint endtime, uint256 amountDailyMints)= control.getDailyInitialMints();
    //     assertEq(uint(1),starttime1);
    //     assertEq(uint(5401),endtime1);
    //     assertEq(uint(61),starttime);
    //     assertEq(uint(121),endtime);

    //     assertEq(uint(315957420375367009208),amountInitialMints);
    //     assertEq(uint(315957420375367009208),amountDailyMints);
    // }

    // function test_initialMint_revert() public {
    //     // initializing();
    //     // addingLiquidity();
    //     deal(address(this), 100e18);
    //     vm.expectRevert("Control: insufficient BNB amount");
    //     control.initialMint{value: 0}();
    // }

    // function test_initialMint_revert_BeforeStartTime() public {
    //     // initializing();
    //     // addingLiquidity();
    //     // control.initialize(
    //     //     address(factory),
    //     //     address(router),
    //     //     address(weth),
    //     //     address(hydt),
    //     //     address(reserve),
    //     //     initialMintStartTime_
    //     // );
    //     deal(address(this), 1000e18);
    //     vm.expectRevert("Control: initial mint not yet started");
    //     control.initialMint{value: 1e18}();
    // }

    // function test_initialMint_revert_MintTimeEnd() public {
    //     // initializing();
    //     // control.initialize(
    //     //     address(factory),
    //     //     address(router),
    //     //     address(weth),
    //     //     address(hydt),
    //     //     address(reserve),
    //     //     initialMintStartTime_
    //     // );
    //     // addingLiquidity();
    //     vm.warp(10000);
    //     deal(address(this), 1000e18);
    //     vm.expectRevert("Control: initial mint ended");
    //     control.initialMint{value: 1e18}();
    // }

   

    // function test_initialMint_RevertOn_MintLimitReach() public {
    //     initializing();

    //     deal(address(this), 100000000000e18);
    //     deal(address(reserve), 64000e18);
    //     usdt.approve(address(router), 3211920779369330438779728312 );

    //     weth.deposit{value:100000000000e18}();
    //     weth.approve(address(router), 100000000000e18);
    //     hydt.approve(address(router), 100000000000e18 );

    //     uint deadline= uint(block.timestamp+1000);

    //     router.addLiquidity(address(usdt),address(weth) , 22119207793693304387797283, 70006926146614989754719, uint(0), uint(0), address(this), deadline);
    //     router.addLiquidity(address(hydt),address(weth) , (1000000*1e18), (1000000*3164983429767117), uint(0), uint(0), address(this), deadline);
    //     // control.initialize(address(weth),address(hydt),address(reserve),initialMintStartTime_);

    //     deal(address(this), 100e18);
    //     vm.expectRevert("Control: insufficient BNB amount");
    //     control.initialMint();

    //     deal(address(this), 1000e18);
    //     vm.expectRevert("Control: initial mint not yet started");
    //     control.initialMint{value:1e18}();

    //     deal(address(this), 30000000e18);
    //     uint amountB= router.quote(1e18, uint(70006926146614989754719), uint(22119207793693304387797283));
    //     console.log(amountB,"amoutn bbbbb");
    //     uint res= control.INITIAL_MINT_LIMIT()/amountB;
    //     res =res* 1e18;
    //     // console.log(res/90);
    //     uint time= 60;
    //     uint iterations;
    //     for (uint i ; i<90; i++)  {
    //         vm.warp(time);
    //         if(iterations >88){
    //             vm.expectRevert("Control: invalid amount considering initial mint limit");
    //         }
    //         control.initialMint{value:(res/90)+0.1e18}();

    //         time= time+60;
    //         iterations++;
    //         console.log("iterations----",iterations);
    //     }
    // }

    // function test_initialMint () public {
    //     initializing();

    //     deal(address(this), 100000000000e18);
    //     deal(address(reserve), 64000e18);
    //     usdt.approve(address(router), 3211920779369330438779728312 );

    //     weth.deposit{value:100000000000e18}();
    //     weth.approve(address(router), 100000000000e18);

    //     hydt.approve(address(router), 100000000000e18 );

    //     uint deadline= uint(block.timestamp+1000);

    //     router.addLiquidity(address(usdt),address(weth) , 22119207793693304387797283, 70006926146614989754719, uint(0), uint(0), address(this), deadline);
    //     router.addLiquidity(address(hydt),address(weth) , (1000000*1e18), (1000000*3164983429767117), uint(0), uint(0), address(this), deadline);
    //     // control.initialize(address(weth),address(hydt),address(reserve),initialMintStartTime_);

    //     deal(address(this), 100e18);
    //     vm.expectRevert("Control: insufficient BNB amount");
    //     control.initialMint();

    //     deal(address(this), 1000e18);
    //     vm.expectRevert("Control: initial mint not yet started");
    //     control.initialMint{value:1e18}();

    //     deal(address(this), 30000000e18);
    //     uint amountB= router.quote(1e18, uint(70006926146614989754719), uint(22119207793693304387797283)); // gives us value of token B i-e usd
    //     console.log(amountB,"amoutn bbbbb");
    //     uint res= control.INITIAL_MINT_LIMIT()/amountB;
    //     res =res* 1e18;
    //     console.log(res);
    //     uint time= 60;
    //     uint iterations;
    //     for (uint i ; i<90; i++)  {
    //         vm.warp(time);
    //         control.initialMint{value:(res/90)}();
    //         time= time+60;
    //         iterations++;
    //         // console.log("iterations----",iterations);
    //     }
    //     (, , uint256 amountUSD)= control.getInitialMints();
    //     // console.log("amountUSD-------",amountUSD);
    //     // console.log(,"amountB*90");

    //     uint expected = (res/1e18)*amountB;

    //     // assertEq(expected, amountUSD);
    //     // vm.warp(123);
    //     // deal(address(this), 100e18);
    //     // control.initialMint{value:1}();

    //     // uint amountIn = 1e18;
    //     // address[] memory path= new address[](2);
    //     // path[0] = address(weth);
    //     // path[1] = address(hydt);
    //     // uint[] memory amounts = router.getAmountsOut(amountIn,  path);
    //     // control.initialMint{value:amountIn}();
    //     // (, , uint256 amountUSD)= control.getInitialMints();
    //     // // assertEq(amountUSD,expected );

    //     // vm.warp(10000);
    //     // vm.expectRevert("Control: initial mint ended");

    // }

    // function test_getInitialmints() public {
    //     uint256 initialMintStartTime = uint256(12123123);
    //     // control.initialize(
    //     //     address(weth),
    //     //     address(hydt),
    //     //     address(reserve),
    //     //     initialMintStartTime
    //     // );
    //     (uint startTime, uint endTime, uint amountUSD) = control
    //         .getInitialMints();
    //     assertEq(startTime, initialMintStartTime);
    //     assertEq(endTime, initialMintStartTime + 5400);
    //     assertEq(amountUSD, 0);
    // }

//     // function test_getDailyInitialMints() public {}
// }
}