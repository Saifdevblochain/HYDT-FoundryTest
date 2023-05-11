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
    }

    function test_initialize() public {
        address[3] memory tokens  ;
        tokens = [address(wbnb), address(usdt), address(hygt)];
        uint256 initialMintStartTime_=block.timestamp ;

        farm.initialize(address (hygt), tokens,initialMintStartTime_ ) ;
    }

    }