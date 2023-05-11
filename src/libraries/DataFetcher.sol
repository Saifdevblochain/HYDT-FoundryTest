// SPDX-License-Identifier: GNU GPLv3

pragma solidity ^0.8.0;

import "../interfaces/IPancakeFactory.sol";
import "../interfaces/IPancakePair.sol";

library DataFetcher {

    // TODO replace
    address private constant pancakeFactory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    // address private constant pancakeFactory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;

    function pairFor(address tokenA, address tokenB) internal view returns (address pair) {
        return IPancakeFactory(pancakeFactory).getPair(tokenA, tokenB);
    }

    function getReserves(address tokenA, address tokenB) internal view returns (uint256 reserveA, uint256 reserveB) {
        address pair = pairFor(tokenA, tokenB);
        address token0 = IPancakePair(pair).token0();
        (uint256 reserve0, uint256 reserve1, ) = IPancakePair(pair).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    function quote(uint256 amountA, address tokenA, address tokenB) internal view returns (uint256 amountB) {
        (uint256 reserveA, uint256 reserveB) = getReserves(tokenA, tokenB);
        amountB = (amountA * reserveB) / reserveA;
    }

    function quoteBatch(uint256[] memory amountsIn, address tokenA, address tokenB) internal view returns (uint256[] memory amountsOut) {
        require(amountsIn.length >= 1, "DataFetcher: INVALID_AMOUNTS_IN");
        (uint256 reserveA, uint256 reserveB) = getReserves(tokenA, tokenB);
        amountsOut = new uint256[](amountsIn.length);

        for (uint256 i = 0 ; i < amountsIn.length ; i++) {
            amountsOut[i] = (amountsIn[i] * reserveB) / reserveA;
        }
    }

    function quoteRouted(uint256 amountIn, address[] memory path) internal view returns (uint256 amountOut) {
        require(path.length >= 2, "DataFetcher: INVALID_PATH");
        uint256[] memory amounts = new uint256[](path.length);
        amounts[0] = amountIn;

        for (uint256 i = 0 ; i < path.length - 1 ; i++) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(path[i], path[i + 1]);
            amounts[i + 1] = (amounts[i] * reserveOut) / reserveIn;
        }
        amountOut = amounts[path.length - 1];
    }
}